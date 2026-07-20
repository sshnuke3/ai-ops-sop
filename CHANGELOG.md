# Changelog

> 本文件按 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 格式维护。
> 版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)——但本仓库**当前处于 0.x 版**，按 SemVer 约定 = "仍在开发，可能会有不向后兼容的变更"。

## [Unreleased]

### Planned

- `prompts/summary_v1.txt`：v1 历史版本反例补全（与 v2 反例配对）
- 真能跑的 examples —— 引入 mock server 让 `make doctor` / `make run-once-dry` 在没有真实凭证情况下也能跑通
- CONTRIBUTING.md：贡献指南（如何提 PR、如何报 issue）

## [0.8.0] - 2026-07-21

### Added

- 主 README 加“🤖 多 Agent 进阶” 段（单 Agent → 多 Agent 场景跳转）
  - 3 资源指针：bojieli/ai-agent-book ch10 · claude-code-subagents · langgraph
  - 各资源“起点门槛”列（读完本 SOP 哪些节才能跳）
  - “本 SOP 适用部分” 清单（§1 交接 / §2 知识地图 / §4 红线 / §5 验证 / §6 记忆）
  - “不适用部分” 清单（§7 HK / §8 原则）
  - 明确本 SOP 不提供多 Agent 完整 SOP · 立项门槛 3+ 失败样本 · demo 启动中
- 1 处脱敏修复：“待项目维护者沉淀”（个人化表述 0 命中）

### Notes

- 本版本是 v0.7.0 的下一步补充，单 Agent → 多 Agent 场景的衔接

## [0.7.0] - 2026-07-21

### Added

- 主 README 加“📚 延伸阅读” 段 · 指向 bojieli/ai-agent-book · 列出与本 SOP 对应的 4 章映射
  - 互补关系明确：“本 SOP 教怎么跑，《深入理解 AI Agent》 教为什么这样跑”
  - 4 章映射表：
    - ch2 上下文工程 ↔ §3 五步定位法 + `load_policy.on_stage_enter`
    - ch6 Agent 评估 ↔ §5 验证双闸门
    - ch7 模型后训练 ↔ §7 红线 + §5 验证是为项目补 Harness 不是补模型
    - ch8 自我进化 ↔ §8 沉淀 + §10 “今天 3 件事”

### Notes

- 背景：2026-07-21 读了《深入理解 AI Agent》 后追加

## [0.5.0] - 2026-07-21

### Added

- `examples/gh-issue-summarizer/commands/`：闭合文档-命令断链
  - `Makefile`：8 个 target（`doctor` / `test` / `build` / `validate-config` / `verify-prompts` / `lint-config` / `run-once-dry` / `clean` / `help`）
  - `scripts/run-once-dry.sh`：6 阶段真实可跑 dry-run 脚本（`bash run-once-dry.sh` exit 0 验证通过）
  - `README.md`：target 速查 + 设计原则
- `examples/gh-issue-summarizer/.gitignore`：项目级忽略（`runs/*-dry/` 等演示产物不跟 git）
- 5 处跨文件引用同步：AGENTS.md / spec.md / red_lines.yaml / .agent-rules / examples README 目录树
- `LICENSE`：MIT 协议（带作者署名要求建议）

## [0.4.0] - 2026-07-21

### Added

- `examples/gh-issue-summarizer/AGENTS.md`：AI 接力起点（8 节 · 5 件必做 · 7 条反向护栏 · 4 条 HK）
- `examples/gh-issue-summarizer/PROJECT_WIKI/.agent-rules`：OpenClaw 风格机器读规则补充
  - 路由规则 · 上下文预算 · 接力信号 · CI hook
- commit message 强约束："X/Y tests pass" 必须 `_test.go` 真存在

### Changed

- AGENTS.md §1：5 件必做 → 6 件（含 `make doctor`）
  # 注：v0.5 才真有 doctor 命令，v0.4 时是断链 — v0.5 commit 已修复

## [0.3.0] - 2026-07-21

### Added

- `examples/gh-issue-summarizer/prompts/`：实物 LLM prompt 资产
  - `summary_v3.txt`：当前主用 prompt（system + user 双段 · 6 条硬约束 · JSON 输出）
  - `summary_v3.txt.sha256`：hash sidecar（`6f489bab...` 真算真锁）
  - `summary_v2.txt`：DEP-N 弃用反例
  - `README.md`：版本管理规则 + 5 件套清单 + 升版本流程示例
- `docs/spec.md §4`：补 ITER-2.5（prompt v2 → v3）+ DEP-1（v2 弃用）

### Discovered

- **hash 自循环真坑**：在 prompt 正文里写 `# SHA256: abc...` 会因"写 hash 这一行"而改变 hash——sidecar 文件才是稳定锁

## [0.2.0] - 2026-07-21

### Added

- `examples/gh-issue-summarizer/`：1 个跨 3 工具完整示例项目（GitHub REST + LLM + Notion）
- 6 个产物文件（README + overview + spec + red_lines.yaml + task-001 + timeline.txt）
- 3 个 configs.example（repos / llm / notion）
- 主 README 加 examples 入口 + 路由表

### Changed

- 主 README 仓库结构示意更新
- 「你现在想要」导航表加 examples 列

## [0.1.0] - 2026-07-21

### Added

- `README.md`：AI 长任务协作 SOP 主文档（11 节 + 30 分钟抄走小节）
- `templates/`：6 份空白模板
  - `task-output-spec.md` · `overview.md` · `failure-triage.md`
  - `red_lines.yaml` · `tech-spec.md` · `hard-checkpoints.md`
- `.gitignore`

---

# === 维护说明 ===
# 1. 每次 commit 必增一行到 [Unreleased] 段（即使是 chore）
# 2. 触发大版本号变更（v0.x → v0.{x+1}.0）必须显式列"Added / Changed / Removed"
# 3. 升级 v1.0.0 时加一段 [1.0.0 - YYYY-MM-DD] 显式标"API 稳定"
# 4. 不要删历史版本项——保留作演进可追溯

# === 类型枚举 ===
# - **Added** 新功能
# - **Changed** 已有功能的变更
# - **Deprecated** 即将移除的功能
# - **Removed** 已移除的功能
# - **Fixed** Bug 修复
# - **Security** 安全修复

# === 版本节奏（参考）===
# v0.x → v1.0：内部迭代 + 反复打磨，**不承诺 API 稳定**
# v1.0 → v1.x：增量功能 + bug 修复，承诺向后兼容
# v1.x → v2.0：API 路径大改 / 架构调整 / 上下游断裂
