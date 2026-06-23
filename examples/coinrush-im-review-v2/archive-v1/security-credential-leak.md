# 敏感信息泄漏

```text
扫描项目中日志、错误返回、配置、脚本、callback、HTTP / WS 入口，找出可能泄漏敏感信息的位置。

重点 grep：skey, secret, sign_key, token, password, Authorization, Cookie, DSN, AppKey, AppSecret, access_key, private_key, api_key, request_body, response_body

特别关注：

- gateway WebSocket 握手、用户认证、内部 RPC、第三方 callback
- debug endpoint、panic / recover 日志
- error message 拼接 URL / DSN
- request / response 全量打印
- callback 原始 body、query string、header
- 脱敏逻辑是否覆盖嵌套结构和错误分支

每个发现说明：

- 泄漏字段和位置
- 泄漏面向：客户端、日志、控制台、仓库还是第三方请求
- 触发条件
- 影响范围
- 脱敏或移除方案
```
