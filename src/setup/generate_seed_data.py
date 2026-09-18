# Databricks notebook source
# MAGIC %md
# MAGIC # Pop Mart — synthetic seed data generator
# MAGIC Generates a referentially-consistent **subset** of all 19 source tables
# MAGIC (9 e-commerce + 10 retail-ops) and writes one CSV folder per table into the
# MAGIC landing **volume**, so Auto Loader can ingest them into Bronze.
# MAGIC
# MAGIC Runs on **serverless**. Parameters come from the job (`base_parameters`).

# COMMAND ----------
import random, datetime as dt
from collections import defaultdict
from pyspark.sql import SparkSession
from pyspark.sql.types import (StructType, StructField, IntegerType, LongType,
                               DoubleType, StringType, BooleanType, DateType, TimestampType)

spark = SparkSession.builder.getOrCreate()

dbutils.widgets.text("catalog", "popmart")
dbutils.widgets.text("schema", "default")
dbutils.widgets.text("volume", "landing")
dbutils.widgets.text("size", "small")
CAT = dbutils.widgets.get("catalog")
SCH = dbutils.widgets.get("schema")
VOL = dbutils.widgets.get("volume")
SIZE = dbutils.widgets.get("size").lower()

BASE = f"/Volumes/{CAT}/{SCH}/{VOL}"
random.seed(42)

# ---- subset sizes -----------------------------------------------------------
SMALL  = dict(series=60,  products=300,  members=1000, orders=4000,  pop_draw=3000,
              reviews=2000, stores=60, roboshops=200, employees=300, suppliers=40,
              inventory=5000, pos=10000, po=500, shipments=500)
MEDIUM = dict(series=120, products=600,  members=5000, orders=20000, pop_draw=15000,
              reviews=8000, stores=120, roboshops=400, employees=600, suppliers=80,
              inventory=15000, pos=25000, po=1200, shipments=1200)
cfg = MEDIUM if SIZE == "medium" else SMALL

# ---- helpers ----------------------------------------------------------------
START, END = dt.date(2024, 9, 18), dt.date(2026, 9, 17)
NOW = dt.datetime(2026, 9, 17, 12, 0, 0)
def rdate(a=START, b=END): return a + dt.timedelta(days=random.randint(0, (b - a).days))
def rts(a=START, b=END):
    d = rdate(a, b); return dt.datetime(d.year, d.month, d.day, random.randint(0, 23), random.randint(0, 59), random.randint(0, 59))

def write(name, rows, schema):
    df = spark.createDataFrame(rows, schema)
    df.coalesce(1).write.mode("overwrite").option("header", "true").csv(f"{BASE}/{name}")
    print(f"  {name:20} {len(rows):>7,} rows")

# ---- reference lookups ------------------------------------------------------
IPS = [(1,"The Monsters (Labubu)","Kasing Lung","licensed",2015),(2,"Molly","Kenny Wong","original",2006),
       (3,"Skullpanda","Xiong Miao","original",2020),(4,"Dimoo","Ayan Deng","original",2018),
       (5,"Hirono","Lang","original",2021),(6,"CryBaby","Molly Yllom","licensed",2017),
       (7,"Pucky","Pucky","original",2016),(8,"Zsiga","Zheng Yun","original",2019),
       (9,"Bunny","Wang Ning","original",2014),(10,"Nyota","PMOGA Studio","licensed",2022),
       (11,"Twinkle","PMOGA Studio","original",2023),(12,"Peach Riot","PMOGA Studio","licensed",2021)]
ip_ids = [r[0] for r in IPS]
ip_name_by_id = {r[0]: r[1] for r in IPS}
PT = ["blind_box"]*6 + ["mega_400","mega_1000","plush_pendant","plush_doll","accessory","blocks"]
GEO = [("United States","New York","Americas"),("Singapore","Singapore","APAC"),("China","Shanghai","APAC"),
       ("Japan","Tokyo","APAC"),("South Korea","Seoul","APAC"),("United Kingdom","London","EMEA"),
       ("Thailand","Bangkok","APAC"),("Canada","Toronto","Americas")]
TIERS = ["Rookie"]*5 + ["Silver"]*3 + ["Gold"]*2 + ["Black Card"]
OSTAT = ["delivered"]*5 + ["paid"]*3 + ["shipped"]*2 + ["packed","created","cancelled","refunded"]
CHAN = ["app_ios","app_android","web"]
PAYM = ["credit_card","paypal","apple_pay","google_pay","alipay","wechat_pay","klarna"]
STYPE = ["standard"]*6 + ["flagship"]*2 + ["pop_bakery","roboshop_hub"]
POSTAT = ["received"]*5 + ["confirmed"]*2 + ["in_transit","sent","draft","closed"]
CATG = ["figures","plush","packaging","accessories","logistics"]

print(f"Generating {SIZE} dataset -> {BASE}")

# ---- ecommerce: ip_brands / product_series / products / product_catalog -----
write("ip_brands", [(i,n,a,o,y,NOW,NOW) for (i,n,a,o,y) in IPS], StructType([
    StructField("ip_id",IntegerType()),StructField("ip_name",StringType()),StructField("artist_name",StringType()),
    StructField("origin",StringType()),StructField("launch_year",IntegerType()),
    StructField("created_at",TimestampType()),StructField("updated_at",TimestampType())]))

series=[]
for sid in range(1, cfg["series"]+1):
    ipid=random.choice(ip_ids); ratio=random.choice([1/72,1/96,1/144]); base=round(random.uniform(8,30),2)
    series.append((sid,ipid,f"{ip_name_by_id[ipid].split(' ')[0]} Series {sid}",random.randint(6,12),True,
                   round(ratio,6),rdate(dt.date(2022,1,1)),base,"USD",NOW,NOW))
ip_by_series={r[0]:r[1] for r in series}; base_by_series={r[0]:r[7] for r in series}
write("product_series", series, StructType([
    StructField("series_id",IntegerType()),StructField("ip_id",IntegerType()),StructField("series_name",StringType()),
    StructField("total_figures",IntegerType()),StructField("has_secret",BooleanType()),StructField("secret_ratio",DoubleType()),
    StructField("release_date",DateType()),StructField("base_price",DoubleType()),StructField("currency",StringType()),
    StructField("created_at",TimestampType()),StructField("updated_at",TimestampType())]))

series_ids=[r[0] for r in series]
products=[]
for pid in range(1, cfg["products"]+1):
    sid=random.choice(series_ids); pt=random.choice(PT); price=round(random.uniform(8,45),2)
    products.append((pid,sid,f"SKU-{pid:05d}",f"Figure {pid}",pt,random.random()<0.08,price,"USD",
                     random.randint(40,600),random.choices(["active","discontinued","preorder"],[0.8,0.1,0.1])[0],NOW,NOW))
price_by_pid={r[0]:r[6] for r in products}
prods_in_series=defaultdict(list)
for r in products: prods_in_series[r[1]].append(r[0])
prod_ids=[r[0] for r in products]
write("products", products, StructType([
    StructField("product_id",IntegerType()),StructField("series_id",IntegerType()),StructField("sku_code",StringType()),
    StructField("figure_name",StringType()),StructField("product_type",StringType()),StructField("is_secret",BooleanType()),
    StructField("unit_price",DoubleType()),StructField("currency",StringType()),StructField("weight_g",IntegerType()),
    StructField("status",StringType()),StructField("created_at",TimestampType()),StructField("updated_at",TimestampType())]))

catalog=[]; cost_by_pid={}
for r in products:
    pid,sid,price=r[0],r[1],r[6]; cost=round(price*random.uniform(0.35,0.55),2); cost_by_pid[pid]=cost
    catalog.append((pid,r[2],r[3],ip_name_by_id[ip_by_series[sid]],r[4],cost,price,"USD",NOW,NOW))
write("product_catalog", catalog, StructType([
    StructField("product_id",IntegerType()),StructField("sku_code",StringType()),StructField("product_name",StringType()),
    StructField("ip_name",StringType()),StructField("product_type",StringType()),StructField("standard_cost",DoubleType()),
    StructField("retail_price",DoubleType()),StructField("currency",StringType()),
    StructField("created_at",TimestampType()),StructField("updated_at",TimestampType())]))

# ---- members ----------------------------------------------------------------
members=[]
for mid in range(1, cfg["members"]+1):
    geo=random.choice(GEO)
    members.append((mid,f"First{mid}",f"Last{mid}",f"user{mid}@example.com",f"+1{random.randint(2000000000,9999999999)}",
                    geo[0],geo[1],rdate(dt.date(2023,1,1)),random.choice(TIERS),random.randint(0,50000),
                    rdate(dt.date(1985,1,1),dt.date(2010,1,1)),random.random()<0.6,NOW,NOW))
member_ids=[r[0] for r in members]
write("members", members, StructType([
    StructField("member_id",IntegerType()),StructField("first_name",StringType()),StructField("last_name",StringType()),
    StructField("email",StringType()),StructField("phone",StringType()),StructField("country",StringType()),
    StructField("city",StringType()),StructField("signup_date",DateType()),StructField("membership_tier",StringType()),
    StructField("points_balance",IntegerType()),StructField("birthday",DateType()),StructField("marketing_opt_in",BooleanType()),
    StructField("created_at",TimestampType()),StructField("updated_at",TimestampType())]))

# ---- orders + order_items + payments ---------------------------------------
orders=[]; order_items=[]; payments=[]; oiid=1
for oid in range(1, cfg["orders"]+1):
    mid=random.choice(member_ids); ots=rts(); geo=random.choice(GEO); status=random.choice(OSTAT)
    nitems=random.randint(1,3); subtotal=0.0
    for _ in range(nitems):
        pid=random.choice(prod_ids); qty=random.randint(1,3); price=price_by_pid[pid]; lt=round(qty*price,2)
        order_items.append((oiid,oid,pid,qty,price,lt)); subtotal=round(subtotal+lt,2); oiid+=1
    ship=round(random.uniform(0,12),2); disc=round(random.choice([0,0,0,5,10]),2); total=round(subtotal+ship-disc,2)
    orders.append((oid,mid,ots,random.choice(CHAN),geo[0],status,subtotal,ship,disc,total,"USD",
                   random.choice([None,None,"WELCOME10","VIP5"]),NOW,NOW))
    pstat="captured" if status not in ("cancelled","refunded") else ("refunded" if status=="refunded" else "failed")
    payments.append((oid,oid,ots,random.choice(PAYM),total,"USD",pstat))
write("orders", orders, StructType([
    StructField("order_id",LongType()),StructField("member_id",IntegerType()),StructField("order_datetime",TimestampType()),
    StructField("channel",StringType()),StructField("ship_country",StringType()),StructField("order_status",StringType()),
    StructField("subtotal",DoubleType()),StructField("shipping_fee",DoubleType()),StructField("discount",DoubleType()),
    StructField("total_amount",DoubleType()),StructField("currency",StringType()),StructField("coupon_code",StringType()),
    StructField("created_at",TimestampType()),StructField("updated_at",TimestampType())]))
write("order_items", order_items, StructType([
    StructField("order_item_id",LongType()),StructField("order_id",LongType()),StructField("product_id",IntegerType()),
    StructField("quantity",IntegerType()),StructField("unit_price",DoubleType()),StructField("line_total",DoubleType())]))
write("payments", payments, StructType([
    StructField("payment_id",LongType()),StructField("order_id",LongType()),StructField("pay_datetime",TimestampType()),
    StructField("method",StringType()),StructField("amount",DoubleType()),StructField("currency",StringType()),
    StructField("status",StringType())]))

# ---- pop_draw ---------------------------------------------------------------
draws=[]
for did in range(1, cfg["pop_draw"]+1):
    sid=random.choice(series_ids); pool=prods_in_series.get(sid) or prod_ids
    ratio=base_by_series[sid]  # noqa (base price, not ratio) -> use series ratio below
    draws.append((did,random.choice(member_ids),sid,random.choice(pool),random.random()<0.02,
                  round(base_by_series[sid],2),rts()))
write("pop_draw", draws, StructType([
    StructField("draw_id",LongType()),StructField("member_id",IntegerType()),StructField("series_id",IntegerType()),
    StructField("drawn_product_id",IntegerType()),StructField("is_secret_hit",BooleanType()),
    StructField("price_paid",DoubleType()),StructField("draw_datetime",TimestampType())]))

# ---- product_reviews --------------------------------------------------------
reviews=[]
for rid in range(1, cfg["reviews"]+1):
    reviews.append((rid,random.choice(prod_ids),random.choice(member_ids),
                    random.choices([5,4,3,2,1],[0.45,0.3,0.15,0.06,0.04])[0],"Great figure!","en",rdate()))
write("product_reviews", reviews, StructType([
    StructField("review_id",LongType()),StructField("product_id",IntegerType()),StructField("member_id",IntegerType()),
    StructField("rating",IntegerType()),StructField("review_text",StringType()),StructField("language",StringType()),
    StructField("review_date",DateType())]))

# ---- retail: stores / roboshops / employees / suppliers --------------------
stores=[]
for sid in range(1, cfg["stores"]+1):
    geo=random.choice(GEO); stype=random.choice(STYPE)
    stores.append((sid,f"Pop Mart {geo[1]} #{sid}",stype,geo[0],geo[2],geo[1],f"{random.randint(1,999)} Main St",
                   round(random.uniform(-55,60),6),round(random.uniform(-160,160),6),rdate(dt.date(2019,1,1)),
                   round(random.uniform(60,600),1) if stype!="roboshop_hub" else round(random.uniform(20,80),1),
                   random.choices(["active","closed"],[0.9,0.1])[0],NOW,NOW))
store_ids=[r[0] for r in stores]
write("stores", stores, StructType([
    StructField("store_id",IntegerType()),StructField("store_name",StringType()),StructField("store_type",StringType()),
    StructField("country",StringType()),StructField("region",StringType()),StructField("city",StringType()),
    StructField("address",StringType()),StructField("latitude",DoubleType()),StructField("longitude",DoubleType()),
    StructField("open_date",DateType()),StructField("floor_area_sqm",DoubleType()),StructField("status",StringType()),
    StructField("created_at",TimestampType()),StructField("updated_at",TimestampType())]))

roboshops=[]
for rmid in range(1, cfg["roboshops"]+1):
    geo=random.choice(GEO)
    roboshops.append((rmid,random.choice(store_ids+[None]),f"{geo[1]} Mall Kiosk",geo[1],geo[0],rdate(dt.date(2021,1,1)),
                      random.choices(["active","maintenance"],[0.85,0.15])[0],random.choice([36,48,60,72]),NOW,NOW))
machine_ids=[r[0] for r in roboshops]
write("roboshops", roboshops, StructType([
    StructField("machine_id",IntegerType()),StructField("store_id",IntegerType()),StructField("location_desc",StringType()),
    StructField("city",StringType()),StructField("country",StringType()),StructField("install_date",DateType()),
    StructField("status",StringType()),StructField("capacity_slots",IntegerType()),
    StructField("created_at",TimestampType()),StructField("updated_at",TimestampType())]))

employees=[]
for eid in range(1, cfg["employees"]+1):
    employees.append((eid,random.choice(store_ids),f"Employee {eid}",random.choice(["associate","supervisor","manager"]),
                      rdate(dt.date(2020,1,1)),random.choices(["active","inactive"],[0.9,0.1])[0],NOW,NOW))
employee_ids=[r[0] for r in employees]
write("employees", employees, StructType([
    StructField("employee_id",IntegerType()),StructField("store_id",IntegerType()),StructField("full_name",StringType()),
    StructField("role",StringType()),StructField("hire_date",DateType()),StructField("status",StringType()),
    StructField("created_at",TimestampType()),StructField("updated_at",TimestampType())]))

suppliers=[]
for spid in range(1, cfg["suppliers"]+1):
    geo=random.choice(GEO)
    suppliers.append((spid,f"Supplier {spid} Co.",geo[0],random.choice(CATG),random.randint(5,45),NOW,NOW))
supplier_ids=[r[0] for r in suppliers]
write("suppliers", suppliers, StructType([
    StructField("supplier_id",IntegerType()),StructField("supplier_name",StringType()),StructField("country",StringType()),
    StructField("category",StringType()),StructField("lead_time_days",IntegerType()),
    StructField("created_at",TimestampType()),StructField("updated_at",TimestampType())]))

# ---- store_inventory --------------------------------------------------------
inv=[]
for iid in range(1, cfg["inventory"]+1):
    qty=0 if random.random()<0.08 else random.randint(1,200)
    inv.append((iid,random.choice(store_ids),random.choice(prod_ids),qty,random.randint(10,50),rdate(dt.date(2025,1,1)),NOW))
write("store_inventory", inv, StructType([
    StructField("inventory_id",LongType()),StructField("store_id",IntegerType()),StructField("product_id",IntegerType()),
    StructField("qty_on_hand",IntegerType()),StructField("reorder_point",IntegerType()),
    StructField("last_restock_date",DateType()),StructField("updated_at",TimestampType())]))

# ---- pos_transactions -------------------------------------------------------
pos=[]
for tid in range(1, cfg["pos"]+1):
    sid=random.choice(store_ids); pid=random.choice(prod_ids); qty=random.randint(1,3); price=price_by_pid[pid]
    roboshop = random.random()<0.4
    pos.append((tid,sid,(random.choice(machine_ids) if roboshop else None),pid,
                (random.choice(member_ids) if random.random()<0.6 else None),qty,price,round(qty*price,2),"USD",
                rts(),random.choice(["cash","card","mobile"]),(None if roboshop else random.choice(employee_ids)),NOW))
write("pos_transactions", pos, StructType([
    StructField("txn_id",LongType()),StructField("store_id",IntegerType()),StructField("machine_id",IntegerType()),
    StructField("product_id",IntegerType()),StructField("member_id",IntegerType()),StructField("quantity",IntegerType()),
    StructField("unit_price",DoubleType()),StructField("sale_amount",DoubleType()),StructField("currency",StringType()),
    StructField("txn_timestamp",TimestampType()),StructField("payment_type",StringType()),
    StructField("employee_id",IntegerType()),StructField("created_at",TimestampType())]))

# ---- purchase_orders + po_line_items + shipments ---------------------------
pos_orders=[]; po_lines=[]; shipments=[]; plid=1; shid=1
for poid in range(1, cfg["po"]+1):
    spid=random.choice(supplier_ids); od=rdate(dt.date(2024,1,1)); lead=random.randint(5,45)
    exp=od+dt.timedelta(days=lead); status=random.choice(POSTAT)
    rec=(exp+dt.timedelta(days=random.randint(-3,7))) if status in ("received","closed") else None
    total=0.0
    for _ in range(random.randint(1,4)):
        pid=random.choice(prod_ids); qty=random.randint(10,500); uc=cost_by_pid[pid]
        po_lines.append((plid,poid,pid,qty,uc)); total=round(total+qty*uc,2); plid+=1
    pos_orders.append((poid,spid,od,exp,rec,status,total,NOW,NOW))
    sd=od+dt.timedelta(days=random.randint(1,5))
    ad=(sd+dt.timedelta(days=random.randint(3,20))) if status in ("received","closed","in_transit") and random.random()<0.8 else None
    shipments.append((shid,poid,sd,ad,f"WH-{random.randint(1,6)}",
                      random.choice(["delivered","in_transit","delayed"]),NOW,NOW)); shid+=1
write("purchase_orders", pos_orders, StructType([
    StructField("po_id",IntegerType()),StructField("supplier_id",IntegerType()),StructField("order_date",DateType()),
    StructField("expected_date",DateType()),StructField("received_date",DateType()),StructField("status",StringType()),
    StructField("total_cost",DoubleType()),StructField("created_at",TimestampType()),StructField("updated_at",TimestampType())]))
write("po_line_items", po_lines, StructType([
    StructField("po_line_id",LongType()),StructField("po_id",IntegerType()),StructField("product_id",IntegerType()),
    StructField("quantity",IntegerType()),StructField("unit_cost",DoubleType())]))
write("shipments", shipments, StructType([
    StructField("shipment_id",IntegerType()),StructField("po_id",IntegerType()),StructField("ship_date",DateType()),
    StructField("arrival_date",DateType()),StructField("dest_warehouse",StringType()),StructField("status",StringType()),
    StructField("created_at",TimestampType()),StructField("updated_at",TimestampType())]))

print(f"\nDone. All 19 tables written as CSV under {BASE}/<table>/")
