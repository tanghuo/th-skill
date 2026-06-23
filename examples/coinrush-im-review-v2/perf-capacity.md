# 性能退化 & SQL/索引

> 数据量与并发量上升后明显退化的点。过载与背压看 `resilience-overload.md`。

```text
审计高频入口、批处理、定时任务和数据库查询在数据增长后的退化风险。

起点：
- store/mysqlstore：全部 SQL 对照 deploy/mysql/schema.sql 的索引定义检查
- internal/job：批处理是否分页、是否全表扫、能否断点恢复
- 热路径：进房/送礼/房间列表等高频 logic 中循环查 DB/Redis/RPC 的点（已知热点：批量取用户信息的串行外呼）

应用层：
- 循环中查 DB/Redis/RPC 形成 N+1；未分页读大表、大 Redis 集合
- Redis KEYS / SMEMBERS / 全量 ZRANGE 等无界操作
- 大对象全量构造/复制；热路径重复解析配置、重建客户端
- 高并发路径上的全局锁

SQL / 索引（MySQL 5.7）：
- where 条件无法命中索引；函数包裹索引列、隐式类型转换、like 前缀通配导致失效
- 复合索引字段顺序与真实查询不匹配；order by 不能利用索引
- limit + offset 深分页；SELECT *；update/delete 缺少限制条件
- 5.7 限制：不要给出依赖 8.0+ 特性（降序索引、窗口函数等）的修复建议

每个发现说明：入口路径、数据规模如何增长、退化点、最坏情况影响、最小修复方向（索引/分页/批量查询/增量扫描/缓存）。
```
