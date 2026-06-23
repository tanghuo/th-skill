# 鉴权 & 对象权限 & 租户隔离

> 合并原"鉴权与公网入口"和"对象级权限/租户隔离"。

```text
检查 HTTP / WS / callback / tool / script 入口的鉴权完整性，以及对象级权限校验。

入口鉴权：

- WebSocket signal 是否被公网客户端直接触达
- callback 是否校验签名、时间戳、nonce、防重放
- 只靠前端隐藏或路径命名声明"内部使用"的入口
- debug / admin / health / metrics / pprof 是否暴露敏感信息
- HTTP method 限制、CORS 配置
- 参数是否可导致越权、越界、批量操作

对象级权限：

- 只校验 user_id 存在，没校验 room_id / order_id / task_id 是否属于该用户
- 通过 URL / body / WS payload 传入 user_id 并直接信任
- 管理员、主播、普通用户、内部服务角色权限混用
- 列表接口做了过滤，详情接口没过滤
- WebSocket 连接鉴权后，后续消息没有再次校验对象归属
- 内部 RPC 默认可信，但入口可被外部间接触发
- 多租户 tenant_id / app_id 查询时遗漏

每个发现从真实入口追到最终查询或写入，说明：

- 越权方式或缺失校验
- 影响数据
- 最小复现请求
- 修复方向
```
