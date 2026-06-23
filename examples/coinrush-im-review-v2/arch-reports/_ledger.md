# 架构评审账本

> 唯一跨期事实源。每次架构评审就地更新本文件；当次发现写入同目录 `YYYY-MM-DD.md` 报告。

## 项目地图基线（最近确认：2026-06-16）

- 顶层模块：`apps/gateway`（HTTP/WS ingress、鉴权、协议封包、dispatch fanout——默认 per-node Redis pub/sub，新增 durable Stream 旁路默认休眠）+ `apps/app-service`（全部业务 + 后台 job）；共享 `internal/*`（xerr/bizcode/idempotency/rpcauth/protocol/config/redisstore 等横切，redisstore 含 dispatch_publisher/dispatch_stream/node_registry/registry）；`pkg/` 已删除（2026-06-10 行动项 B3 落地）。
- app-service 分层：`logic`（gRPC 适配薄层）→ `application`（feature 用例包）→ `domain`（状态机/规则）→ `store`（mysqlstore + appredisstore + externaluserstore）；另有 `roomactor`（内存 actor + Redis owner lease）、`roomstate`、`job`；外呼集中在 `client/`（agora/peer/rongcloud/internalapi）；dispatch 发布经新目录 `adapter/gateway` + `signaldispatch`；另有 `metrics/`(appmetrics)、`ratelimit/`、`config/`、`buildinfo/`。cmd 含 seed-anchor/run-anchor-analytics/run-settlement/bootstrap-anchor-guild-bindings。
- 进程模型：两个二进制。app-service 单进程内跑 gRPC server + 15 个进程内 ticker（main.go:38-55）；3 个 MQ consumer 已预写未注册（等交换机/队列就绪）。
- 调度与依赖：MySQL 5.7（事实源）+ Redis（房态投影/presence/owner lease/分布式锁/pub-sub）；外部依赖融云 IM、Agora、用户中心 RPC。15 个 ticker 中 6 个有分布式锁。
- 部署规模：gateway × 1、app-service × 1（2026-06-10 用户口头确认）。2026-06-10 报告中 A1/A2/C1 的"维持现状"结论以此为前提，前提已坐实。
- 团队与观测：开发 1 人（后期最多 +1，可能性低）；无 metrics 看板——`appmetrics` 已埋点（job 时长/panic 等）但无人监控，线上异常靠日志与用户反馈感知（2026-06-10 用户口头确认）。

## 北极星（建立：2026-06-10）

1. 双进程拓扑维持：gateway（ingress/fanout）+ app-service（业务+job），不拆微服务。【假设：单团队、核心表共库强一致（送礼/结算/房态）、无独立扩容需求】
2. app-service 内部收敛为 logic(薄适配) → application(按 feature 用例包) → domain(规则) → store(持久化)；新功能业务逻辑一律落 application。【假设：room-core 迁移渐进可负担，不停下功能开发】
   - 6. `service/` 为领域服务层：无状态机制助手（gift combo/lucky/banner/resource_url 等，被多路径复用）长期留此；其中残留的 action 生命周期编排（service/gift/service.go 主送礼路径）定性为待迁移 legacy，新 gift/送礼编排一律落 application/gift。【假设：gift 双轨合并与 room-core 同属可缓迁 backlog】
3. 房间/在线状态拓扑：MySQL 事实源 + Redis 投影 + roomactor 串行化 + 对账 job 收敛漂移；gateway fanout 已预置 durable Stream 旁路（节点注册+心跳常驻），默认休眠走 pub/sub，多 gateway 时启用，app-service 仍单实例。【假设：app-service 单实例或极低实例数】
4. job 形态：进程内 ticker + 分布式锁/幂等，不引入外部调度器或 MQ 调度。【假设：job 量级与时延容忍度不需要分布式调度】
5. 横切关注点（错误码/鉴权/幂等/RPC auth/协议）收口在根 `internal/*`。【假设：共享方只有 gateway 与 app-service 两个 runtime】

## 决策账本（活跃条目）

| 决策项 | 当前结论 | 依据(强度) | 触发再评估信号(可观测，数据来源) | 最近复核 |
|---|---|---|---|---|
| app-service 拆不拆 | 不拆，只整理内部模块（1 人团队 + 共库强一致，拆分无任何收益侧） | 送礼/结算/房态共库且事务强一致；单 main.go 单进程，无独立扩容诉求（强：apps/app-service/main.go）；团队 1 人（用户确认） | ① 某业务域需独立扩容/部署（部署变更时用户自报）；② 在线接口因结算 job 出现可感知变慢（用户/客户端反馈，无看板）；③ 团队扩到 ≥3 人 | 2026-06-16（维持，无信号） |
| logic→application 迁移 | 渐进迁移；新功能必须落 application；room-core（process_signal_*、checkrongmessagecallback）迁移是已认账 backlog，不混入日常 | 新功能落点合规（强：grep -l 'application/' 统计）。2026-06-16 已把内部落位规则（logic 薄适配/新功能落 application/service 层定位）写入 CLAUDE.md Runtime And Layer Boundaries——D1"落位规则未沉淀"已了结 | ① logic 目录 fix-commit 密度连续两期居首（git log --grep='^fix'）；② 新增 logic 文件出现不委托 application 的业务实现 | 2026-06-16（维持；本期 logic fix 密度降至 #4，信号未触发） |
| job 调度形态 | 维持进程内 ticker | 单实例部署下够用；钱相关管线已有锁+幂等（强：main.go；6/15 job 含 AcquireLock）；本期补 per-round deadline（ticker.go:126-135 RunTimeout 默认 1min）关闭"单轮挂住停调度"失败模式 | ① app-service 多实例部署立项 → 全量 job 锁/幂等审计；② 结算 job 单轮耗时接近 1min 默认 RunTimeout（ticker.go:104 durationMs 日志可读）→ 给结算类 job 设更大 per-job RunTimeout | 2026-06-16（维持；本期 job fix 密度 #1 但全为业务口径/重构，非调度形态；C 维度复核 deadline 加固） |
| roomactor 跨实例策略 | 维持 takeover 模型；AdvertiseAddr 预留不实现转发 | 非本地 owner 时直接抢所有权而非转发（强：logic/process_signal_router.go:34）；单实例下无影响 | app-service 多实例部署立项（用户自报；届时无看板，需临时抓取 takeover 指标或加日志评估） | 2026-06-16（维持，未触发；Stream 链路属 gateway fanout 侧，与此条不同层） |
| service/ 层定位 + gift 编排双轨 | 已定性（2026-06-16 用户裁决）：service/ = 领域服务层，无状态机制留此；service/gift/service.go 编排为待迁移 legacy，新 gift 编排落 application/gift。北极星 #6 + CLAUDE.md 已落字 | gift 编排分裂：主送礼在 service/gift/service.go(420)、私聊在 application/gift(480)，互不调用、分别被不同 logic 入口用；无状态机制(combo/lucky/banner，无 store 依赖)合法属 service/；北极星 4 层不含 service/（强：grep 导入 + 文件分工） | ① 新 gift/送礼功能编排落进 service/ 而非 application/（grep 新 logic 入口指向）；② service/{display,im,roomshare} 经核对也出现与 application 重叠 | 2026-06-16 |
| Dispatch 传输形态 | 默认 pubsub，Stream 链路休眠（shadow/stream 仅配置可启） | 单实例下 pub/sub 够用；Stream durable+节点注册已建成且单实例有显式失败价值——ActiveNodes 空返回 ErrNoActiveDispatchNodes（强：dispatch_publisher.go:61-66、config.go:142,146）；C 维度：失败模式逐项已处理（approx maxlen=10000 裁剪、XAutoClaim 恢复 PEL、requestId 去重、replay-age 30s display guard，dispatch_stream.go） | ① 多 gateway 实例立项 → 启 shadow 测量投递一致性达标后切 stream，并移除 legacy pubsub 分支与 DeleteNodeStream 死代码；② 派发吞吐显著增长/multi-gateway 启用 → 重估 DispatchStreamMaxLen 与 ~5min 回放窗口；③ 3 个休眠 consumer（gameflow/taskreward/firstpaycoupon）激活时默认复用 Redis Stream，避免引入外部 MQ 造双消息技术（用户自报部署变更；shadow 一致性指标无看板，需临时抓取） | 2026-06-16（A 建立；C 维度补失败模式依据+条件） |

## 维度覆盖记录

| 维度 | 最近覆盖 |
|---|---|
| A 运行时与状态 | 2026-06-16（dispatch 拓扑） |
| B 目录与职责 | 2026-06-16（service/ 层定位 + gift 编排双轨） |
| C 选型失败模式 | 2026-06-16（ticker deadline/Redis Stream 派发/消息技术一致性） |
| D 演进与一致性 | 2026-06-16（落位规则/横切超时/not-found 收敛） |

## 待补信息清单

- **dispatch cutover 度量口径与责任人**：rollout 文档已删（99e02a7d 等），shadow 模式下"投递一致性达标"如何度量、由谁拍板切 stream、何时移除 legacy pubsub 分支，仓库内无留痕。影响 Dispatch 传输形态决策条目的触发可执行性——补齐前只能落到占位触发信号（多 gateway 立项），无量化 cutover 门槛。来源：用户/部署决策。
- **结算 job 实际单轮耗时**：未知，直接决定 job 调度形态条目「1min 统一 RunTimeout 对长结算」的严重度——实测远小于 1min 则纯理论风险，接近则需立刻给 per-job RunTimeout。补齐途径：结算 job 已有 ticker.go:104 durationMs 日志，生产跑一轮即读。来源：生产日志（无看板，需手取）。
- **service/{display,im,roomshare} 是否也编排双轨**：B 维度只深挖了 gift（最重），其余三个子包仅确认被引用未逐包核对是否与 application 重叠。影响 service/ 层定性完整性——补齐前「service/ 层定位」条目主要基于 gift 证据。来源：下次 B 维度复核或专项 grep。

## 归档区

- 2026-06-10 待补项"部署实例数"已补齐：gateway × 1、app-service × 1（用户确认），写入地图基线。
- 2026-06-10 待补项"团队规模"已补齐：1 人，后期最多 +1（用户确认）；"拆不拆"条目依据与信号已据此修订。
- 2026-06-10 待补项"metrics 看板"已补齐：无看板，埋点存在但无人监控；涉及指标的触发信号已改写为用户自报/反馈驱动。
