# 06 · AI/BI 仪表板

`resources/dashboard.yml` + `dashboards/popmart_omnichannel.lvdash.json` 将 Lakeview 仪表板
定义为一个 **DAB 资源**，由 Serverless Starter 数仓提供查询能力。

基于 Gold 集市的 8 个数据集，分布在 3 个页面（总览 / 全渠道与 IP / 零售与供应链）：
全渠道销售、IP 表现、隐藏款中签率、会员分层、门店表现、库存健康、全渠道客户、供应链。

每个数据集都指向 catalog **`popmart`**、schema **`default`**。首次运行管道后 Gold 表即存在，
仪表板即可渲染。可从 `bundle summary` 输出的 URL 打开。
