---
name: audit
description: 运行当前仓库 .local/review 下的质量审计/评审提示词（自动拼接 _base 或走独立模式）。当用户要求做代码质量审计、按主题评审、架构评审、变更评审、过度实现评审或入口梳理，且当前仓库存在 .local/review/ 目录时使用。
---

# Audit

你是当前仓库 `.local/review/` 审计提示词库的执行入口。参数为用户在调用本 skill 时给出的内容（形如 `<主题|arch [A-D]|change|over|entry> [限定路径]`）。

执行规则：

1. **无参数**：读 `.local/review/README.md` 的文件索引、推荐执行顺序和运行记录表，只展示可用项与建议，不执行任何审计。
   - 输出必须优先可读性，使用 Markdown 表格，不把多个主题挤在同一段。
   - 先输出“主题（按优先级）”表，列为：`主题`、`用途`、`最近运行`。`主题` 和 `用途` 来自文件索引；`最近运行` 必须从运行记录表合并，格式优先用 `MM-DD (P0/P1/P2/P3)`，未跑写 `未跑`，复杂备注可压缩为简短状态（如 `06-15 多轮`）。
   - 再输出“独立模式”表，列为：`模式`、`用途`、`最近运行`。独立模式包括 README 中列出的 `mode-*`，命令名使用别名（如 `change`、`over`、`entry`、`arch [A-D]`）。
   - 最后结合近期 git 改动和运行记录，输出 1-2 个建议先跑的主题或模式，用表格列出：`优先级`、`命令`、`原因`。若当前工作区有未提交改动，优先考虑 `change` 或与改动路径最相关的主题。

2. **参数解析**：
   - 先读 `.local/review/README.md` 的文件索引，以 README 中列出的顶层主题和独立模式为准。
   - 第一个参数匹配提示词，其余参数按下述规则处理。
   - 支持不带 `.md` 的模糊匹配（如 `money` -> `money-settlement.md`，`atomicity` -> `consistency-atomicity.md`）。只匹配 `.local/review/` 顶层文件和 README 索引，不递归 `archive-v1/`。命中多个候选时列出让用户选，不要猜。
   - 别名：`arch` / `architecture` -> `mode-architecture-review.md`；`change` -> `mode-change-review.md`；`over` / `over-implementation` -> `mode-over-implementation.md`；`entry` / `entry-map` -> `mode-entry-map.md`。

3. **执行方式按文件类型分流**：
   - 普通主题文件：拼接 `_base.md` + 主题文件作为本次审计指令执行。若剩余参数是路径（如 `apps/app-service/`），在主题前加一行“只扫描 <路径>”。
   - `mode-*` 独立模式：不拼接 `_base.md`，直接按该文件全文执行。
   - `mode-architecture-review.md` 额外规则：剩余参数若为 A/B/C/D，作为本次指定评审维度传入；该模式涉及读写 `.local/review/arch-reports/` 下的账本与报告，严格按文件内的流程与落盘约定执行。

4. **纪律**：
   - 严格遵守所选提示词文件的输出格式与约束，不自行增删章节、不掺入文件外的评审标准。
   - 一次只跑一个主题；用户同时给了多个主题时按顺序逐个跑，各自独立输出。
   - 若当前会话已有大量与审计无关的上下文，先提醒用户“建议新开干净会话跑审计”，经确认后再继续。

5. **收尾**：审计完成后更新 `.local/review/README.md` 的运行记录表：填写日期、P0/P1/P2/P3 计数；若执行中发现提示词本身的问题（误报多、起点失效、规则被无视），在备注列记一笔，并提示用户是否回改该提示词文件。

维护提醒：这个 Codex skill 是全局入口薄封装；真实审计内容以当前仓库 `.local/review/` 为准。若同步修改 `.claude/commands/audit.md` 的入口规则，也要同步检查本文件。
