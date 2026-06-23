# context / 超时 / 重试 / 外部依赖韧性

> 合并原"context 超时与取消传播"和"外部依赖超时/重试/熔断/降级"。

```text
检查 RPC、HTTP client、DB、Redis、stream、goroutine 和 job 的 context 使用及外部依赖韧性。

context & 超时：

- context.Background() 绕过请求取消
- 外部请求没有 timeout / deadline
- goroutine 启动后不监听 ctx.Done()
- WithTimeout / WithCancel 创建后没有 cancel
- 请求结束后 goroutine 继续使用 request-scoped 对象
- job 使用请求 context 导致任务中途被取消
- 服务关闭时 worker / actor / consumer 没有优雅退出

外部依赖韧性：

- retry 没有幂等保护或 backoff
- 外部依赖失败后静默降级导致业务状态错误
- 依赖不可用时启动仍成功但核心功能必然失败
- 长时间阻塞调用占满 goroutine / 连接池 / worker
- 第三方 API 返回部分成功时处理不完整
- 网络错误、超时错误、业务错误没有区分
- fallback 返回空数据但调用方误以为成功

只报告会导致请求挂死、资源泄漏、取消不生效、任务误取消、请求堆积或状态错误的问题。
```
