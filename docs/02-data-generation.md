# 02 · 数据生成

`src/setup/generate_seed_data.py`（一个在 Serverless 上运行的 notebook，由 `popmart_setup` 作业调度）
生成全部 19 张源表的**保持外键一致性的子集**，并将每张表以一个 CSV 文件夹写入落地 Volume：
`/Volumes/popmart/default/landing/<table>/`。

- 确定性生成（`seed=42`），全部币种为 **USD**，约 24 个月历史，截至 2026-09-17。
- 数据量由 `size` 参数控制 —— **small**（默认，约 5 万行）或 **medium**（约 25 万行）。
- 表名与列名与原始的 MySQL / PostgreSQL 源系统完全一致，因此 Bronze / Silver 无需改动。

| 域 | 表 |
|---|---|
| 电商（9） | ip_brands、product_series、products、members、orders、order_items、payments、pop_draw、product_reviews |
| 零售运营（10） | stores、roboshops、employees、product_catalog、suppliers、store_inventory、pos_transactions、purchase_orders、po_line_items、shipments |

生成时保持外键一致性（orders→members、order_items→orders/products、
pop_draw→series/products、pos_transactions→stores/products/employees、po_line_items→po/products 等）。
少量记录被刻意设计为「不完美」（例如缺货），以便 Silver 层的数据质量校验有可度量的对象。

运行：`databricks bundle run popmart_setup -t dev --profile popmart`
