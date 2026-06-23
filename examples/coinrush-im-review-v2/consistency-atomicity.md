# 事务边界 & 幂等 & 半成功状态

> 一个业务动作跨 MySQL/Redis/RPC/WS 推送时的原子性与幂等。
> 状态机非法流转看 `consistency-state.md`，结算重跑幂等看 `money-settlement.md`。

```text
检查逻辑上应原子完成的业务路径，确认 MySQL、Redis、RPC、WS 推送和内存状态之间是否存在半成功状态或缺乏幂等边界。

起点：
- 多步写入的用例：app-service 的 logic / application 中送礼、进退房、开关播、任务奖励路径
- 异步消费与重试：internal/job/ 下各 job 与 consumer（如 anchortaskrewardconsumer）
- Redis 与 MySQL 双写点：store/appredisstore 与 mysqlstore 被同一用例先后调用的位置

事务边界：
- 一个业务动作多次 DB 写入但无事务；事务内调用外部 RPC / Redis / 推送
- MySQL 写成功后 Redis / WS 推送失败无补偿；Redis 标记成功但 MySQL 回滚
- 事务提交前对外发通知，外部看到未提交状态
- 事务内执行耗时外部调用导致锁持有过长

幂等：
- 重复请求/重复回调是否重复写入；幂等键是否包含正确业务维度
- 唯一键/锁/Redis lease 是否和业务不变量一致；终态是否还能被重复修改
- 乐观锁 CAS 失败后的处理；分布式锁过期后是否双写

异步任务：
- 同一业务对象是否可能被多个 worker 同时处理；重试是否重复执行副作用
- 批处理扫到异常数据是修复/标记还是永远重复扫描；是否有分页/游标/checkpoint
- callback/消息乱序到达的影响；worker 退出是否丢弃内存中的任务

每个发现给出：真实入口和操作顺序、失败点与半成功状态、缺失的幂等边界、最小复现顺序、业务后果、最小修复方向（事务/outbox/补偿/幂等键/重试去重）。
```
