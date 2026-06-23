# 限流、背压与资源耗尽

```text
检查公网入口、WebSocket、callback、批量接口、后台任务是否存在资源耗尽风险。

重点关注：

- 无限制读取 request body
- WebSocket 单连接消息频率无限制
- 单用户 / 单 IP / 单房间 / 单 app 缺少限流
- callback 可被重复大量触发
- goroutine per request / per message 没有上限
- channel 无界或队列积压无告警
- 批量接口没有分页、limit、最大数量限制
- Redis / MySQL 查询可能被用户参数放大
- 大 JSON、长字符串、大数组导致 CPU / 内存异常
- 失败重试没有退避，可能形成雪崩
- 广播逻辑被单个慢连接阻塞

只报告真实外部输入能触发，且会造成资源异常、服务降级或成本放大的问题。
```
