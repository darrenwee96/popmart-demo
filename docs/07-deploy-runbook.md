# 07 · Deploy runbook

Prerequisites: Databricks CLI ≥ 0.230, a profile named `popmart`, and access to the `popmart`
catalog with `CREATE_TABLE` / `CREATE_VOLUME` / `CREATE_MATERIALIZED_VIEW` on `popmart.default`.

```bash
# 0. from the repo root
cd popmart-demo

# 1. validate the bundle
databricks bundle validate -t dev --profile popmart

# 2. deploy all resources (volume, job, pipeline, dashboard, genie space)
databricks bundle deploy -t dev --profile popmart

# 3. generate the CSV subset into the landing volume
databricks bundle run popmart_setup -t dev --profile popmart

# 4. build Bronze -> Silver -> Gold
databricks bundle run popmart_medallion -t dev --profile popmart

# 5. open the dashboard + Genie
databricks bundle summary -t dev --profile popmart
```

Order matters: **deploy → setup job → pipeline**. The dashboard and Genie query the Gold
tables, so they light up after step 4. To regenerate data, re-run steps 3–4 (use
`--full-refresh-all` on the pipeline if you changed the CSV schema).

### Tear down
`databricks bundle destroy -t dev --profile popmart`
