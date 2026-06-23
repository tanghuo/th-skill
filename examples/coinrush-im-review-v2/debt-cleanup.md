# 技术债：Dead Code & 重复逻辑 & 低价值抽象

> 合并原 debt 三件套。修复阶段可配合 go-abstraction-pruning / go-test-seam-discipline 等本机 skill。

```text
审计真实无用的代码、实质重复的业务逻辑和低价值抽象。

工具步骤（先跑工具再人工串链，已验证有效）：
1. 官方 deadcode 做全程序可达性分析，必须把全部 main 入口一起传入（当前入口包括：
   apps/gateway、apps/app-service、apps/app-service/cmd/run-settlement、apps/app-service/cmd/seed-anchor、
   apps/app-service/cmd/bootstrap-anchor-guild-bindings、tools/rongcloud-system-user-init、
   tools/loadtest/wsroom、tools/rongcloud-user-cleaner、tools/docs/localize_openapi_tags；
   新增 cmd/tools main 时同步补上）：
   GOMODCACHE=/tmp/gomodcache GOCACHE=/tmp/gocache deadcode ./apps/gateway ./apps/app-service ./apps/app-service/cmd/run-settlement ./apps/app-service/cmd/seed-anchor ./apps/app-service/cmd/bootstrap-anchor-guild-bindings ./tools/rongcloud-system-user-init ./tools/loadtest/wsroom ./tools/rongcloud-user-cleaner ./tools/docs/localize_openapi_tags
2. staticcheck 只跑 U1000（未导出符号未使用），过滤测试文件：
   GOMODCACHE=/tmp/gomodcache GOCACHE=/tmp/gocache staticcheck -checks U1000 ./... | grep -v _test.go
3. 两份结果交叉：deadcode 独有的命中多为"导出但不可达"（重点查遗留入口/测试专用 API）；
   U1000 独有的命中多为包内私有残留。每个命中必须打开文件并 grep 生产/CLI/测试三类调用方后才能定性，
   工具输出本身不是证据。

Dead Code：
- 未导出且同包内从未被调用的函数；永不命中的分支；只写不读的字段
- 已删除功能遗留的配置、常量、SQL、Redis key、callback handler
- 排除：main/init、接口实现方法、反射、RPC/HTTP/CLI 注册、框架 hook、生成代码
- 不要仅凭 grep 不到调用就判定 exported 符号为 dead code，必须列出已检查过哪些注册点

重复逻辑（业务重复，不是模板代码）：
- 权限判断、状态流转判断、金额/热度计算在多处各写一遍
- Redis key 拼接、callback 签名校验、错误码映射重复
- HTTP 与 WS payload 转换、字段映射重复
- 重点报告"两处已经发生差异"的重复——差异即潜在 bug

低价值抽象与测试污染：
- interface 只有一个生产实现且不对应真实运行时边界（存储/RPC/Redis/第三方除外）
- 函数纯转发、wrapper 纯透传、每层无实质职责的过度分层
- function field 注入 fake、仅测试使用的可选参数/构造器、为测试方便的生产 nil guard
- 生产代码出现 test/mock/fake/stub 命名

每个发现说明：位置、判定依据（dead code 要列已排查的注册点；重复要给出各处差异；抽象要说明为何无运行时边界价值）、维护成本、移除或合并方案。
```
