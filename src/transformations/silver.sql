-- ============================================================================
-- SILVER — cleaned & conformed dimensions + facts (+ data-quality expectations)
-- Reads Bronze tables (defined in bronze.sql) by name; siblings by name.
-- ============================================================================

-- ============================ SILVER — dimensions ==========================
CREATE OR REFRESH MATERIALIZED VIEW silver_dim_ip (
  CONSTRAINT valid_ip_id      EXPECT (ip_id IS NOT NULL)                                    ON VIOLATION FAIL UPDATE,
  CONSTRAINT valid_ip_name    EXPECT (ip_name IS NOT NULL AND length(trim(ip_name)) > 0),
  CONSTRAINT valid_origin     EXPECT (origin IN ('original','licensed')),
  CONSTRAINT plausible_launch EXPECT (launch_year IS NULL OR launch_year BETWEEN 1990 AND year(current_date()) + 1)
)
COMMENT 'Cleaned IP/brand dimension' AS
SELECT ip_id, ip_name, artist_name, origin, launch_year
FROM ip_brands;

CREATE OR REFRESH MATERIALIZED VIEW silver_dim_product (
  CONSTRAINT valid_product_id    EXPECT (product_id IS NOT NULL)                             ON VIOLATION FAIL UPDATE,
  CONSTRAINT valid_sku           EXPECT (sku_code IS NOT NULL AND length(trim(sku_code)) > 0),
  CONSTRAINT valid_product_type  EXPECT (product_type IN ('blind_box','mega_400','mega_1000','plush_pendant','plush_doll','accessory','blocks')),
  CONSTRAINT non_negative_price  EXPECT (retail_price IS NULL OR retail_price >= 0),
  CONSTRAINT non_negative_cost   EXPECT (standard_cost IS NULL OR standard_cost >= 0),
  CONSTRAINT non_negative_margin EXPECT (unit_margin >= 0),
  CONSTRAINT valid_secret_ratio  EXPECT (secret_ratio IS NULL OR secret_ratio BETWEEN 0 AND 1)
)
COMMENT 'Conformed product dimension (ecom catalog + retail cost)' AS
SELECT
  p.product_id, p.sku_code, p.figure_name AS product_name,
  s.series_id, s.series_name, s.secret_ratio,
  b.ip_id, b.ip_name, b.artist_name, b.origin,
  p.product_type, CAST(p.is_secret AS BOOLEAN) AS is_secret,
  p.unit_price AS retail_price, c.standard_cost,
  ROUND(p.unit_price - COALESCE(c.standard_cost, 0), 2) AS unit_margin,
  (p.product_type = 'blind_box') AS is_blind_box
FROM products p
LEFT JOIN product_series s ON p.series_id = s.series_id
LEFT JOIN ip_brands b ON s.ip_id = b.ip_id
LEFT JOIN product_catalog c ON p.product_id = c.product_id;

CREATE OR REFRESH MATERIALIZED VIEW silver_dim_member (
  CONSTRAINT valid_member_id     EXPECT (member_id IS NOT NULL)                              ON VIOLATION FAIL UPDATE,
  CONSTRAINT valid_email         EXPECT (email IS NULL OR email LIKE '%@%.%'),
  CONSTRAINT valid_tier          EXPECT (membership_tier IN ('Rookie','Silver','Gold','Black Card')),
  CONSTRAINT non_negative_points EXPECT (points_balance IS NULL OR points_balance >= 0),
  CONSTRAINT signup_not_future   EXPECT (signup_date IS NULL OR signup_date <= current_date())
)
COMMENT 'Cleaned member dimension — standardized country, typed flags' AS
SELECT
  member_id, first_name, last_name, email, phone, city,
  country AS country_raw,
  CASE
    WHEN upper(trim(country)) IN ('US','USA','U.S.','UNITED STATES') THEN 'United States'
    WHEN upper(trim(country)) IN ('SG','SGP','SINGAPORE') THEN 'Singapore'
    WHEN upper(trim(country)) IN ('UK','U.K.','UNITED KINGDOM') THEN 'United Kingdom'
    WHEN upper(trim(country)) IN ('KOREA','KR','S.KOREA','SOUTH KOREA') THEN 'South Korea'
    ELSE initcap(trim(country))
  END AS country,
  signup_date, membership_tier, points_balance, birthday,
  CAST(marketing_opt_in AS BOOLEAN) AS marketing_opt_in
FROM members;

CREATE OR REFRESH MATERIALIZED VIEW silver_dim_store (
  CONSTRAINT valid_store_id   EXPECT (store_id IS NOT NULL)                                   ON VIOLATION FAIL UPDATE,
  CONSTRAINT valid_store_type EXPECT (store_type IN ('flagship','standard','pop_bakery','roboshop_hub')),
  CONSTRAINT valid_status     EXPECT (status IN ('active','closed','maintenance','inactive')),
  CONSTRAINT valid_latitude   EXPECT (latitude IS NULL OR latitude BETWEEN -90 AND 90),
  CONSTRAINT valid_longitude  EXPECT (longitude IS NULL OR longitude BETWEEN -180 AND 180),
  CONSTRAINT positive_area    EXPECT (floor_area_sqm IS NULL OR floor_area_sqm > 0)
)
COMMENT 'Store dimension' AS
SELECT store_id, store_name, store_type, country, region, city,
       latitude, longitude, open_date, floor_area_sqm, status
FROM stores;

-- ============================ SILVER — facts ===============================
CREATE OR REFRESH MATERIALIZED VIEW silver_fact_online_sales (
  CONSTRAINT valid_order_item_id   EXPECT (order_item_id IS NOT NULL)                        ON VIOLATION FAIL UPDATE,
  CONSTRAINT valid_order_id        EXPECT (order_id IS NOT NULL)                             ON VIOLATION DROP ROW,
  CONSTRAINT valid_product_id      EXPECT (product_id IS NOT NULL)                           ON VIOLATION DROP ROW,
  CONSTRAINT valid_quantity        EXPECT (quantity > 0)                                     ON VIOLATION DROP ROW,
  CONSTRAINT valid_amount          EXPECT (line_total >= 0)                                  ON VIOLATION DROP ROW,
  CONSTRAINT non_negative_price    EXPECT (unit_price >= 0),
  CONSTRAINT valid_order_status    EXPECT (order_status IN ('created','paid','packed','shipped','delivered','cancelled','refunded')),
  CONSTRAINT order_date_not_future EXPECT (order_date <= current_date())
)
COMMENT 'Online order lines (orders x order_items)' AS
SELECT
  oi.order_item_id, oi.order_id, o.member_id, CAST(o.order_datetime AS TIMESTAMP) AS order_datetime,
  CAST(o.order_datetime AS DATE) AS order_date,
  o.channel, o.ship_country, o.order_status,
  oi.product_id, oi.quantity, oi.unit_price, oi.line_total, o.currency
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id;

CREATE OR REFRESH MATERIALIZED VIEW silver_fact_pos_sales (
  CONSTRAINT valid_txn_id        EXPECT (txn_id IS NOT NULL)                                 ON VIOLATION FAIL UPDATE,
  CONSTRAINT valid_product_id    EXPECT (product_id IS NOT NULL)                             ON VIOLATION DROP ROW,
  CONSTRAINT valid_quantity      EXPECT (quantity > 0)                                       ON VIOLATION DROP ROW,
  CONSTRAINT non_negative_amount EXPECT (sale_amount >= 0)                                   ON VIOLATION DROP ROW,
  CONSTRAINT non_negative_price  EXPECT (unit_price >= 0),
  CONSTRAINT valid_payment_type  EXPECT (payment_type IS NULL OR payment_type IN ('cash','card','mobile')),
  CONSTRAINT valid_channel       EXPECT (channel IN ('store','roboshop'))
)
COMMENT 'In-store & roboshop POS lines' AS
SELECT
  txn_id, store_id, machine_id, product_id, member_id,
  quantity, unit_price, sale_amount, currency,
  CAST(txn_timestamp AS TIMESTAMP) AS txn_timestamp, CAST(txn_timestamp AS DATE) AS txn_date, payment_type, employee_id,
  CASE WHEN machine_id IS NOT NULL THEN 'roboshop' ELSE 'store' END AS channel
FROM pos_transactions;

CREATE OR REFRESH MATERIALIZED VIEW silver_fact_sales (
  CONSTRAINT valid_sale_id        EXPECT (sale_id IS NOT NULL)                               ON VIOLATION FAIL UPDATE,
  CONSTRAINT valid_channel        EXPECT (channel IN ('online','store','roboshop'))          ON VIOLATION DROP ROW,
  CONSTRAINT valid_product_id     EXPECT (product_id IS NOT NULL)                            ON VIOLATION DROP ROW,
  CONSTRAINT valid_quantity       EXPECT (quantity > 0)                                      ON VIOLATION DROP ROW,
  CONSTRAINT non_negative_amount  EXPECT (gross_amount >= 0)                                 ON VIOLATION DROP ROW,
  CONSTRAINT valid_sale_date      EXPECT (sale_date IS NOT NULL),
  CONSTRAINT sale_date_not_future EXPECT (sale_date <= current_date())
)
COMMENT 'UNIFIED omnichannel sales fact (online + store + roboshop)' AS
SELECT
  CONCAT('ONL-', CAST(order_item_id AS STRING)) AS sale_id,
  'online' AS channel, order_datetime AS sale_ts, order_date AS sale_date,
  product_id, member_id,
  CAST(NULL AS BIGINT) AS store_id, CAST(NULL AS BIGINT) AS machine_id,
  quantity, line_total AS gross_amount, currency, ship_country AS country
FROM silver_fact_online_sales
WHERE order_status <> 'cancelled'
UNION ALL
SELECT
  CONCAT('POS-', CAST(p.txn_id AS STRING)) AS sale_id,
  p.channel, p.txn_timestamp AS sale_ts, p.txn_date AS sale_date,
  p.product_id, p.member_id, p.store_id, p.machine_id,
  p.quantity, p.sale_amount AS gross_amount, p.currency, st.country
FROM silver_fact_pos_sales p
LEFT JOIN silver_dim_store st ON p.store_id = st.store_id;

CREATE OR REFRESH MATERIALIZED VIEW silver_fact_pop_draw (
  CONSTRAINT valid_draw_id        EXPECT (draw_id IS NOT NULL)                               ON VIOLATION FAIL UPDATE,
  CONSTRAINT valid_product_id     EXPECT (drawn_product_id IS NOT NULL)                      ON VIOLATION DROP ROW,
  CONSTRAINT non_negative_price   EXPECT (price_paid >= 0)                                   ON VIOLATION DROP ROW,
  CONSTRAINT valid_secret_ratio   EXPECT (secret_ratio IS NULL OR secret_ratio BETWEEN 0 AND 1),
  CONSTRAINT draw_date_not_future EXPECT (draw_date <= current_date())
)
COMMENT 'Online blind-box draws with IP/series + typed secret-hit flag' AS
SELECT
  pd.draw_id, pd.member_id, pd.series_id, b.ip_name, s.series_name, s.secret_ratio,
  pd.drawn_product_id, CAST(pd.is_secret_hit AS BOOLEAN) AS is_secret_hit,
  pd.price_paid, CAST(pd.draw_datetime AS TIMESTAMP) AS draw_datetime, CAST(pd.draw_datetime AS DATE) AS draw_date
FROM pop_draw pd
LEFT JOIN product_series s ON pd.series_id = s.series_id
LEFT JOIN ip_brands b ON s.ip_id = b.ip_id;

CREATE OR REFRESH MATERIALIZED VIEW silver_fact_inventory (
  CONSTRAINT valid_inventory_id   EXPECT (inventory_id IS NOT NULL)                          ON VIOLATION FAIL UPDATE,
  CONSTRAINT valid_store_id       EXPECT (store_id IS NOT NULL)                              ON VIOLATION DROP ROW,
  CONSTRAINT valid_product_id     EXPECT (product_id IS NOT NULL)                            ON VIOLATION DROP ROW,
  CONSTRAINT non_negative_qty     EXPECT (qty_on_hand >= 0),
  CONSTRAINT non_negative_reorder EXPECT (reorder_point IS NULL OR reorder_point >= 0)
)
COMMENT 'Store inventory with stockout / reorder flags' AS
SELECT inventory_id, store_id, product_id, qty_on_hand, reorder_point, last_restock_date,
       (qty_on_hand = 0) AS is_stockout,
       (qty_on_hand < reorder_point) AS is_below_reorder
FROM store_inventory;

CREATE OR REFRESH MATERIALIZED VIEW silver_fact_supply (
  CONSTRAINT valid_po_id          EXPECT (po_id IS NOT NULL)                                 ON VIOLATION FAIL UPDATE,
  CONSTRAINT valid_product_id     EXPECT (product_id IS NOT NULL)                            ON VIOLATION DROP ROW,
  CONSTRAINT valid_quantity       EXPECT (quantity > 0)                                      ON VIOLATION DROP ROW,
  CONSTRAINT non_negative_cost    EXPECT (unit_cost IS NULL OR unit_cost >= 0),
  CONSTRAINT valid_status         EXPECT (status IN ('draft','sent','confirmed','in_transit','received','closed')),
  CONSTRAINT non_negative_lead    EXPECT (actual_lead_days IS NULL OR actual_lead_days >= 0),
  CONSTRAINT expected_after_order EXPECT (expected_date IS NULL OR expected_date >= order_date)
)
COMMENT 'Purchase-order lines with supplier + lead-time' AS
SELECT
  po.po_id, po.supplier_id, sup.supplier_name, sup.country AS supplier_country, sup.category,
  li.product_id, li.quantity, li.unit_cost, po.order_date, po.expected_date, po.received_date, po.status,
  DATEDIFF(po.received_date, po.order_date) AS actual_lead_days,
  sup.lead_time_days AS expected_lead_days
FROM po_line_items li
JOIN purchase_orders po ON li.po_id = po.po_id
JOIN suppliers sup ON po.supplier_id = sup.supplier_id;
