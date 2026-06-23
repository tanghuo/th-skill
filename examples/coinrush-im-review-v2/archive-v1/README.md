# 后期质量审计提示词

> 原始完整版：`docs/archive/review.md`  
> 本目录是精简重组版，每个文件可直接拼接使用。

## 使用方式

每次审计 = `_base.md` + 一个主题文件，拼接后喂给 Codex `/goal`。
Claude Code 下可直接用 `/audit <主题>` 执行（自动拼接 `_base` / 识别独立模式），如 `/audit money`、`/audit arch A`、`/audit bug-concurrency apps/app-service/`。

- 一次只跑一个主题
- 拼接后总长度控制在 800-1200 字
- 如果需要限定范围，在主题前加一行：`只扫描 apps/app-service/`

变更 Review、入口识别、架构师评审是独立模式，不需要拼接 `_base.md`。

## 文件索引

### 基础

| 文件 | 用途 |
|---|---|
| `_base.md` | 审计基础：严重度 + 输出格式 + 误报过滤（每次必拼） |

### Bug 类

| 文件 | 用途 |
|---|---|
| `bug-concurrency.md` | 并发 & 数据竞争 |
| `bug-resource-leak.md` | 资源泄漏 |
| `bug-error-swallow.md` | 错误处理黑洞 |
| `bug-nil-boundary.md` | 边界条件 & nil |

### 状态一致性

| 文件 | 用途 |
|---|---|
| `consistency-atomicity.md` | 事务边界 + 幂等 + 异步重试（合并 3 个原主题） |
| `consistency-state-machine.md` | 业务状态机 + 不变量（合并 2 个原主题） |
| `consistency-mysql-redis-drift.md` | MySQL / Redis 状态漂移 |
| `money-precision.md` | 金额精度 + 溢出 + 超扣（礼物/结算/余额专项） |

### 实时消息

| 文件 | 用途 |
|---|---|
| `realtime-messaging.md` | 长连接生命周期 + 投递语义 + 在线状态（IM/语音房专项） |

### 安全

| 文件 | 用途 |
|---|---|
| `security-credential-leak.md` | 敏感信息泄漏 |
| `security-authz.md` | 鉴权 + 对象权限 + 租户隔离（合并 2 个原主题） |
| `security-rate-limit.md` | 限流、背压与资源耗尽 |

### 契约

| 文件 | 用途 |
|---|---|
| `contract-api-drift.md` | 文档 / API / 代码漂移 |
| `contract-field-semantics.md` | 字段单位、语义 + 时间/时区/TTL（合并 2 个原主题） |
| `contract-schema-alignment.md` | Schema / Model / Query 对齐 |

### 性能

| 文件 | 用途 |
|---|---|
| `perf-capacity.md` | 性能退化 + SQL / 索引（合并 2 个原主题） |
| `perf-timeout-retry.md` | context / 超时 / 重试 / 外部依赖韧性（合并 2 个原主题） |

### 技术债

| 文件 | 用途 |
|---|---|
| `debt-dead-code.md` | Dead Code |
| `debt-duplication.md` | 重复逻辑 |
| `debt-abstraction.md` | 薄封装 + 单实现接口 + 测试污染（合并 2 个原主题） |

### 发布 & 运维

| 文件 | 用途 |
|---|---|
| `ops-tools-scripts.md` | 运维工具 + 脚本 + 启动顺序（合并 2 个原主题） |
| `release-compat.md` | 发布兼容性 & Schema 迁移 |

### 低频

| 文件 | 用途 |
|---|---|
| `observability.md` | 可观测性缺口 |
| `test-effectiveness.md` | 测试有效性 |
| `compliance-privacy.md` | 隐私 + 合规 + 依赖安全（合并 2 个原主题） |

### 独立模式

| 文件 | 用途 |
|---|---|
| `mode-change-review.md` | 变更 Review（PR / diff 增量审计，自带完整格式） |
| `mode-entry-map.md` | 高风险入口识别（审计前跑一轮，产出审计地图） |
| `mode-architecture-review.md` | 架构师视角评审（定期模式：账本 `arch-reports/_ledger.md` 跨期维护，报告按日期落盘，证据驱动轮换维度） |

## 推荐执行顺序

### 时间有限（Top 5）

1. `consistency-atomicity.md` — 事务 + 幂等 + 半成功
2. `money-precision.md` — 金额精度 + 溢出 + 超扣（资损优先）
3. `consistency-state-machine.md` — 状态机 + 不变量
4. `realtime-messaging.md` — 长连接 + 投递语义（IM 核心）
5. `security-authz.md` — 鉴权 + 权限

### 首次全面审计

**第一步**：跑 `mode-entry-map.md` 产出审计地图

**第二步（高风险）**：
1. `security-credential-leak.md`
2. `security-authz.md`
3. `consistency-atomicity.md`
4. `money-precision.md`
5. `consistency-mysql-redis-drift.md`
6. `realtime-messaging.md`
7. `bug-resource-leak.md`
8. `bug-nil-boundary.md`

**第三步（数据和契约）**：
1. `contract-api-drift.md`
2. `contract-field-semantics.md`
3. `contract-schema-alignment.md`
4. `consistency-state-machine.md`

**第四步（性能和技术债）**：
1. `perf-capacity.md`
2. `perf-timeout-retry.md`
3. `debt-dead-code.md`
4. `debt-duplication.md`
5. `debt-abstraction.md`

**第五步（按需）**：
1. `release-compat.md`
2. `ops-tools-scripts.md`
3. `compliance-privacy.md`
4. `observability.md`
5. `test-effectiveness.md`

### 日常 PR Review

直接使用 `mode-change-review.md`，可选追加一个主题文件深挖特定方向。

### 发布前

依次跑：`release-compat.md` → `ops-tools-scripts.md` → `security-credential-leak.md` → `perf-timeout-retry.md`

## 与原始版本的对应关系

| 原始章节 | 精简版文件 | 变化 |
|---|---|---|
| 一~四（母提示词/严重度/格式/误报） | `_base.md` | 合并为一份 |
| 五.1 并发 | `bug-concurrency.md` | 保留 |
| 五.2 资源泄漏 | `bug-resource-leak.md` | 保留 |
| 五.3 错误处理 | `bug-error-swallow.md` | 保留 |
| 五.4 边界条件 | `bug-nil-boundary.md` | 保留 |
| 六.1 Dead Code | `debt-dead-code.md` | 保留 |
| 六.2 重复逻辑 | `debt-duplication.md` | 保留 |
| 六.3 薄封装 + 六.4 测试污染 | `debt-abstraction.md` | **合并** |
| 七.1 API 漂移 | `contract-api-drift.md` | 保留 |
| 七.2 字段语义 + 十.1 时间/时区 | `contract-field-semantics.md` | **合并** |
| 七.3 Schema 对齐 | `contract-schema-alignment.md` | 保留 |
| 八.1 敏感信息 | `security-credential-leak.md` | 保留 |
| 八.2 鉴权 + 八.3 对象权限 | `security-authz.md` | **合并** |
| 八.4 限流/背压 | `security-rate-limit.md` | 保留 |
| 九.1 MySQL/Redis 漂移 | `consistency-mysql-redis-drift.md` | 保留 |
| 九.2 幂等 + 九.3 事务 + 九.4 异步任务 | `consistency-atomicity.md` | **合并** |
| 九.5 状态机 + 九.6 不变量 | `consistency-state-machine.md` | **合并** |
| 十一.1 性能 + 十一.2 SQL/索引 | `perf-capacity.md` | **合并** |
| 十二.1 context + 十二.2 外部依赖 | `perf-timeout-retry.md` | **合并** |
| 十二.3 启动顺序 + 十三.1 工具脚本 | `ops-tools-scripts.md` | **合并** |
| 十四 发布兼容性 | `release-compat.md` | 保留 |
| 十五 可观测性 | `observability.md` | 保留 |
| 十六 测试有效性 | `test-effectiveness.md` | 保留 |
| 十七 隐私 + 十八 依赖安全 | `compliance-privacy.md` | **合并** |
| 十九 变更 Review | `mode-change-review.md` | 保留 |
| 二十 入口识别 | `mode-entry-map.md` | 保留 |
| （无原始章节） | `realtime-messaging.md` | **新增**：IM/语音房长连接与投递语义 |
| （无原始章节） | `money-precision.md` | **新增**：金额精度/溢出/超扣专项 |
| 二十一~二十五（执行顺序/组合用法） | `README.md`（本文件） | 整合 |
| 二十二 grep 方向 | 删除 | 给人看的索引，不喂给模型 |
| 二十三 最终统一后缀 | 合入 `_base.md` | 不再单独维护 |
