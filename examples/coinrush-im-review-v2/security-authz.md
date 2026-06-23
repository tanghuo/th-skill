# 鉴权 & 对象权限

> 入口鉴权完整性 + 对象级越权。敏感信息泄漏看 `security-exposure.md`。

```text
审计 HTTP / WebSocket / callback / 脚本入口的鉴权完整性和对象级权限校验。

起点：
- 入口清单：apps/gateway/signal.api 全量过一遍，对照 handler 实现
- WS 建连鉴权：apps/gateway/internal/ws 与 handler 中的认证路径
- 权限语义基线：房间权限判断应基于 HostUserID（主播）而非 CreatorUserID，未来要区分主播房/工会房——检查现有判断用的是哪个字段

入口鉴权：
- WS 信令是否可被公网客户端直接触达本应内部的操作
- callback 是否校验签名、时间戳、nonce、防重放
- 只靠路径命名或前端隐藏声明"内部使用"的入口
- debug / metrics / pprof 是否暴露；HTTP method 与 CORS 限制

对象级权限：
- 只校验登录身份，没校验 room_id / order_id 是否属于该用户
- 从 URL / body / WS payload 传入 user_id 并直接信任
- 主播、管理员、普通用户、内部服务角色混用；列表接口过滤了但详情接口没过滤
- WS 建连鉴权后，后续每条消息是否还校验对象归属
- 内部 RPC 默认可信，但其入口可被外部间接触发

每个发现从真实入口追到最终查询或写入，说明：越权方式或缺失校验、影响数据、最小复现请求、最小修复方向。
```
