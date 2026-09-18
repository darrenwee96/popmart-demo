# 05 · Genie space

`resources/genie.yml` + `genie/popmart.geniespace.json` define a **native `genie_spaces`
DAB resource** — Genie deploys with the bundle (no separate API call).

- **Data sources:** the 8 `gold_*` marts + key `silver_*` tables (`silver_fact_sales`,
  `silver_dim_member/product/store`).
- **Instructions** give business context (channels online/store/roboshop, USD, blind-box
  secret odds, omnichannel definition, prefer Gold for rollups).
- **Sample & example questions** with curated SQL, e.g. *"Revenue by IP, online vs in-store"*,
  *"Secret-hit rate vs designed odds"*, *"Monthly revenue by channel"*.

Edit it in the UI and sync back with:
`databricks bundle generate genie-space --resource popmart_genie --force`
