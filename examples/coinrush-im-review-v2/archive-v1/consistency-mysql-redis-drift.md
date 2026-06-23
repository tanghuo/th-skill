# MySQL / Redis 状态漂移

```text
检查 Redis 索引、房间状态、成员状态、任务队列、内存状态和 MySQL 主记录之间是否可能出现单向残留或语义不一致。

重点关注：

- Redis 集合 / ZSet 中存在候选，但 MySQL 主记录已不存在
- 批处理读到脏候选后直接 continue，导致下次重复扫描
- close / cleanup / expire 路径只删了一部分状态
- roomactor 内存、Redis snapshot、MySQL 持久化之间语义不一致
- Redis key TTL 与 MySQL 状态生命周期不一致
- 多个 Redis key 表达同一状态但只更新其中一个
- MySQL 更新成功但 Redis 未更新/未删除
- cache miss 回源后回填了过期或错误数据

每个发现说明：

- 主状态来源是什么
- Redis / 内存 / MySQL 分别存了什么
- 哪条路径导致漂移
- 后续哪条读路径会观察到错误状态
- 修复方向
```
