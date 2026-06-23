# 错误处理黑洞

```text
找出项目中错误被忽略、覆盖或吞掉后仍继续执行的问题。

重点关注：

- `_ = someFunc()`
- err 被赋值后从未检查就被覆盖
- error 被 log 后继续执行而非 return / rollback / compensate
- 事务、Redis、RPC、HTTP、第三方 API 失败后继续使用结果
- JSON 反序列化失败后继续访问字段
- Close / Commit / Rollback / Flush 失败影响业务一致性
- panic / recover 后吞掉错误，调用方误以为成功

误报过滤：明确 best-effort 且失败不影响后续依赖状态的，不报告。
只报告后续逻辑依赖该结果，或会导致状态不一致、资损、安全、泄漏的问题。

每个发现说明：

- 错误在哪里产生
- 如何被忽略或覆盖
- 后续代码为什么依赖这个结果
- 触发后果
- 修复方向
```
