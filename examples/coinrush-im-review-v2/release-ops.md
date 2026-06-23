# 发布兼容 & 迁移 & 脚本与启动

> 合并原"发布兼容性&Schema迁移"与"运维工具&脚本&启动顺序"：都是"部署与运维动作会不会出事"。

```text
审计数据库迁移、发布回滚兼容性、运维脚本和启动配置的安全性。

起点：
- 迁移：deploy/mysql/changesql 下迁移脚本，对照 schema.sql
- 部署：docker-compose*.yml、Makefile、scripts/release 与 scripts/services
- 数据脚本：scripts/data（seed/settlement/analytics）、tools/
- 启动配置：apps/*/internal/config 与 svc 的依赖构造

发布与迁移（MySQL 5.7）：
- 新代码依赖新字段但迁移不保证先执行；新字段无默认值、历史数据语义不明
- 删改字段后旧版本服务仍可能读写；回滚后新数据旧代码无法识别
- API/WS/proto 字段变更对旧客户端不兼容；Redis key 格式变更无旧格式兼容
- migration 含长事务、全表锁、无分页大更新（5.7 online DDL 能力有限，需特别确认）
- 多服务部署顺序是否在脚本中真实保证

脚本与工具：
- 默认连接哪个环境；dry-run 是否真的不写数据
- 批量删除/更新有无分页、限速、失败恢复；where 为空有无保护
- destructive 操作是否需要二次确认；失败后是否留下半更新状态
- 是否打印敏感数据（与 security-exposure 交叉，这里只看脚本）

启动与配置：
- 必需依赖是否构造期 fail-fast，还是 nil guard 静默跳过
- 配置缺失时的默认值是否危险；dev/test/prod 配置是否可能混用
- 初始化失败后服务是否仍注册 ready

每个发现说明：入口与默认行为、误操作或发布顺序错误的后果、防护建议。
```
