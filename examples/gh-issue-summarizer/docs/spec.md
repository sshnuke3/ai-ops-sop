# gh-issue-summarizer 项目规约

> 创建：2026-07-15
> 最近更新：2026-07-21（a3f8e21 · ITER-3）
> 维护者：<name>

---

## §0 AI 入场自检清单

# === 字段 0：AI 入场自检 ===
# 【填法】5-7 条 checkbox · 顺序读完才算"已接手"。
# 【为什么这样填】下次会话的 AI 一进入就要按这个走——5 分钟读完，避免"我现在在哪"的迷茫。

1. [ ] 读过本文档 §0、§1、§2、§3
2. [ ] 读过 `PROJECT_WIKI/overview.md`（L1 总览）
3. [ ] 跑过 `make doctor`，验证 3 个 API 都可连通
4. [ ] 看过 `runs/timeline.txt` 最近 50 行
5. [ ] 知道当前唯一进行中的任务（"v1.2 加 webhook 触发"）
6. [ ] 已读完 `red_lines.yaml` 中 level=critical 部分
7. [ ] 已确认要做的不是 §1.2 列出的"不做项"

---

## §1 功能边界

# === §1 是越界防线 ===
# 【填法】三段：✅ 做的 / ❌ 不做的 / ⚠️ 待定的。每条都用"主谓宾"句式，越清楚越好。
# 【为什么这样填】新人 / AI 越界的第一道防线——能 grep 出"我现在做的在不在范围"。

### 1.1 ✅ 这一版做（In-Scope）

- **拉指定仓库 issues + comments**：从 `configs/repos.yaml` 读仓库列表（≤ 5 个/周）
- **按讨论热度排序**：comment 数 + 时间衰减（参数见 `configs/ranker.yaml`）
- **LLM 提炼 3 句话中文总结**：prompt 版本 v3，temperature=0
- **写入 Notion 数据库**：结构化字段（issue_id / 仓库 / 标题 / 链接 / 总结 / 状态）
- **每周自动跑一次**：cron 触发，本地时区 Asia/Shanghai 09:00 周一

### 1.2 ❌ 这一版不做（Out-of-Scope）

- **多 GitHub 实例（Enterprise）**：等 v2.0
- **PR / Discussion 拉取**：issue 不够用，PR 留到下一大版本
- **定时之外的手动触发 UI**：本项目以 cron + CLI 为主，不做 UI
- **Slack / 飞书 / 钉钉 推送**：API 凭证未到位 → 等配置到位再做（spec §1.3 不算）

# === §1.2 是越界防御的核心 ===
# 改这里任何一项 → 单独 commit "spec: extend scope" + 在 §4 加 ITER-N 记录。

### 1.3 ⚠️ 待定（PENDING）

- **webhook 触发**（HK-1 已确认设计方向，待 ITER-4 实现）
- **Notion 失败时的本地 fallback 写 .ndjson**（已确认，待 ITER-5 实现）

---

## §2 模块地图

# === §2 是物理结构入口 ===
# 【填法】表格 + 关键调用链。
# 【为什么这样填】AI 改代码前必须在这里"找到目标模块"。

| 模块 | 路径 | 关键公开 API | 依赖 |
|---|---|---|---|
| fetcher | `internal/fetcher/` | `New(token) / Fetch(repo, since)` | go-github/v62 |
| ranker | `internal/ranker/` | `Score(issue) Issues` | 无 |
| summarizer | `internal/summarizer/` | `New(client) / Summarize(issue)` | go-openai |
| writer | `internal/writer/` | `New(client, dbID) / Write(issue, summary)` | notionapi |
| run | `cmd/gh-issue-summarizer/main.go` | `Run() / RunOnce(repos)` | 上述 4 个模块 |

### 关键调用链

```
main.RunOnce(repos) [每个 repo 一遍]
   ├─ fetcher.Fetch(repo, since=7d_ago)
   ├─ ranker.Score(issues)
   │     └─ sort by Score desc (tiebreaker: issue_id 字典序)
   ├─ summarizer.Summarize(top10)
   │     └─ 并发限速: max 2 req/s
   │     └─ 失败 → 落 runs/fallback/<date>.ndjson，继续下一个
   └─ writer.Write(issues)
         └─ 限速: max 2 req/s (golang.org/x/time/rate)
         └─ 失败 → 重试 3 次，backoff 1s/2s/4s
         └─ 最终失败 → 落 runs/fallback/<date>.ndjson
```

---

## §3 不变式（Invariants）

# === §3 是 bug 复发的护身符 ===
# 【填法】3-5 条具体规则 + 附"为什么"。
# 【为什么这样填】同 overview §"关键不变量"，但这里是**项目级永久版本**——更严格更具体。

1. **API token 只走环境变量**
   - 实施：`internal/config/config.go` 用 `os.Getenv()` 而非 `os.ReadFile()`
   - 反例：如果改回读文件 → 立即报 "token 在 disk 上可见" → **REV**
   - 教训：2026-07-18 早期版本曾把 token 误写进 `~/.gh-issue-summarizer/config.yaml`，差点 commit

2. **LLM 输出必须可重放**
   - 实施：`prompts/summary_v{N}.txt` 的 SHA256 入 Notion 数据库字段，重跑时若 hash 变则强制更新 prompt 版本号
   - 教训：2026-07-19 BUG-2 发现换 prompt 后旧 issue 总结被覆盖，但 Notion 里看不出哪版生成

3. **失败不丢数据**
   - 实施：fetcher / summarizer / writer 任一失败，必须把对应 issue 写 `runs/fallback/<date>.ndjson`，**不准静默**
   - 教训：2026-07-20 第一版 fetcher 在 GitHub 限流时直接返回空数组，未告知用户丢了几条

4. **窗口固定为 7 天**
   - 当前版本：`since = now - 7*24h`
   - 改窗口 → 必须先升 spec.md 版本号 + ITER-N

5. **单次运行 ≤ 10 分钟超时**
   - 实施：cron 任务加 `timeout 600`，watchdog 在 `runs/<date>/run.log` 每 60s 写心跳
   - 反例：如果去掉 timeout，GitHub API 假死会让 cron hang 一整夜

### 不要复发的 Bug（BUG-N 索引）

# === BUG-N 设计 ===
# 【填法】每条 ✓ 复发护栏 + 教训 + 时间。
# 【为什么这样填】让"我以前踩过这个坑"在新会话里能 grep 到。

- ❌ **BUG-1（2026-07-19）**：排序在 comment 数相同时随机
  - 教训：所有 Score 函数必须显式定义 tiebreaker
  - 护栏：`ranker_test.go` 3 个 tie 场景必须有断言
- ❌ **BUG-2（2026-07-19）**：LLM prompt 改版后旧数据被覆盖
  - 教训：所有 LLM 输出必须带 prompt hash
  - 护栏：Notion 数据库必填字段 "prompt_version"
- ❌ **BUG-3（2026-07-20）**：GitHub 限流时 fetcher 返回空不报错
  - 教训：分页未到 end 但 page 超限 = 限流信号，必须显式标记
  - 护栏：`fetcher.go` 检测到 `X-RateLimit-Remaining < 5` 必须返回 error
- ❌ **REV-1（2026-07-10）**：go-github v60 → v62，移除 deprecated API
  - 教训：升 major 版本前要写 EOL 检查清单

---

## §4 演进事件

# === §4 是文档的"骨架" ===
# 【填法】时间倒序，最近在最上面。每条 ≤ 3 行：日期 + 类型 + 一句话 + 影响范围。
# 【为什么这样填】让"项目是怎么长成现在这样"可追溯。

```markdown
- 2026-07-21 · ITER-3 · 接入 Notion 推送
  - 原因：单纯落地 markdown 用户读得少
  - 影响：内部包 +1（notion writer）；spec.md §2 调用链新增 writer
  - 影响范围：run 主入口加 Notion 配置加载，ranker/fetcher 不动
- 2026-07-20 · BUG-3 · fetcher 限流不报错
  - 原因：原代码吞掉 `X-RateLimit-Remaining=0` 响应
  - 修复：加显式 error + warn 日志 + 优雅退出部分结果
- 2026-07-19 · BUG-1 / BUG-2 · 排序 + LLM 覆盖
  - 原因：上 V 周末跑发现了 2 个隐性 bug
  - 修复：见 §3 BUG-N 索引
- 2026-07-15 · INIT · v1.0，骨架定下来（fetcher + ranker + 本地 markdown 输出）
```

事件类型枚举（§"演进事件"类型）：

# === 事件类型必须固定 ===
# 【为什么这样填】类型不准，新事件无法归档，§4 表格字段会乱。

- **INIT** · 项目立项 / 重大版本起点
- **ITER-N** · 增量功能
- **BUG-N** · Bug 修复（含 regression）
- **REV-N** · 重大重构 / 框架升级
- **DEP-N** · 废弃某个功能 / 模块

---

## §5 产物清单（每次 commit 必看）

# === §5 是 commit 的"账本" ===
# 【填法】按时间倒序，最近在最上面。每条 = commit hash + 一句话 + 改/加/不动文件清单。
# 【为什么这样填】回滚时知道"哪条 commit 改了什么 + 影响面"。

```markdown
- 2026-07-21 · a3f8e21 · "feat: 接入 Notion 推送"
  - 改：cmd/.../main.go, internal/writer/notion_client.go, configs/notion.yaml.example
  - 加：internal/writer/notion_client_test.go, docs/spec.md
  - 不动：fetcher/, ranker/, summarizer/

- 2026-07-20 · 8c1e07a · "fix(fetcher): 限流时显式返回 error 而非吞掉"
  - 改：internal/fetcher/fetcher.go, internal/fetcher/fetcher_test.go
  - 加：runs/2026-07-20/run.log（手动验证记录）
  - 不动：其他模块

- 2026-07-19 · bb93c44 · "fix: 排序 tiebreaker + LLM prompt hash 持久化"
  - 改：internal/ranker/ranker.go, internal/summarizer/summarizer.go
  - 加：相应 _test.go 覆盖 3 种场景
```

---

## §6 版本号

# === §6 是版本节奏的元规则 ===
# 【填法】小迭代 v1.x，大变更 v(N+1).0。
# 【为什么这样填】让"什么时候升大版本"有规矩可循，避免无意义的破坏性变更。

```markdown
- **v1.0** · 2026-07-15 · 立项 + 骨架（fetcher + ranker + 本地 markdown）
- **v1.1** · 2026-07-19 · bug 修复（BUG-1, BUG-2）
- **v1.2** · 2026-07-21 · 当前（接入 Notion 推送）
- **v1.3** · TBD · webhook 触发 + 本地 fallback（待 ITER-4, ITER-5）
- **v2.0** · TBD · PR / Discussion 拉取（重大功能变更）
```

> **升 v2.0 的判定**：API 路径大改 / 上下游断裂 / 多 GitHub 实例支持。
> 当前所有改动都属于 v1.x 内部。

---

## §7 链接到其他资产

- 项目总览：`PROJECT_WIKI/overview.md`
- 红线配置：`red_lines.yaml`
- 任务台账：`tasks/`
- 时间线：`runs/timeline.txt`
- 配置（不属 SOP 范围）：`configs/*.yaml.example`
- SOP 主文档：`../../README.md`

---

## §8 维护说明

- **新增功能** → §1.1 加一行 + §4 加 ITER-N + §5 加 commit
- **修 bug** → §3 加 ❌ BUG-N + §4 加 BUG-N + §5 加 commit
- **废弃功能** → §1.2 加一行 + §4 加 DEP-N
- **跨工具新增/删减** → §2 调用链图必须同步更新
- **§6 升版本号** → 跨工具新增 = v1.x+1；架构调整 = v2.0

> **更新频率**：每次 commit 后 §5 必更新；§1/§2/§3 修改需单独 commit（"docs: update spec"）。

---

# === 本 spec.md 示例特意展示的 3 件事 ===

# 1. §"功能边界"严格用"主谓宾"句式，避免"支持微信推送"这种含糊措辞
# 2. §"不变式"每条都带"实施 + 反例 + 教训"三件套——具体到能 grep
# 3. §4 演进事件用 markdown code block 含 markdown 体——便于直接复制粘贴进 git commit message
