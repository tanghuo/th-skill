# Schema / Model / Query 对齐

```text
检查 MySQL schema、model struct、SQL 查询、索引、唯一约束和业务读写逻辑是否一致。

重点关注：

- schema 删除或改名的字段是否仍被代码读取
- model 字段是否落后于 deploy/mysql/schema.sql
- 查询条件是否命中正确索引
- order by 是否能利用索引
- 唯一约束是否真的支撑业务幂等
- 新增字段是否有默认值、迁移路径和历史数据语义
- nullable 字段在代码中是否按非空使用
- 代码写入字段但 schema 不存在
- schema 有字段但代码永远不维护
- 复合索引字段顺序是否匹配真实查询

每个发现说明：

- schema 定义 vs model 定义 vs 查询/写入路径
- 不一致点
- 实际后果
- 修复方向
```
