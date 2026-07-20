# commands/ —— gh-issue-summarizer 的命令入口

> 本目录是 SOP §"流水线骨架 + 红线系统"的项目级落地。
>
> **为什么有这个目录**：AGENTS.md / spec.md / red_lines.yaml / prompts/README 引用的命令（`make doctor` / `make test` / `sha256sum -c` 等）必须有真实入口文件存在，否则 = 文档引用了不存在的命令 = AI 一跑就崩。

## 文件清单

| 文件 | 状态 | 用途 |
|---|---|---|
| `Makefile` | **生效中** | 8 个 target 的命令定义 |
| `README.md` | **生效中** | 本文件 |
| `scripts/run-once-dry.sh` | demo 级 | 干跑脚本示例（演示"什么是 dry-run"） |

## target 速查

| target | 何时用 | 引用方 | 退出码失败时 |
|---|---|---|---|
| `make doctor` | 接新会话 / commit 前 / 任何运行时问题前 | AGENTS.md §1/§5, spec.md §0 | exit 1 |
| `make test` | 任何代码改动后 | red_lines.yaml RL-15, .agent-rules §ci_hooks | exit 1 |
| `make test-strict` | pre-push（CI） | .agent-rules §ci_hooks.pre_push | exit 1 |
| `make build` | pre-commit / 发布前 | red_lines.yaml RL-15 | exit 1 |
| `make validate-config` | 任何 configs/*.yaml 改动后 | red_lines.yaml RL-60, task-001 阶段 1 | exit 1 |
| `make verify-prompts` | prompt 升版本后 / commit 前 | prompts/README.md 升版本流程 | exit 1 |
| `make lint-config` | pre-commit | .agent-rules §ci_hooks.pre_commit | warn 跳过（无 yamllint 不报错） |
| `make run-once-dry` | pre-push（CI） | .agent-rules §ci_hooks.pre_push | exit 1 |
| `make clean` | 维护用 | — | FORCE=yes 保护 |
| `make help` | （默认）显示本表 | — | — |

## 设计原则（本 Makefile 体现的）

| 原则 | 实现 |
|---|---|
| **target 名 = 文档里引用的命令** | 不写 `make check`，写 `make doctor` —— 文档引用 1:1 命中 |
| **退出码严格传递** | `.SHELLFLAGS := -eu -o pipefail -c` 让 bash 失败立刻停 |
| **危险命令要确认** | `make clean` 必须 `FORCE=yes`（spec §"反向护栏"落地） |
| **缺工具不假装通过** | `yamllint` 没装 → warn 但 exit 0 + 提示安装方法（不是 fail 也不是假装） |
| **demo 级项目能跑就不错了** | `go.mod` 不存在时打印 ⚠️ skip，不强行 exit 1 —— 让 examples 仓库也能 `make help` 跑通 |
| **不破坏 SOP 强约束** | `make verify-prompts` 真的调 `sha256sum -c`，跟 prompts/README.md 写的命令完全一致 |

## 为什么 demo 级不真能跑

本仓库是**教学示例**，不是真项目。所以：

| target | 真实项目里的样子 | 本 demo 里 |
|---|---|---|
| `make doctor` | 真调 3 个 API 探测端点 | 仅检查 env vars + yaml schema |
| `make test` / `make build` | 跑 `go test ./...` / `go build` | 检测 `go.mod` 存在则跑，否则 ⚠️ skip |
| `make run-once-dry` | 调 main.go 加 `--dry-run` flag | 仅打印"真实项目里应该这样" |
| `make validate-config` | 真调 `cmd/config-validator/main.go` | 检测文件存在则跑，否则 ⚠️ skip |

**给读者的真心建议**：把 `examples/gh-issue-summarizer/` 当模板拷走你的项目时，必须：

1. 删除 demo 级 `if [ -f ... ]` 分支的 demo 友好行为
2. 实现真实 Go 代码（cmd/gh-issue-summarizer/main.go 等）
3. 替换 `make doctor` 里的"示意代码"为真 API 探测调用
4. 写 1 个 `cmd/config-validator/main.go` 用于 `make validate-config` 真跑

否则 `make doctor` 永远显示 "demo 级"，不会真验证 3 个 API 联通。

## commands/ 跟其他文件的关系

```
文档层：
  AGENTS.md §1/§5 ───────→ make doctor + make test
  spec.md §0 入场自检 ────→ make doctor
  spec.md §3 不变式 ─────→ make test / make build
  red_lines.yaml RL-15 ──→ make test
  red_lines.yaml RL-60 ──→ make validate-config
  red_lines.yaml RL-50 ──→ go run ./cmd/summarizer (在 task-001 阶段 4)
  prompts/README.md ─────→ make verify-prompts
  .agent-rules §ci_hooks → 全部 8 个 target

实现层：
  commands/Makefile ────→ 8 个 target 的实际定义
  commands/scripts/ ──────→ run-once-dry.sh 等具体脚本
 内部 Go 代码 ──────────→ main.go + _test.go + cmd/config-validator/main.go
              ↑
              └── 本 demo 没有，是真项目需要补的
```

## 维护说明

1. **新增 target** → 在本 README 的"target 速查"表加一行 + 在被引用文档里加 cross-ref
2. **删除/重命名 target** → 先 grep `make <name>` 所有引用方，按需更新文档
3. **修改 .SHELLFLAGS** → 影响所有 target，仔细 review；推荐别动
4. **加 .PHONY** → 不要漏，否则同名文件会让 make 误判"已 up-to-date"

## 配套文件

- Makefile（8 个 target）
- `scripts/run-once-dry.sh`（演示 dry-run 流程）
- SOP 主文档：`../../README.md`

---

# === 本 README + Makefile 示例特意展示的 4 件事 ===
# 1. 8 个 target 闭合了 7 处文档引用 —— 这是 commands/ 的核心价值（断链修复）
# 2. demo 友好行为（"go.mod 不存在则 ⚠️ skip"）让 examples 仓库自身能 `make help` 通过，但不假装真项目 —— 明确告诉读者"拷走后要改"
# 3. `make clean FORCE=yes` 是反向护栏的 Makefile 落地 —— spec §"反向护栏" → Makefile 安全约束
# 4. `make help` 默认 target + 自描述 help 输出 —— 不依赖 `make -n` 这种低信号操作
