# 并发竞态 & 资源泄漏

> 合并原"并发&数据竞争"与"资源泄漏"：都是 goroutine 生命周期与共享状态的运行时问题。

```text
审计 goroutine 共享状态的竞态风险和资源创建/释放路径的泄漏风险。

起点：
- apps/gateway/internal/ws：连接表、单连接读写 goroutine、广播扇出
- apps/app-service/internal/roomactor：单线程 actor 的边界——重点找绕过 actor 直接并发改房间状态的代码
- apps/app-service/internal/job 与 apps/app-service/internal/signaldispatch：worker goroutine 的启动、退出与共享对象

并发竞态：
- map 并发读写、共享 slice append、全局缓存/连接表无锁访问
- WebSocket 同一连接的并发写、write on closed conn
- goroutine 闭包捕获循环变量；多 goroutine 改同一结构体字段
- actor/worker/callback 并发修改同一业务对象，缺少 happens-before 保证

资源泄漏：
- HTTP response body、gRPC stream、文件句柄未 Close
- context.WithCancel/WithTimeout 未 cancel；Ticker/Timer 未 Stop
- goroutine 等 channel 永不退出；errgroup/WaitGroup 异常分支不收敛
- defer 放在循环里延迟释放；early return / error 分支漏 close/cancel/rollback
- 连接关闭后关联资源（订阅、计数、actor 引用）未释放

每个竞态发现必须说明：goroutine A/B 分别从哪启动、共享对象与字段、为什么没有同步保证、最小触发顺序、后果（panic/数据错乱/状态覆盖/乱序）。
每个泄漏发现必须说明：资源在哪创建、正常路径如何释放、异常路径如何遗漏、长期运行影响。
只报告有实际并发路径或真实泄漏路径的问题。
```
