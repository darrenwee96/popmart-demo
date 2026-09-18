# 03 · 摄取 —— Auto Loader（Bronze）

`src/transformations/bronze.sql` 定义了 **19 张流式表**，每张对应一个源表，
通过 **Auto Loader** 的 `read_files` 摄取各自的 CSV 文件夹：

```sql
CREATE OR REFRESH STREAMING TABLE orders
COMMENT 'Bronze — Online order headers (ecommerce)' AS
SELECT * FROM STREAM read_files(
  '${source_path}/orders',
  format => 'csv', header => 'true', inferColumnTypes => 'true');
```

- `${source_path}` = `/Volumes/${catalog}/${schema}/${landing_volume}` —— 由管道 `configuration`
  注入（见 `resources/medallion.pipeline.yml`），其值来自 bundle 变量。
- `inferColumnTypes` 会正确推断数值/日期/小数类型，使 Silver 层的数据质量校验
  （例如 `quantity > 0`）按预期生效。
- 流式 + 增量：重新运行生成作业与管道即可拾取新增/变更的文件。

Bronze 保持**源表名不变**，因此 Silver 层可直接按名引用。
