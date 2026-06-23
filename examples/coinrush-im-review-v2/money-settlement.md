# 金额 & 结算专项

> 资损优先级最高的主题。精度/溢出/超扣 + 结算重跑与统计口径。
> 守恒类账目对齐在 `consistency-state.md`，事务半成功在 `consistency-atomicity.md`，本文件看单值正确性和结算专属风险。

```text
审计金额、礼物价值、余额、分成、主播薪资结算路径的数值正确性与重跑安全。

起点：
- apps/app-service/internal/job/ 下 anchor*.go 结算 job 群（earning / salary / settlement / payout / revenueboost / roi）
- 礼物与钱包写路径：store/mysqlstore 中金额相关方法、rpc/proto/gift.proto 对应实现
- 金额字段定义：deploy/mysql/schema.sql

精度与类型：
- 金额是否用 float 参与计算或存储；整数分/厘与展示元换算是否散落多处口径不一
- 跨表/跨接口传递时单位是否混用（分 vs 元 vs 金币/钻石）
- DB 列类型（DECIMAL 位数、BIGINT/INT）能否容纳业务最大值
- 分成/折扣/倍率的取整方向（floor/round/ceil）是否明确一致；多方分账取整后是否对齐总额

溢出与负值：
- 流水累加、数量 × 单价是否可能溢出
- 负数金额/数量能否进入计算；余额扣减是否校验充足、并发下是否扣成负数
- 余额/计数扣减是否原子操作或乐观锁，并发下是否超扣/漏扣

结算重跑与口径（本项目硬要求）：
- 结算 job 重跑时是否真正幂等：重复 insert 有无唯一键兜底、累加型 update 是否会翻倍
- RowsAffected 判断：默认 DSN 是"变更行数"语义，重跑时值未变 RowsAffected==0，不能据此判定"行不存在"而报错或走错分支
- stat_date 必须按主播结算时区；跨天直播必须按当日在场时间切分，不得把整场时长记到开播日
- 结算周期边界 < / <= 是否会重复纳入或漏掉边界数据；重跑窗口与上次窗口重叠时的行为

每个发现说明：金额字段与计算路径、具体触发输入、资损方向（多付/少结/平台亏损）、最小修复方向。
```
