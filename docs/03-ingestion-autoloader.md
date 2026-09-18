# 03 · Ingestion — Auto Loader (Bronze)

`src/transformations/bronze.sql` defines **19 streaming tables**, one per source table, each
ingesting its CSV folder with **Auto Loader** via `read_files`:

```sql
CREATE OR REFRESH STREAMING TABLE orders
COMMENT 'Bronze — Online order headers (ecommerce)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/orders',
  format => 'csv', header => 'true', inferColumnTypes => 'true');
```

- `${source_path}` = `/Volumes/${catalog}/${schema}/${landing_volume}` — injected from the
  pipeline `configuration` block (`resources/medallion.pipeline.yml`), which is fed by bundle variables.
- `inferColumnTypes` types numeric/date/decimal columns correctly so the Silver expectations
  (e.g. `quantity > 0`) evaluate as intended.
- Streaming + incremental: re-running the setup job and pipeline picks up new/changed files.

Bronze keeps the **source table names** unchanged, so Silver reads them by bare name.
