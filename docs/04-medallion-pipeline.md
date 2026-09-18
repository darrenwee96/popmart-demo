# 04 · 奖章架构管道（Silver + Gold）

一条 Lakeflow 声明式管道（`popmart_medallion`，Serverless）构建 Bronze → Silver → Gold。

## Silver —— `src/transformations/silver.sql`
清洗、一致化的**维度**（`silver_dim_ip/product/member/store`）与**事实**
（`silver_fact_online_sales`、`silver_fact_pos_sales`、`silver_fact_pop_draw`、
`silver_fact_inventory`、`silver_fact_supply`），并构建**统一的全渠道销售事实表**
`silver_fact_sales`（把线上订单与门店/机器人商店 POS 合并为同一粒度）。

每张 Silver 表都带有**数据质量校验（Expectations）**，按处理动作分级：
- `FAIL UPDATE`：作用于主键/粒度键 —— 空键绝不允许流向下游。
- `DROP ROW`：作用于事实表中的脏数据（例如 `quantity > 0`、金额非负）—— 隔离坏行，保持 Gold 干净。
- 仅告警（warn）：作用于软性指标（枚举取值、范围、毛利、交期）—— 体现在管道的 **Data Quality** 面板。

## Gold —— `src/transformations/gold.sql`
8 张开箱即用的业务集市：`gold_sales_daily`、`gold_ip_performance`、`gold_secret_hit_rates`、
`gold_omnichannel_customer`、`gold_member_tier_summary`、`gold_store_performance`、
`gold_inventory_health`、`gold_supply_chain_supplier`。

运行：`databricks bundle run popmart_medallion -t dev --profile popmart`
