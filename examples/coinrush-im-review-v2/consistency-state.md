# 状态机 & 不变量 & 投影漂移

> 合并原"状态机&不变量"与"MySQL/Redis 状态漂移"：都回答"系统各处声称的状态是否互相一致且合法"。
> 在线状态的实时语义看 `realtime-messaging.md`。

```text
梳理核心状态机与关键不变量，检查非法流转、不变量破坏和多存储投影漂移。

起点：
- 房间状态：internal/roomstate、roomactor、store/appredisstore 与 mysqlstore 的房间读写
- 状态语义基线：sl_voice_room 一行 = 一场直播会话；online_status/status 是投影不是事实源，漂移由 MySQL 驱动的对账 job 收敛——审计时先找到这个对账 job，确认它覆盖所有漂移路径，短暂漂移本身不是 bug
- 结算/任务状态：internal/job 中各 job 的状态字段流转

状态机：
- 是否允许从非法前置状态迁移；close/expire/settle 终态是否还能被修改
- 不同入口是否绕过统一流转逻辑直接改字段（特别是绕过 roomactor 直接写存储）
- 定时任务与用户操作并发修改同一状态；状态字段与时间字段是否绑定一致（closed_at 有值但 status 仍 active）

投影漂移：
- Redis 集合/ZSet 有候选但 MySQL 主记录已不存在；批处理读到脏候选直接 continue 导致重复扫描
- close/cleanup 路径只删了一部分状态；多个 Redis key 表达同一状态只更新其一
- Redis TTL 与 MySQL 状态生命周期不一致；cache miss 回源回填过期数据
- 对账 job 的覆盖缺口：哪类漂移既不会被 TTL 清掉、也不在对账范围内

不变量：
- 金额守恒：收入、支出、余额、结算、手续费是否对齐
- 唯一性：一个主播同时只有一个 active 房间之类的约束由什么保证
- 计数守恒：成员数、在线数、热度、礼物数与来源是否一致
- 时间不变量：开始/结束/结算时间顺序合法性

每个发现给出：不变量或合法流转定义、哪条路径破坏它、哪条读路径会观察到错误状态、最小复现顺序、业务后果、最小修复方向。
```
