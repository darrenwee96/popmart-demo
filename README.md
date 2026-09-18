<div align="center">

# Pop Mart 全渠道湖仓 · 上手指南

**从零到可用：在你的 Databricks 工作区端到端部署这套全渠道湖仓 Demo**

</div>

> 只想快速了解这是什么？→ 查看一页读懂的 [项目概览](docs/00-overview.md)（业务故事 · 架构 · 价值）。

![端到端架构](docs/images/architecture-e2e.png)

---

## 你将完成什么

按本指南操作，你会在自己的工作区里得到一套完整、可运行的湖仓：

- 一个 UC Volume，以及生成好的 **19 张源表**（CSV，约 5 万行）；
- **Bronze → Silver（含数据质量校验）→ Gold** 的声明式管道；
- 一个 **AI/BI 仪表板** 和一个 **Genie 智能问答**空间。

全部由一个 **Databricks Asset Bundle（DABs）** 声明与部署 —— 一处定义，任意工作区可复现。

> 摄取说明：本 Demo 用脚本生成同构假数据（CSV）经 Auto Loader 摄取；生产环境应改用 [Lakeflow Connect](https://docs.databricks.com/aws/en/ingestion/lakeflow-connect/) 的托管 CDC 直连 MySQL / PostgreSQL。其余环节完全一致。

---

## 前置条件

- **Databricks CLI ≥ 0.230** —— 用 `databricks version` 确认（[安装文档](https://docs.databricks.com/aws/en/dev-tools/cli/install)）；
- 一个能访问目标工作区的 **CLI profile**（本指南统一使用 `popmart`）；
- 工作区已启用 **Unity Catalog + Serverless**；
- 对目标 schema 拥有 **`CREATE_TABLE` / `CREATE_VOLUME` / `CREATE_MATERIALIZED_VIEW`** 权限
  （默认写入 `popmart.default`，可在 `databricks.yml` 调整）。

---

## 第 0 步 · 获取代码

```bash
git clone https://github.com/darrenwee96/popmart-demo.git
cd popmart-demo
databricks version    # 确认 CLI 已安装
```

## 第 1 步 · 配置 profile

创建名为 `popmart` 的 profile，指向你的工作区：

```bash
# 交互式 OAuth 登录（推荐）
databricks auth login --host https://<你的工作区>.cloud.databricks.com --profile popmart

# 或使用个人访问令牌
databricks configure --host https://<你的工作区>.cloud.databricks.com --profile popmart

# 验证身份
databricks current-user me --profile popmart
```

## 第 2 步 · 按需调整目标（可选）

打开 `databricks.yml`，确认 `targets.dev.workspace.host` 指向你的工作区，并按需修改变量：

| 变量 | 含义 | 默认值 |
|---|---|---|
| `catalog` | 发布 Silver/Gold 的 catalog | `popmart` |
| `schema` | 发布 Silver/Gold 的 schema（Volume 也在此） | `default` |
| `landing_volume` | CSV 落地的 Volume 名 | `landing` |
| `warehouse_id` | Genie 与仪表板使用的 SQL 数仓 | 见文件 |

```bash
# 查找可用的 SQL 数仓 ID
databricks warehouses list --profile popmart
```

## 第 3 步 · 校验并部署

```bash
databricks bundle validate -t dev --profile popmart
databricks bundle deploy   -t dev --profile popmart
```

这会创建全部资源：Volume、生成数据的作业、奖章管道、仪表板、Genie 空间（此步不写入任何业务数据）。

## 第 4 步 · 生成数据

```bash
databricks bundle run popmart_setup -t dev --profile popmart
```

在 Serverless 上生成 19 张表并以 CSV 写入落地 Volume（确定性，`seed=42`）。

## 第 5 步 · 运行管道

```bash
databricks bundle run popmart_medallion -t dev --profile popmart
```

构建 **Bronze → Silver（数据质量）→ Gold**。首次运行约需几分钟（Serverless 冷启动）。

## 第 6 步 · 探索成果

```bash
databricks bundle summary -t dev --profile popmart   # 打印各资源的链接
```

- **仪表板**：查看全渠道营收、IP 表现、门店与供应链；
- **Genie**：用自然语言提问，例如「哪个 IP 营收最高？线上线下如何拆分？」；
- **数据质量**：在管道的 **Data Quality** 面板查看各校验的通过/丢弃/告警计数；
- **治理与血缘**：在 Catalog Explorer 中查看 `popmart.default` 的血缘与权限。

> 顺序很重要：**部署（步 3）→ 生成数据（步 4）→ 运行管道（步 5）**。仪表板与 Genie 查询 Gold 表，因此在步 5 之后才有数据。

---

## 项目结构

```
popmart-demo/
├── databricks.yml                     # Bundle 定义 + 变量 + 目标环境
├── resources/                         # 全部 DAB 资源
│   ├── volume.yml · setup.job.yml · medallion.pipeline.yml · dashboard.yml · genie.yml
├── src/
│   ├── setup/generate_seed_data.py    # 合成数据生成器（19 张表）
│   └── transformations/               # bronze.sql · silver.sql · gold.sql
├── dashboards/popmart_omnichannel.lvdash.json
├── genie/popmart.geniespace.json
└── docs/                              # 概览 + 各环节说明（00–07）
```

---

## 深入阅读

| 主题 | 文档 |
|---|---|
| 项目概览（捷径） | [docs/00-overview.md](docs/00-overview.md) |
| 架构总览 | [docs/01-architecture.md](docs/01-architecture.md) |
| 数据生成 | [docs/02-data-generation.md](docs/02-data-generation.md) |
| Auto Loader 摄取 | [docs/03-ingestion-autoloader.md](docs/03-ingestion-autoloader.md) |
| 奖章架构管道 | [docs/04-medallion-pipeline.md](docs/04-medallion-pipeline.md) |
| Genie 智能问答 | [docs/05-genie.md](docs/05-genie.md) |
| AI/BI 仪表板 | [docs/06-dashboard.md](docs/06-dashboard.md) |
| 部署手册 | [docs/07-deploy-runbook.md](docs/07-deploy-runbook.md) |

---

## 常见问题 / 排错

- **没有 `CREATE SCHEMA` 权限**：使用一个已存在的 schema（如 `popmart.default`），在 `databricks.yml` 中把 `schema` 改成它即可。
- **作业/管道找不到 Serverless**：确认工作区已启用 Serverless 计算，并已接受使用条款。
- **Auto Loader 类型不对**：Bronze 已开启 `inferColumnTypes`；若更改了 CSV 结构，运行管道时加 `--full-refresh-all`。
- **host 不匹配**：profile 的 host 必须与 `databricks.yml` 中目标的 `workspace.host` 一致。
- **仪表板/Genie 空白**：确认已完成步 4、步 5，Gold 表已生成。

---

## 清理

```bash
databricks bundle destroy -t dev --profile popmart
```

---

<div align="center">
<sub>由 Databricks Lakehouse 驱动 · MySQL + PostgreSQL → Lakeflow → 奖章架构 → AI/BI 与 Genie，统一治理于 Unity Catalog。</sub>
</div>
