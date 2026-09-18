# 06 · AI/BI Dashboard

`resources/dashboard.yml` + `dashboards/popmart_omnichannel.lvdash.json` define a Lakeview
dashboard as a **DAB resource**, backed by the Serverless Starter warehouse.

8 datasets over the Gold marts, across 3 pages (overview / omnichannel & IP / retail & supply):
Omnichannel sales, IP performance, Secret-hit rates, Membership tiers, Store performance,
Inventory health, Omnichannel customers, Supply chain.

Each dataset points at catalog **`popmart`**, schema **`default`**. After the first pipeline
run the Gold tables exist and the dashboard renders. Open it from the `bundle summary` URL.
