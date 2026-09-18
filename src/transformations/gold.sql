-- ============================================================================
-- GOLD — business-ready marts (feed the dashboard & Genie)
-- ============================================================================

-- ============================ GOLD — marts =================================
CREATE OR REFRESH MATERIALIZED VIEW gold_sales_daily
COMMENT 'Daily revenue/units by channel, country, IP, product type' AS
SELECT f.sale_date, f.channel, f.country, d.ip_name, d.product_type,
       SUM(f.quantity) AS units, ROUND(SUM(f.gross_amount), 2) AS revenue,
       COUNT(DISTINCT f.sale_id) AS line_count
FROM silver_fact_sales f
LEFT JOIN silver_dim_product d ON f.product_id = d.product_id
GROUP BY f.sale_date, f.channel, f.country, d.ip_name, d.product_type;

CREATE OR REFRESH MATERIALIZED VIEW gold_ip_performance
COMMENT 'Revenue/units by IP across all channels' AS
SELECT d.ip_name, d.artist_name, d.origin,
       ROUND(SUM(f.gross_amount), 2) AS total_revenue,
       SUM(f.quantity) AS total_units,
       COUNT(DISTINCT f.sale_id) AS total_lines,
       ROUND(SUM(CASE WHEN f.channel = 'online' THEN f.gross_amount ELSE 0 END), 2) AS online_revenue,
       ROUND(SUM(CASE WHEN f.channel <> 'online' THEN f.gross_amount ELSE 0 END), 2) AS offline_revenue,
       COUNT(DISTINCT d.product_id) AS num_products
FROM silver_fact_sales f
JOIN silver_dim_product d ON f.product_id = d.product_id
GROUP BY d.ip_name, d.artist_name, d.origin;

CREATE OR REFRESH MATERIALIZED VIEW gold_secret_hit_rates
COMMENT 'Blind-box secret-figure hit rates by series' AS
SELECT ip_name, series_name, secret_ratio AS expected_ratio,
       COUNT(*) AS total_draws,
       SUM(CAST(is_secret_hit AS INT)) AS secret_hits,
       ROUND(SUM(CAST(is_secret_hit AS INT)) / COUNT(*), 5) AS actual_hit_rate
FROM silver_fact_pop_draw
GROUP BY ip_name, series_name, secret_ratio;

CREATE OR REFRESH MATERIALIZED VIEW gold_omnichannel_customer
COMMENT 'Per-member online vs offline spend + omnichannel flag' AS
WITH online AS (
  SELECT member_id, SUM(gross_amount) AS online_spend, COUNT(DISTINCT sale_id) AS online_lines
  FROM silver_fact_sales WHERE channel = 'online' AND member_id IS NOT NULL GROUP BY member_id),
offline AS (
  SELECT member_id, SUM(gross_amount) AS offline_spend, COUNT(DISTINCT sale_id) AS offline_lines
  FROM silver_fact_sales WHERE channel <> 'online' AND member_id IS NOT NULL GROUP BY member_id)
SELECT m.member_id, m.membership_tier, m.country, m.city,
       ROUND(COALESCE(o.online_spend, 0), 2) AS online_spend,
       ROUND(COALESCE(f.offline_spend, 0), 2) AS offline_spend,
       ROUND(COALESCE(o.online_spend, 0) + COALESCE(f.offline_spend, 0), 2) AS total_spend,
       (o.member_id IS NOT NULL AND f.member_id IS NOT NULL) AS is_omnichannel
FROM silver_dim_member m
LEFT JOIN online o ON m.member_id = o.member_id
LEFT JOIN offline f ON m.member_id = f.member_id;

CREATE OR REFRESH MATERIALIZED VIEW gold_member_tier_summary
COMMENT 'Membership-tier LTV + omnichannel penetration' AS
SELECT membership_tier,
       COUNT(*) AS num_members,
       ROUND(AVG(total_spend), 2) AS avg_ltv,
       ROUND(SUM(total_spend), 2) AS total_revenue,
       ROUND(100.0 * SUM(CASE WHEN is_omnichannel THEN 1 ELSE 0 END) / COUNT(*), 1) AS omnichannel_pct
FROM gold_omnichannel_customer
GROUP BY membership_tier;

CREATE OR REFRESH MATERIALIZED VIEW gold_store_performance
COMMENT 'Revenue/units/basket by store' AS
SELECT st.store_id, st.store_name, st.store_type, st.country, st.city,
       ROUND(SUM(p.sale_amount), 2) AS revenue, SUM(p.quantity) AS units,
       COUNT(DISTINCT p.txn_id) AS txns,
       ROUND(SUM(p.sale_amount) / NULLIF(COUNT(DISTINCT p.txn_id), 0), 2) AS avg_basket
FROM silver_fact_pos_sales p
JOIN silver_dim_store st ON p.store_id = st.store_id
GROUP BY st.store_id, st.store_name, st.store_type, st.country, st.city;

CREATE OR REFRESH MATERIALIZED VIEW gold_inventory_health
COMMENT 'Inventory health by store' AS
SELECT st.store_id, st.store_name, st.store_type, st.country,
       COUNT(*) AS num_skus,
       SUM(CASE WHEN i.is_stockout THEN 1 ELSE 0 END) AS stockouts,
       SUM(CASE WHEN i.is_below_reorder THEN 1 ELSE 0 END) AS below_reorder,
       ROUND(100.0 * SUM(CASE WHEN i.is_stockout THEN 1 ELSE 0 END) / COUNT(*), 1) AS stockout_rate
FROM silver_fact_inventory i
JOIN silver_dim_store st ON i.store_id = st.store_id
GROUP BY st.store_id, st.store_name, st.store_type, st.country;

CREATE OR REFRESH MATERIALIZED VIEW gold_supply_chain_supplier
COMMENT 'Supplier lead-time & spend' AS
SELECT supplier_name, supplier_country, category,
       COUNT(DISTINCT po_id) AS num_pos,
       ROUND(SUM(quantity * unit_cost), 2) AS total_cost,
       ROUND(AVG(actual_lead_days), 1) AS avg_actual_lead_days,
       ROUND(AVG(expected_lead_days), 1) AS avg_expected_lead_days
FROM silver_fact_supply
GROUP BY supplier_name, supplier_country, category;
