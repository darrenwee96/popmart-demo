# 02 · Data generation

`src/setup/generate_seed_data.py` (a serverless notebook, run by the `popmart_setup` job)
generates a **referentially-consistent subset** of all 19 source tables and writes one CSV
folder per table into the landing volume: `/Volumes/popmart/default/landing/<table>/`.

- Deterministic (`seed=42`), all currency in **USD**, ~24 months of history ending 2026-09-17.
- Sizes controlled by the `size` parameter — **small** (default, ~50k rows) or **medium** (~250k).
- Same table + column names as the original MySQL/PostgreSQL sources, so Bronze/Silver are unchanged.

| Domain | Tables |
|---|---|
| E-commerce (9) | ip_brands, product_series, products, members, orders, order_items, payments, pop_draw, product_reviews |
| Retail ops (10) | stores, roboshops, employees, product_catalog, suppliers, store_inventory, pos_transactions, purchase_orders, po_line_items, shipments |

Referential integrity is preserved (orders→members, order_items→orders/products,
pop_draw→series/products, pos_transactions→stores/products/employees, po_line_items→po/products, …).
A small share of rows are intentionally "imperfect" (e.g. stockouts) so the Silver
data-quality expectations have something to measure.

Run: `databricks bundle run popmart_setup -t dev --profile popmart`
