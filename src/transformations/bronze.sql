-- ============================================================================
-- BRONZE — raw ingest from CSV landing zone via Auto Loader (read_files STREAM)
-- Source dir per table: ${source_path}/<table>/   (set in the pipeline config)
-- ============================================================================

CREATE OR REFRESH STREAMING TABLE ip_brands
COMMENT 'Bronze — IP / brand master (ecommerce)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/ip_brands',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE product_series
COMMENT 'Bronze — Blind-box product series (ecommerce)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/product_series',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE products
COMMENT 'Bronze — Product / figure catalog (ecommerce)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/products',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE members
COMMENT 'Bronze — Loyalty members (ecommerce)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/members',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE orders
COMMENT 'Bronze — Online order headers (ecommerce)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/orders',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE order_items
COMMENT 'Bronze — Online order line items (ecommerce)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/order_items',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE payments
COMMENT 'Bronze — Online payments (ecommerce)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/payments',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE pop_draw
COMMENT 'Bronze — Online blind-box draws (ecommerce)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/pop_draw',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE product_reviews
COMMENT 'Bronze — Product reviews (ecommerce)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/product_reviews',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE stores
COMMENT 'Bronze — Physical stores (retail ops)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/stores',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE roboshops
COMMENT 'Bronze — Roboshop vending machines (retail ops)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/roboshops',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE employees
COMMENT 'Bronze — Store employees (retail ops)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/employees',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE product_catalog
COMMENT 'Bronze — Retail product catalog with standard cost (retail ops)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/product_catalog',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE suppliers
COMMENT 'Bronze — Suppliers (retail ops)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/suppliers',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE store_inventory
COMMENT 'Bronze — Per-store inventory levels (retail ops)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/store_inventory',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE pos_transactions
COMMENT 'Bronze — In-store & roboshop POS transactions (retail ops)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/pos_transactions',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE purchase_orders
COMMENT 'Bronze — Purchase order headers (retail ops)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/purchase_orders',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE po_line_items
COMMENT 'Bronze — Purchase order line items (retail ops)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/po_line_items',
  format => 'csv', header => 'true', inferColumnTypes => 'true');

CREATE OR REFRESH STREAMING TABLE shipments
COMMENT 'Bronze — Inbound shipments (retail ops)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/shipments',
  format => 'csv', header => 'true', inferColumnTypes => 'true');
