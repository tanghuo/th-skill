# 资源泄漏

```text
检查项目中所有资源创建和释放路径，找出可能未正确关闭、取消或回收的泄漏问题。

重点关注：

- io.Closer：HTTP response body、文件句柄、数据库连接、gRPC stream
- context.WithCancel / WithTimeout 创建后未 cancel
- time.Ticker / Timer 未 Stop
- goroutine 等待 channel 永不退出
- WebSocket 关闭后关联资源未释放
- errgroup / WaitGroup 异常分支无法收敛
- defer 放在循环中导致延迟释放
- early return 和 error 分支遗漏 close / cancel / rollback

每个发现说明：

- 资源在哪里创建
- 正常路径如何释放
- 异常路径如何遗漏
- 触发条件
- 长期运行后的影响
- 修复方向

只报告确实存在泄漏路径的问题。
```
