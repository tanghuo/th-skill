# Dead Code

```text
找出项目中真实无用、不可达或已废弃但仍保留的代码。

重点关注：

- 未导出且同包内从未被调用的函数
- 已导出但无注册、路由、反射、接口实现或外部使用意图的函数和类型
- 永远不会命中的分支
- 已废弃但仍维护的兼容逻辑
- 已删除功能遗留的配置、常量、结构体字段、SQL、Redis key
- 只写不读的字段
- 永远不被消费的事件、消息、callback handler

排除：main / init、接口实现方法、反射调用、RPC / HTTP / CLI 注册、framework hook、protobuf / go-zero 约定方法、外部包可能调用的公共 SDK API、生成代码。

不要仅凭 grep 不到调用就判定 exported 函数是 dead code。

每个发现说明：# Dead Code

```text
找出项目中真实无用、不可达或已废弃但仍保留的代码。

重点关注：

- 未导出且同包内从未被调用的函数
- 已导出但无注册、路由、反射、接口实现或外部使用意图的函数和类型
- 永远不会命中的分支
- 已废弃但仍维护的兼容逻辑
- 已删除功能遗留的配置、常量、结构体字段、SQL、Redis key
- 只写不读的字段
- 永远不被消费的事件、消息、callback handler

排除：main / init、接口实现方法、反射调用、RPC / HTTP / CLI 注册、framework hook、protobuf / go-zero 约定方法、外部包可能调用的公共 SDK API、生成代码。

不要仅凭 grep 不到调用就判定 exported 函数是 dead code。

每个发现说明：

- 文件路径和符号名
- 为什么判定为 dead code
- 已检查哪些注册点或调用点
- 删除后的影响
```


- 文件路径和符号名
- 为什么判定为 dead code
- 已检查哪些注册点或调用点
- 删除后的影响
```
