# 05 · Genie 智能体（Genie Agents）

`resources/genie.yml` + `genie/popmart.geniespace.json` 将 Genie 智能体定义为**原生的 `genie_spaces`
DAB 资源** —— Genie 智能体随 bundle 一起部署（无需单独调用 API）。

- **数据源：** 8 张 `gold_*` 集市 + 若干关键 `silver_*` 表（`silver_fact_sales`、
  `silver_dim_member/product/store`）。
- **指令（Instructions）** 提供业务上下文（渠道 online/store/roboshop、币种 USD、
  盲盒隐藏款概率、全渠道会员定义、汇总优先使用 Gold）。
- **示例问题、示例 SQL 与基准问题（benchmarks）** 帮助智能体给出一致、可信的回答。

## 可直接向 Genie 智能体提问的示例

部署后打开 Genie 智能体，用自然语言直接提问（无需写 SQL）。以下问题按业务主题分组，
可直接复制使用，也可以改写成你自己的问题：

### 全渠道营收与趋势
- 各渠道的月度营收是多少？（近 12 个月）
- 线上、门店与机器人商店（roboshop）的营收占比如何？
- 哪个月的总营收最高？
- 所有渠道的总营收是多少？

### IP 表现
- 哪个 IP 营收最高？线上与门店如何拆分？
- 按营收给各 IP 排名，并显示它们的线上/线下占比。
- The Monsters（Labubu）与 Molly、Skullpanda 相比表现如何？

### 盲盒隐藏款（secret）
- 各系列隐藏款的实际中签率与设计概率相比如何？
- 抽盒次数最多的系列有哪些？它们的实际中签率是多少？

### 全渠道会员与分层
- 哪个会员分层的平均生命周期价值（LTV）最高，全渠道比例如何？
- 有多少会员同时在线上和门店消费（全渠道会员）？
- 全渠道会员与单一渠道会员的平均消费差异有多大？

### 门店与机器人商店
- 哪些门店的缺货率最高？
- 营收最高的门店有哪些？
- 机器人商店与直营门店的营收对比如何？

### 库存与供应链
- 哪些商品的库存健康度最差（缺货风险最高）？
- 各供应商的按时交付与供货表现如何？

> 以上问题对应 Genie 空间中预置的**示例问题（sample questions）**、**示例 SQL** 与
> **基准问题（benchmarks）**。Genie 智能体会结合指令中的业务上下文作答，并说明所应用的
> 渠道与时间范围。

在 UI 中修改后，可用以下命令同步回 bundle：
`databricks bundle generate genie-space --resource popmart_genie --force`
