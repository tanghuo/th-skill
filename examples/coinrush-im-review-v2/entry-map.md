# 高风险入口审计地图

> 生成日期：2026-06-10 ｜ 基于 commit：`05cf127f`
> 增量刷新：2026-06-22 ｜ 对照 HEAD：`087c2fb7`
> 下次刷新：对比最近一次刷新基线之后的 git 变化，增量更新新增/删除的入口即可，不必重做。

## 1. 公网 HTTP / WebSocket / Callback 入口（gateway）

路由注册：`apps/gateway/internal/handler/routes.go`；API 定义：`apps/gateway/signal.api`。

### 1.1 无鉴权入口（最高暴露面）

| 路径 | Handler | 触发方式 | 核心状态 | 建议主题 |
|---|---|---|---|---|
| `GET /ws` | `wshandler.go` → `ws/handler.go` `WSHandler` | 客户端 WebSocket 长连接（连接后再认证） | conn registry、presence、房间订阅 | realtime-messaging, concurrency-resource |
| `POST /v1/im/rong/callback/message` | `rongmessagecallbackhandler.go` | 融云服务端回调（query 签名 appKey/nonce/timestamp/signature，app-service 校验签名+时间窗+重放） | `sl_im_msg_ref`、评论热度、回调重放锁 | security-authz, resilience-overload |
| `GET /healthz` `/readyz` | `healthhandler.go` | 探活 | 无 | — |
| `GET /docs/*` | `docshandler.go` | 文档静态页 | 无 | security-exposure |

### 1.2 客户端签名鉴权入口（`/v1` 前缀，auth_middleware）

鉴权：`apps/gateway/internal/handler/auth_middleware.go`（MD5 `action+skey+secret` 客户端签名 + `internal/userauth` 外部用户服务校验）。全部经 RPC 转发 app-service。

| 分组 | 路径 | 核心状态 | 建议主题 |
|---|---|---|---|
| 房间生命周期 | `/room/create` `/room/update` `/room/enter` | `sl_voice_room`（一行=一场直播）、roomstate Redis 快照 | consistency-state, security-authz |
| 房间列表/推荐 | `/room/list` `/room/recommend/list` `/room/anchor/status` `/room/game-option/list` | 房间投影读 | perf-capacity |
| RTC | `/rtc/grant/refresh` | Agora token | security-authz |
| 房管 | `/room/admin/*`（search/invite/accept/list/remove/status-batch） | `sl_voice_room_admin`、`sl_voice_room_admin_invite` 状态机（1待接受…5已过期） | consistency-state, security-authz |
| 主播黑名单/关注 | `/anchor/blacklist/*` `/anchor/follow*` `/anchor/following|follower/*` | `sl_anchor_blacklist`、`sl_anchor_follow` | security-authz |
| 主播资料/相册 | `/anchor/profile/*` `/anchor/album/photo/*` | `sl_anchor_public_profile`、`sl_anchor_album_photo` | security-authz, contract-alignment |
| 房间分享 | `/room/share/private` `/room/share/social` | `sl_room_share`（RoomShareToken 签名）、`sl_room_share_visit` | security-authz |
| IM | `/im/token/refresh` `/im/chatroom/ensure` `/im/private/template/list` | `sl_im_user_token`、融云 chatroom | realtime-messaging |
| 礼物/优惠券 | `/gift/private/submit` `/room/gift/list` `/coupon/list` | `sl_gift_action` 支付状态机、幂等表 | money-settlement, consistency-atomicity |
| 数据中心 | `/anchor/datacenter/*` `/guild/datacenter/*` `/room/data/*` `/room/contribution/rank` | `sl_anchor_earning_daily/monthly`、`sl_guild_owner_income_daily` 等汇总表 | money-settlement, perf-capacity |

### 1.3 内部 HTTP 入口（`/internal` 前缀，internal_auth_middleware）

鉴权：`internal_auth_middleware.go`（per-client Secret + nonce 重放防护，Redis `internal:http:nonce`）。

| 路径 | Handler | 触发方式 | 核心状态 | 建议主题 |
|---|---|---|---|---|
| `POST /internal/room/force-close` | `forcecloseroomhandler.go` | 运营/管理后台 | 房间强制关闭 → 结算入队、礼物清理 | consistency-atomicity, security-authz |
| `POST /internal/notice/official/send` | `officialnoticehandler.go` | 运营后台 | `sl_official_notice` 发送状态 | consistency-state |
| `POST /internal/anchor/guild-binding/change` | `anchorguildbindinghandler.go` | 运营/管理后台 | `sl_anchor_guild_binding_log`、`sl_anchor_profile.guild_id`、主播收益归属口径 | money-settlement, consistency-atomicity, security-authz |

### 1.4 WebSocket 信令命令（连接内二级入口）

定义：`internal/protocol/envelope.go`；路由：`apps/app-service/internal/logic/process_signal_router.go`。

| 命令组 | 事件 | 核心状态 | 建议主题 |
|---|---|---|---|
| system | `system/ping` `system/resume` `system/presence_sync` | resume token、conn registry | realtime-messaging |
| room | `room/join|leave|close|kick|block` | roomstate 快照、presence、成员表 | realtime-messaging, consistency-state |
| room 管理 | `room/admin_*` `room/text_mute|unmute` | 房管/禁言状态，权限走 `domain.canManageTargetUser` | security-authz |
| mic | `mic/*`（apply/take/invite/lock/mute/speaking/...约 20 个） | 麦位状态机（`domain/room_state_mutation.go`） | consistency-state, concurrency-resource |
| gift | `gift/submit` | 礼物支付+连击（`logic/gift_payment.go`、`appredisstore/gift_combo.go`） | money-settlement, consistency-atomicity |
| coupon | `coupon/send` `coupon/claim` | 优惠券+私聊卡片 | consistency-atomicity |
| comment | `room/comment`（trigger） | 评论热度（room heat） | perf-capacity |

## 2. RPC 入口（app-service）

proto：`rpc/proto/signal.proto`（单一 `SignalService`，约 58 个方法）；实现：`apps/app-service/internal/server/signalserviceserver.go` → `internal/logic/*logic.go`。鉴权：`internal/rpcauth` SharedSecret 拦截器（`main.go:67`）。

高风险方法（其余与 HTTP 入口一一对应）：

| RPC | 实现 | 触发方式 | 核心状态 | 建议主题 |
|---|---|---|---|---|
| `ProcessSignal` / `ProcessSignalOnOwner` | `processsignallogic.go` + `process_signal_*.go` | gateway 转发 ws 信令；OnOwner 为跨节点路由到房主节点 | roomactor 串行边界、roomstate | concurrency-resource, realtime-messaging |
| `PublishDispatches` | `publishdispatcheslogic.go` | app-service → gateway 扇出指令 | dispatch 队列（redisstore/dispatch.go） | realtime-messaging |
| `CloseRoom` / `CloseRoomOnOwner` / `AutoCloseEmptyRoomOnOwner` | `closeroomlogic.go` `autocloseemptyroomlogic.go` | 主动关房 / 空房清理 job | 房间 status 1→2、结算入队（`job/roomclose_effects.go`） | consistency-atomicity, money-settlement |
| `GetRoomStateSync` | `getroomstatesynclogic.go` | gateway join/resume 时拉快照 | roomstate Redis | realtime-messaging |
| `CheckRongMessageCallback` | `checkrongmessagecallbacklogic.go` | 融云回调签名/时间窗/重放校验 | 回调重放锁 | security-authz |
| `SendOfficialNotice` | `sendofficialnoticelogic.go` | 内部 HTTP | `sl_official_notice` | consistency-state |
| `SubmitPrivateGiftAction` | `submitprivategiftactionlogic.go` | HTTP 私聊送礼 | `sl_gift_action` + 幂等 + 扣费外呼 | money-settlement |
| `ChangeAnchorGuildBinding` | `anchor_profile_logic.go` | 内部 HTTP 公会绑定调整 | `sl_anchor_guild_binding_log` 区间、`sl_anchor_profile.guild_id` 修复、收益归属回溯口径 | money-settlement, consistency-atomicity |

`*OnOwner` 变体（Update/Accept/Remove/AddBlacklist 等）= 房主节点亲和路由，依赖 `redisstore/room_owner.go` 的 owner lease——跨节点一致性是固有风险点。

## 3. Job / Worker / 定时任务入口

注册：`apps/app-service/main.go:38-54`（`job.Ticker`，间隔常量在 `internal/config`）。全部在 `apps/app-service/internal/job/`。

| Job | 文件 | 触发 | 核心状态 | 建议主题 |
|---|---|---|---|---|
| display dispatch | `displaydispatchjob.go` | ticker | `sl_display_dispatch` 状态机（pending→active→done） | consistency-state |
| flush room state | `flushroomstatejob.go` | ticker | Redis roomstate dirty 分片 → MySQL 投影 | consistency-state（投影漂移） |
| presence heartbeat flush | `presenceheartbeatflushjob.go` | ticker | presence 心跳 ZSet → `sl_voice_room_member_presence` | realtime-messaging |
| presence cleanup | `presencecleanupjob.go` | ticker | 过期 presence 清理（cleanup due/claim key） | concurrency-resource |
| stale presence reconcile | `stalepresencereconcilejob.go` | ticker | MySQL 驱动的幽灵在场对账（项目已知语义：MySQL 是兜底事实源） | consistency-state |
| empty room cleanup | `emptyroomcleanupjob.go` | ticker | 空房自动关闭 → AutoCloseEmptyRoomOnOwner | consistency-atomicity |
| anchor live notice discover / room notice send / cleanup | `roomnoticejobs.go` | ticker | `sl_room_notice` + `sl_room_notice_delivery` fanout 状态 | consistency-state |
| gift stale close | `giftstalejob.go` | ticker | 超时未支付礼物关闭（payment_status→4） | money-settlement |
| gift reconcile | `giftreconcilejob.go` | ticker | 支付中礼物对账（外部钱包状态回查） | money-settlement, consistency-atomicity |
| anchor live settle worker | `anchorlivesettlejob.go` | ticker | `sl_anchor_live_settle_queue` claim → `sl_anchor_live_fragment/daily/session` → 失败进 `sl_anchor_live_settle_dead` | money-settlement |
| anchor revenue boost import | `anchorrevenueboostjob.go` | ticker（RunImmediately） | `sl_anchor_revenue_boost`（status 1有效 2作废） | money-settlement |
| anchor earning pipeline | `anchorearningpipeline.go` | ticker（按业务时区整点对齐 + 分布式锁） | 顺序执行：midnight cut → 游戏收入结算 → daily rebuild → 小时工资 → daily rebuild → 薪资周期 → 会长收入作废 → 会长佣金 → 月汇总 | money-settlement（最高优先） |
| anchor conversion ROI pipeline | `anchorconversionroipipeline.go` | ticker（整点对齐 + 锁） | `sl_anchor_conversion_daily` → `sl_anchor_roi_daily` 重建 | money-settlement, consistency-atomicity |

预接线未启用（未来 MQ 消费者，当前无人调用）：`anchortaskrewardconsumer.go`、`voiceroomgameflowconsumer.go`、`firstpaycouponincomeconsumer.go` → debt-cleanup 关注是否长期闲置。

## 4. Destructive Tools / Scripts

| 入口 | 触发方式 | 危险性 | 建议主题 |
|---|---|---|---|
| `apps/app-service/cmd/run-settlement` | CLI，`-date` 可重跑历史结算（业务时区） | 重写结算数据；重跑幂等是已知雷区（RowsAffected 语义） | money-settlement, release-ops |
| `apps/app-service/cmd/run-anchor-analytics` | CLI，重建转化/ROI 日表 | 重写分析汇总 | money-settlement |
| `apps/app-service/cmd/bootstrap-anchor-guild-bindings` | CLI，给现有主播创建开放公会绑定区间 | 初始化/回填 `sl_anchor_guild_binding_log`；误指生产或重复执行会影响收益归属历史口径 | money-settlement, release-ops |
| `apps/app-service/cmd/seed-anchor` | CLI，播种测试主播数据 | 误指生产 DSN 即污染 | release-ops |
| `scripts/data/run-settlement.sh` / `run-anchor-analytics.sh` / `run-anchor-demo.sh` / `seed-anchor.sh` / `seed-db.sh` | shell 包装上述 CLI + 建库导 schema | 默认 env / DSN 选择错误会重跑或污染真实数据 | release-ops |
| `scripts/dev/up.sh <dev|test|prod>` | docker compose 统一启动入口 | `prod` 分支会用 prod compose / 8080 / latest 镜像，并加载仓库 `apps/*/etc/.env` | release-ops |
| `scripts/release/build-*.sh` `install-amzn2023-package.sh` | 发布构建/安装 | 部署面 | release-ops |
| `scripts/services/restart|start|stop-services.sh` | 服务起停 | 运行时 | release-ops |
| `tools/rongcloud-user-cleaner` | CLI，删除融云侧用户 | 外部系统破坏性删除 | release-ops, security-exposure |
| `tools/rongcloud-system-user-init` | CLI，初始化系统账号 | 外部系统写入 | release-ops |
| `scripts/ci/schema-smoke.sh` `secret-scan.sh` | CI | 只读 | — |

## 5. 核心 MySQL 表与 Redis Key

### 5.1 MySQL（`deploy/mysql/schema.sql`，MySQL 5.7；增量：`deploy/mysql/changesql/`）

资金/结算（最高风险）：
- `sl_gift_action` / `sl_gift_settlement` / `sl_gift_play_result` / `sl_gift_event_log` — 礼物动作与分账；payment_status 1待付/2已付/3失败/4关闭/5支付中
- `sl_anchor_income_ledger`（status 1有效 2冲正）、`sl_anchor_revenue_boost`、`sl_anchor_hourly_payout`
- `sl_anchor_salary_cycle`（1待结算 2已结算 3已重算）、`sl_anchor_salary_base_rule`、`sl_anchor_level`
- `sl_anchor_live_fragment/daily/session` + `sl_anchor_live_settle_queue/dead` — 直播时长结算链（stat_date=结算时区、跨天切割）
- `sl_anchor_earning_daily/monthly`、`sl_guild_owner_income_daily`（eligibility_status: valid/owner_inactive/retro_invalidated）、`sl_guild_commission_tier_config`、`sl_guild`
- `sl_anchor_conversion_daily` / `sl_anchor_roi_daily` / `sl_anchor_action_log`（attribution_status 1成功 2多房间冲突 3无匹配 4人工修正）

房间/IM：
- `sl_voice_room`（一行=一场直播；status 1活跃 2已关闭 3未激活）、`sl_voice_room_member`（online_status 为投影）、`sl_voice_room_member_presence`（settle_status 0/1）
- `sl_voice_room_admin` / `_admin_invite`、`sl_voice_room_text_mute`、`sl_voice_room_event_log`、`sl_voice_room_game_flow`
- `sl_room_notice` / `_delivery`（fanout_status）、`sl_official_notice`（send_status）、`sl_room_share` / `_visit`
- `sl_im_user_token`、`sl_im_msg_ref`、`sl_im_message_template`、`sl_im_private_chat_initiation`、`sl_idempotency_request`
- `sl_anchor_blacklist` / `_follow` / `_public_profile` / `_album_photo` / `_profile` / `_guild_binding_log` / `_level_change_log`
- `sl_display_definition` / `_dispatch` / `_event_log`

### 5.2 Redis（`internal/store/redisstore/`，hash-tag 槽位在 `keyshape.go`；业务键在 `apps/app-service/internal/store/appredisstore/`）

| Key 族 | 文件 | 用途 | 建议主题 |
|---|---|---|---|
| `{conn:*}` connMeta/connRooms、`{user:*}` userConns、`{room:*}` roomNodes、`{resume:*}` | `registry.go` | 连接注册表/扇出路由/断线恢复 | realtime-messaging, concurrency-resource |
| `{room-state:NN}` 分片 + roomState/roomDirty/flushLock | `room_state.go` | 房间状态快照与脏标记 | consistency-state |
| roomOwner lease | `room_owner.go` | 房主节点租约（OnOwner 路由依据） | concurrency-resource |
| presence heartbeat ZSet、cleanup record/due/claim | `registry.go` `presence_cleanup.go` | 在场心跳与清理 | realtime-messaging |
| user active room | `active_room.go` | 用户当前活跃房间 | consistency-state |
| 分布式锁 `lock:*` | `lock.go` | 结算 pipeline、ROI pipeline 互斥 | consistency-atomicity |
| `rong:callback:replay:{...}`、`internal:http:nonce:{...}` | `callback_replay.go` `internal_http_replay.go` | 重放防护 | security-authz |
| gift combo / gift close retry / mic invite | `appredisstore/*.go` | 连击聚合、关单重试、上麦邀请 TTL | money-settlement, consistency-atomicity |

## 6. 核心状态对象与流转路径

| 状态对象 | 位置 | 流转 | 建议主题 |
|---|---|---|---|
| 房间状态机 | `domain/room_state_mutation.go`（纯函数）+ `roomstate/store.go`（Redis 快照）+ `roomactor/actor_manager.go`（按房串行） | 所有 ws 信令经 roomactor 串行应用 mutation → Redis → flush job 投影回 MySQL；`online_status`/`status` 是投影非事实源 | consistency-state, concurrency-resource |
| 房间生命周期 | create（HTTP）→ active → close（ws/HTTP/internal/空房 job）→ `roomclose_effects.go`（结算入队+礼物清理+presence 收尾） | 关房是多副作用扇出点，半成功风险集中 | consistency-atomicity |
| 礼物支付 | `logic/gift_payment.go` → `service/gift` → 外部钱包 `/im/wallet/deduct` | 待支付→支付中→已支付/失败/关闭；stale close + reconcile 两个 job 兜底 | money-settlement |
| 直播结算 | presence settle → `sl_anchor_live_settle_queue` claim（`anchorlivesettlejob.go`）→ fragment/daily → earning pipeline 七步串行 | stat_date 口径、跨天切割、重跑幂等 | money-settlement |
| 权限判定 | `logic/room_access_status.go` `ensureRoomAccessibleForUser`；`domain.canManageTargetUser`（host>admin>member）；HostUserID 而非 CreatorUserID | 对象级越权核心面 | security-authz |
| 房管邀请 | `sl_voice_room_admin_invite` 1待接受→2接受/3拒绝/4撤销/5过期 | ws 与 HTTP 双入口操作同一状态机 | consistency-state |

## 7. 资金/结算/礼物路径 与 权限路径（审计优先级最高）

资金流（写钱的地方）：
1. `gift/submit`（ws）/ `/v1/gift/private/submit`（HTTP）→ `gift_payment.go` 扣费外呼 → `sl_gift_action` → `sl_gift_settlement` 分账 → `sl_anchor_income_ledger`
2. earning pipeline（七步，见 §3）→ daily/monthly/佣金/时薪 → 数据中心只读接口
3. 重跑入口：`cmd/run-settlement -date`、`run-anchor-analytics`（幂等性=资损风险）

权限链：客户端签名（gateway）→ userauth 外呼校验 → JWT claims → RPC SharedSecret → 业务层 `ensureRoomAccessibleForUser` / `canManageTargetUser`。内部链：per-client secret + nonce。回调链：融云签名 + 时间窗 + 重放锁。

## 8. 关键外部依赖、配置与发布入口

| 依赖/配置 | 位置 | 用途 | 建议主题 |
|---|---|---|---|
| 融云 RongCloud | `service/rongcloud/client.go`；`RongCloud.AppKey/AppSecret` | IM 消息/chatroom/回调 | resilience-overload |
| Agora | `service/agora/service.go`；`Agora.*` TokenTTL 1h | RTC token | security-authz |
| 钱包扣费 | `GiftPayment.BaseURL` + `/im/wallet/deduct`（3s 超时） | 资金外呼 | money-settlement, resilience-overload |
| 用户信息 | `UserInfoAPI.*`（30m cache；已知热点：GetUserInfos 串行外呼） | 用户资料 | perf-capacity |
| 用户鉴权 | gateway `UserAuth.BaseURL/Key` | 登录态校验 | security-authz |
| 密钥集 | `JWT.Secret` `RoomShareToken.Secret` `InternalRPCAuth.SharedSecret` `ClientRequestAuth.SecretKey` `InternalHTTPAuth.*` `IMRequestAuth.Key`（均环境变量注入） | — | security-exposure |
| 限流 | `SignalRateLimit`（30/s） | ws 信令限流 | resilience-overload |
| WS XOR | gateway `WS.XORKey=13 HTTPXORKey=15` | 报文混淆（非加密） | security-exposure |
| 业务时区 | `BusinessTimezone`（结算口径根） | stat_date | money-settlement |
| compose 环境 | `deploy/compose-env/{dev,test,prod}.env` | 环境注入 | release-ops |
| migration | `deploy/mysql/changesql/*.sql`（时间戳命名，人工执行） | schema 演进 | release-ops |
| 发布 | `scripts/release/*`、`dist/` | 打包安装 | release-ops |
