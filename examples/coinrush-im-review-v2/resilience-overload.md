# 超时重试降级 & 限流背压

> 合并原"context/超时/重试"与"限流、背压与资源耗尽"：都回答"依赖变慢、流量变大、失败发生时系统怎么垮"。
> N+1 与 SQL 性能看 `perf-capacity.md`。

```text
审计外部依赖失败和流量过载两类压力下的系统行为。

起点：
- RPC 客户端：gateway 调 app-service 的 client 配置（超时/重试）；app-service 外呼第三方（如批量取用户信息的串行外呼热点）
- WS 广播路径：gateway ws 扇出、signaldispatch——慢连接是否阻塞整体
- job：internal/job 各 job 的 context 来源与重试策略

context 与超时：
- context.Background() 绕过请求取消；外部请求无 timeout
- goroutine 不监听 ctx.Done()；请求结束后继续用 request-scoped 对象
- job 误用请求 context 被中途取消；服务关闭时 worker/actor 不优雅退出

重试与降级：
- retry 无幂等保护或无 backoff；失败重试可能形成雪崩
- 依赖失败后静默降级导致业务状态错误；fallback 返回空数据但调用方以为成功
- 网络错误/超时/业务错误未区分；第三方部分成功处理不完整

限流与背压：
- 单用户/单 IP/单房间缺少频率限制；WS 单连接消息频率无限制
- goroutine per message 无上限；channel 无界或积压无告警
- 批量接口无分页/limit；用户参数可放大 Redis/MySQL 查询
- 广播被单个慢连接阻塞；无限制读取 request body；callback 可被重复大量触发

只报告真实外部输入或真实依赖故障能触发，且会造成请求挂死、资源耗尽、状态错误或雪崩的问题。每个发现说明：压力来源、放大路径、最坏情况、最小修复方向。
```
