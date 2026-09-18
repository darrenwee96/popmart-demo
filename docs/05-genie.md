# 05 · Genie 空间

`resources/genie.yml` + `genie/popmart.geniespace.json` 将 Genie 定义为**原生的 `genie_spaces`
DAB 资源** —— Genie 随 bundle 一起部署（无需单独调用 API）。

- **数据源：** 8 张 `gold_*` 集市 + 若干关键 `silver_*` 表（`silver_fact_sales`、
  `silver_dim_member/product/store`）。
- **指令（Instructions）** 提供业务上下文（渠道 online/store/roboshop、币种 USD、
  盲盒隐藏款概率、全渠道会员定义、汇总优先使用 Gold）。
- **示例问题与样例问题** 附带精选 SQL，例如「按 IP 的营收，线上 vs 门店」、
  「隐藏款中签率 vs 设计概率」、「按渠道的月度营收」。

在 UI 中修改后，可用以下命令同步回 bundle：
`databricks bundle generate genie-space --resource popmart_genie --force`
