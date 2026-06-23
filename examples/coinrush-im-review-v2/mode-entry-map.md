# 高风险入口识别

> 审计前置：产出可复用的审计地图。独立模式，不拼接 `_base.md`。
> 产物落盘 `.local/review/entry-map.md`（带生成日期）；已存在时做增量刷新而非重做——对比 git 变化，更新新增/删除的入口即可。

```text
不要报告问题。识别项目中的高风险入口和核心状态对象，产出审计地图并写入 .local/review/entry-map.md。

需要枚举：
1. 公网 HTTP / WebSocket / callback 入口（以 apps/gateway/signal.api 和 handler 注册为准）
2. RPC 入口（rpc/proto/*.proto 对应实现）
3. job / worker / 定时任务入口（apps/app-service/internal/job）
4. destructive tools / scripts（tools/、scripts/data、scripts/release）
5. 核心 MySQL 表（deploy/mysql/schema.sql）和核心 Redis key（internal/store/redisstore 为主：连接注册/房态/锁/重放；apps/app-service/internal/store/appredisstore 为辅：礼物连击/关单重试/上麦邀请）
6. 核心状态字段与流转路径（roomstate / roomactor / 结算状态）
7. 资金/结算/礼物路径；权限判断路径
8. 关键外部依赖与配置项；发布/migration/compose 入口

每个条目给出：文件路径、函数名、触发方式、涉及的核心状态、建议优先审计的主题文件名。
文件头部写明生成日期和基于的 commit，便于下次增量刷新。
```
