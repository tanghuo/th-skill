# 契约对齐：API / 字段语义 / Schema

> 合并原 contract 三件套：都回答"声明的语义和实际行为是否一致"。

```text
审计对外契约、字段语义、schema 与代码三层的一致性。

起点：
- 契约源：apps/gateway/signal.api、rpc/proto/*.proto、docs/ 下对外文档
- schema 源：deploy/mysql/schema.sql 与 deploy/mysql/changesql 迁移脚本
- 来源可信度从高到低：线上实际行为 > .api/.proto > docs/*.md > 注释；冲突时说明哪侧更可信，不默认文档正确

对外契约：
- 字段名、类型、required/optional、默认值、enum 含义在 api/proto/docs/实现间不一致
- 文档说会返回但代码没返回（或反之）；HTTP 与 WS 表达同一语义但字段不同
- callback 文档与实际处理不一致；错误码定义与实际返回不一致

字段单位与时间语义：
- 分/元/金币混用；秒/毫秒混用；存储单位与展示单位换算口径不一
- 历史字段被新业务复用导致语义漂移；字段名与实际含义脱节
- UTC/本地时区混用；Unix 时间戳与 DB datetime 转换是否一致
- stat_date 口径：必须按主播结算时区，相关查询与文档是否一致
- 定时任务的自然日/滚动窗口边界与产品定义是否一致；< / <= 边界是否重复或漏算
- Redis TTL 与 MySQL 过期时间语义是否一致

Schema / Model / Query：
- schema 已删改的字段仍被代码读取；代码写入 schema 不存在的字段
- model 落后于 schema.sql；nullable 字段被代码按非空使用
- 唯一约束是否真的支撑业务幂等；新增字段有无默认值与历史数据语义
- 复合索引顺序与真实查询匹配（性能细节归 perf-capacity，这里只看正确性）

只报告会导致前端出错、统计/结算口径错误、兼容性破坏或业务语义误用的差异。
```
