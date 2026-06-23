# 薄封装 & 单实现接口 & 测试污染

> 合并原"薄封装 & 单实现接口"和"测试驱动的生产污染"。

```text
找出项目中低价值抽象和测试驱动的生产污染。

低价值抽象：

1. interface 只有一个生产实现，且不是为了真实运行时边界
2. 函数只是对另一个函数的简单转发，没有增加逻辑
3. 类型别名或 wrapper struct 只是透传字段
4. service / manager / helper 只包了一层，没有业务语义
5. 过度分层导致调用链变长，但每层没有实质职责

测试污染：

- function fields 用于注入 fake
- 仅在测试中被使用的 optional 参数
- 仅测试调用的 NewXxxWithDefaults
- 生产代码 nil guard 只是为了测试方便
- 为了测试绕过真实鉴权、事务、Redis、RPC 或状态机
- 生产代码中出现 test、mock、fake、stub 命名

不要报告真实边界抽象：RPC client、存储层、Redis/cache、第三方服务、支付/结算/风控、feature flag、多环境配置。
忽略 protobuf 和 go-zero 生成代码。

每个发现说明：

- 位置
- 为什么是低价值或测试污染
- 增加了什么维护成本
- 移除或迁移方案
```
