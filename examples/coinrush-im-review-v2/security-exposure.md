# 敏感信息泄漏 & 隐私 & 供应链

> 合并原"敏感信息泄漏"与"隐私&合规&依赖安全"：都是"敏感数据流向了不该去的地方"。

```text
审计日志、错误返回、配置、脚本、构建产物中的敏感信息暴露和供应链风险。

起点：
- grep：secret, skey, sign_key, token, password, Authorization, Cookie, DSN, AppKey, AppSecret, access_key, private_key, api_key
- 配置与部署：apps/*/internal/config、deploy/、docker-compose*.yml、Dockerfile、Makefile
- 脚本：scripts/ 各子目录（ci/data/dev/release/services）
- 高危打印点：gateway WS 握手与认证日志、callback 原始 body、panic/recover 日志、error message 拼接 DSN/URL

敏感信息泄漏：
- 凭证硬编码进代码/配置/脚本/compose 文件
- request/response 全量打印；callback 原始 body、query、header 入日志
- error 信息把 DSN、内部地址、堆栈返回给客户端
- 脱敏逻辑是否覆盖嵌套结构和错误分支

隐私数据：
- 用户敏感字段是否进入日志、埋点、调试接口或第三方请求
- 用户删除/注销/封禁后数据是否仍被使用；删除是否只删主表不删缓存/索引
- 导出、修复脚本是否打印或留存敏感数据
- 前端可见字段是否带出内部风控、结算、权限信息

供应链：
- go.mod replace 到本地路径或临时 fork；依赖存在已知漏洞
- Docker base image 用 latest 或过旧；构建产物含 .env、私钥、测试数据
- CI 配置中泄漏 token 或生产配置

每个发现说明：泄漏字段与位置、面向谁泄漏（客户端/日志/仓库/第三方）、触发条件、脱敏或移除方案。不给法律结论，只报工程实现风险。
```
