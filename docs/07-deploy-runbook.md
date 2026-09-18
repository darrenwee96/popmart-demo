# 07 · 部署手册

前置条件：Databricks CLI ≥ 0.230、一个名为 `popmart` 的 profile，且对 `popmart.default`
拥有 `CREATE_TABLE` / `CREATE_VOLUME` / `CREATE_MATERIALIZED_VIEW` 权限。

```bash
# 0. 进入仓库根目录
cd popmart-demo

# 1. 校验 bundle
databricks bundle validate -t dev --profile popmart

# 2. 部署所有资源（Volume、作业、管道、仪表板、Genie 空间）
databricks bundle deploy -t dev --profile popmart

# 3. 生成 CSV 子集并写入落地 Volume
databricks bundle run popmart_setup -t dev --profile popmart

# 4. 构建 Bronze -> Silver -> Gold
databricks bundle run popmart_medallion -t dev --profile popmart

# 5. 打开仪表板与 Genie
databricks bundle summary -t dev --profile popmart
```

顺序很重要：**部署 → 生成数据 → 运行管道**。仪表板与 Genie 查询 Gold 表，
因此在第 4 步之后生效。若要重新生成数据，重跑第 3–4 步
（如更改了 CSV 结构，请在管道上使用 `--full-refresh-all`）。

### 拆除
`databricks bundle destroy -t dev --profile popmart`
