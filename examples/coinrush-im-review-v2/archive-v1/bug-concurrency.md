# 并发 & 数据竞争

```text
扫描项目中所有 goroutine 共享状态的代码路径，找出缺少锁保护、channel 同步、atomic 或单线程 actor 保证的数据竞争风险。

重点关注：

- map 并发读写
- 共享 slice 的 append
- 全局变量、缓存、连接管理器、房间状态、用户连接表
- goroutine 内闭包捕获循环变量
- 多 goroutine 同时修改同一结构体字段
- WebSocket 连接读写并发安全
- roomactor / worker / callback 并发修改同一业务对象

每个发现必须说明：

- goroutine A 和 B 分别从哪里启动
- 共享对象和并发读写的字段
- 为什么没有 happens-before 保证
- 最小触发顺序
- 后果：panic、数据错乱、状态覆盖、消息乱序、连接泄漏

只报告有实际并发路径的问题。不报告单线程初始化代码和无真实并发入口的理论问题。
```
