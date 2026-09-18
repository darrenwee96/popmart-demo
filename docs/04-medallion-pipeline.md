# 04 · Medallion pipeline (Silver + Gold)

One Lakeflow Declarative Pipeline (`popmart_medallion`, serverless) builds Bronze → Silver → Gold.

## Silver — `src/transformations/silver.sql`
Cleaned & conformed **dimensions** (`silver_dim_ip/product/member/store`) and **facts**
(`silver_fact_online_sales`, `silver_fact_pos_sales`, `silver_fact_pop_draw`,
`silver_fact_inventory`, `silver_fact_supply`), plus the **unified omnichannel sales fact**
`silver_fact_sales` (online orders + in-store/roboshop POS in one grain).

**Data-quality expectations** on every Silver table, tiered by action:
- `FAIL UPDATE` on primary/grain keys — a null key never reaches downstream.
- `DROP ROW` on corrupting values in facts (e.g. `quantity > 0`, non-negative amounts) — bad rows are quarantined so Gold stays clean.
- warn-only on soft signals (enum domains, ranges, margins, lead times) — tracked in the pipeline **Data quality** tab.

## Gold — `src/transformations/gold.sql`
8 business-ready marts: `gold_sales_daily`, `gold_ip_performance`, `gold_secret_hit_rates`,
`gold_omnichannel_customer`, `gold_member_tier_summary`, `gold_store_performance`,
`gold_inventory_health`, `gold_supply_chain_supplier`.

Run: `databricks bundle run popmart_medallion -t dev --profile popmart`
