# 项目总规文档模板（spec.md）

> **用途**：项目级永久资产，记录"项目做什么、怎么做、不能动什么"。
> **何时写**：项目立项第一周，骨架定下来时就该有。
> **谁读**：下一次会话的 AI（入场扫描）+ 新人入职 + 半年后回看的自己。
> **抄走方式**：复制本文件 → 改名 `docs/spec.md` → 按节填空，前 4 节优先。

---

## 为什么这是核心

| 没这份文档 | 有这份文档 |
|---|---|
| 每次 AI 都从零理解，重复踩坑 | AI 接力读 5 分钟，无缝干活 |
| 新人入职能问出 100 个问题 | 新人读 + 问 5 个问题就上手 |
| Bug 复发，没人记得为什么这么改 | 演进事件链完整，决策可追溯 |
| 半年后自己也看不懂项目 | 自己回看，10 分钟想起全貌 |

---

## 模板（blank，照抄改）

```markdown
# <项目名> 项目规约

> 创建：YYYY-MM-DD
> 最近更新：YYYY-MM-DD（关联 commit hash）
> 维护者：<名字 / 联系方式>

---

## §0 AI 入场自检清单

> **下次会话的 AI 进入本项目的第一件事**，按顺序读完下列项才算"已接手"。

1. [ ] 读过本文档的 §0、§1、§2、§3（其他按需）
2. [ ] 跑过 `make doctor` 或等价命令，开发环境 OK
3. [ ] 看过 `runs/timeline.txt` 最近 50 行，知道上周在干啥
4. [ ] 知道当前唯一进行中的任务（"当前状态"在 README）
5. [ ] 已读完本项目的 `red_lines.yaml` 的 critical 部分

---

## §1 功能边界（做什么 / 不做什么）

### 1.1 ✅ 这一版做（In-Scope）

- <功能 A>：<一句具体定义，含验收标准>
- <功能 B>：<同上>
- <功能 C>：<同上>

### 1.2 ❌ 这一版不做（Out-of-Scope）

- <不做 X>：<为什么不做>
- <不做 Y>：<同上>

### 1.3 ⚠️ 待定（Pending）

- <待定 P1>：<原因 / 何时定>
- <待定 P2>：<同上>

> **新人 / AI 越界的第一道防线**：改了 §1.2 里的"不做项" = 严重越界，立即回退。

---

## §2 模块地图

> **一张表看懂项目的物理结构。** 只看这一张表，AI 应该能判断"用户的需求该改哪个模块"。

| 模块 | 路径 | 关键公开 API | 依赖 |
|---|---|---|---|
| <模块 1> | `src/<path>/` | `<FuncA> / <FuncB>` | <其他模块> |
| <模块 2> | `src/<path>/` | ... | ... |
| <模块 3> | `<path>` | ... | ... |

### 关键调用链（用户视角）

```
用户 → <入口函数>
       ↓
<调用 A>
       ↓
<调用 B>（核心业务逻辑）
       ↓
<副作用：DB / 网络 / 文件>
```

---

## §3 不变式（Invariants）

> **项目里绝对不能动的东西。** 改之前必须三思 + 在文档里加演进事件记录。

1. **<不变量 1>**：<精确描述，含"为什么不能动">
   - 例："API 路径前缀 `/v1/` 不能换——会破坏老客户端的 oncall 集成"
2. **<不变量 2>**：<同上>
3. **<不变量 3>**：<同上>

### 不要复发的 Bug / 不允许的回归

- ❌ **BUG-N（YYYY-MM-DD）**：<简述>。
  - 教训：<一行总结，避免再次犯>
- ❌ **REV-N（YYYY-MM-DD）**：<重构/回滚事件>。

---

## §4 演进事件（Evolution Timeline）

> 按时间倒序排，最近的事件在最上面。每条 ≤ 3 行：日期 + 事件类型 + 一句话。

```markdown
- 2026-07-21 · ITER-3 · 接入多仓库配置项
  - 原因：单仓库硬编码被业务提出
  - 影响：configs/repos.yaml 新增，`fetcher.New()` 接受路径参数
  - 影响范围：CLI 入口，ranker/writer 不动
- 2026-07-15 · BUG-1 · 排序在 comment 数相同时随机
  - 原因：score 函数未对 tiebreaker 做确定化
  - 修复：增加 issue_id 字典序作为 tiebreaker，加单测覆盖
- 2026-07-10 · REV-1 · 升 go-github v60 → v62，移除 deprecated API
- 2026-07-01 · INIT · v1.0，骨架定下来
```

事件类型枚举：
- **INIT** · 项目立项 / 重大版本起点
- **ITER-N** · 增量功能
- **BUG-N** · Bug 修复（含 regression）
- **REV-N** · 重大重构 / 框架升级
- **DEP-N** · 废弃某个功能 / 模块

---

## §5 产物清单（每次 commit 必看）

> **维护一个 git-tracked 的"每次 commit 改了什么"台账**，便于回滚时找 commit。

```markdown
- 2026-07-21 · a3f8e21 · "接入多仓库配置项"
  - 改：configs/repos.yaml, internal/fetcher/fetcher.go, cmd/.../main.go
  - 加：configs/repos.example.yaml, internal/fetcher/fetcher_test.go
  - 不动：ranker/, writer/, templates/

- 2026-07-15 · 91c2d04 · "fix: 排序 tiebreaker 确定化"
  - 改：internal/ranker/ranker.go
  - 加：internal/ranker/ranker_test.go（覆盖 3 种 tie 场景）
```

---

## §6 版本号（Versioning）

```markdown
- **v1.0** · 2026-07-01 · 立项 + 骨架
- **v1.1** · 2026-07-21 · 接多仓库配置（当前）
- **v2.0** · TBD · 数据库接入（重大变更，baseline 合并触发）
```

> **版本规则**（建议）：
> - **v0.x** · 早期，内部快速迭代
> - **v1.0** · 第一个对外/可用版本
> - **v1.x** · 增量功能 + bug 修复
> - **v2.0** · 重大变更（API 重写 / 架构调整 / 上下游断裂）—— 必须 baseline 合并

---

## §7 链接到其他资产

- 项目总览：`README.md` 或 `PROJECT_WIKI/overview.md`
- 红线配置：`red_lines.yaml`
- 任务台账：`tasks/`（每子任务一个 .md 或 .yaml）
- 时间线：`runs/timeline.txt`
- 模块详细 spec：`docs/modules/<module>.md`（按需拆出）
- 设计/产品术语桥：`docs/term-mapping.md`（按需拆出）

---

## §8 维护说明

- **新增功能** → 在 §1.1 加一行 + §4 加 ITER-N + §5 加 commit
- **修 bug** → 在 §3 加 ❌ BUG-N + §4 加 BUG-N + §5 加 commit
- **废弃功能** → 在 §1.2 加一行 + §4 加 DEP-N
- **重构** → 在 §4 加 REV-N + 强制写"前后对比"在 commit message

> **更新频率**：每次 commit 后必须更新 §5；§1/§2/§3 的修改需要单独 commit（"docs: update spec"）。
```

---

## 填好示例（GitHub issue 爬虫小工具）

```markdown
# gh-issue-crawler 项目规约

> 创建：2026-07-01
> 最近更新：2026-07-21（a3f8e21）
> 维护者：<name>

---

## §0 AI 入场自检清单

1. [ ] 读过本文档 §0-§3
2. [ ] 跑过 `make doctor`，验证 GitHub token + Go 1.23+
3. [ ] 看过 `runs/timeline.txt` 最近 50 行
4. [ ] 知道当前在做的：跑通单仓库每周自动跑一次（cron）
5. [ ] 已读 `red_lines.yaml` critical 部分

---

## §1 功能边界

### 1.1 ✅ 做的
- **拉 issues + comments**：单个 GitHub 仓库，按周拉
- **按热度排序**：comment 数 + 时间衰减
- **输出 markdown 周报**：模板在 `templates/report.tmpl`

### 1.2 ❌ 不做的
- **多 GitHub 实例**（GitHub Enterprise）：先不做，等 v2.0
- **飞书/钉钉推送**：API 凭证未到位，暂停

### 1.3 ⚠️ 待定
- **多仓库**：configs/repos.yaml 设计中
- **Webhook 触发**：等 v1.2

---

## §2 模块地图

| 模块 | 路径 | 关键 API | 依赖 |
|---|---|---|---|
| fetcher | `internal/fetcher/` | `New(token) / Fetch(repo)` | go-github |
| ranker | `internal/ranker/` | `Score(issue)` | 无 |
| writer | `internal/writer/` | `Render(issues)` | templates/ |
| main | `cmd/.../main.go` | `Run()` | fetcher + ranker + writer |

### 关键调用链

```
main.Run()
  → fetcher.Fetch(repo)
  → ranker.Score(issues)
  → writer.Render(sorted)
  → os.Stdout (或文件)
```

---

## §3 不变式

1. **GitHub API 限流**：60 次/小时（无 token），6000 次/小时（有 token）。代码里不能硬编码超过这个上限。
2. **排序确定性**：相同输入必须产相同排序——避免 AI 输出"看起来差不多"的结果。
3. **markdown 模板与代码分离**：模板改动在 `templates/report.tmpl`，不在 Go 代码里硬编码。
4. **token 来自环境变量**：禁止 hardcode 或进 prompt。

### 不允许的回归
- ❌ BUG-1（2026-07-15）：排序在 comment 数相同时随机
  - 教训：所有 score 函数必须显式定义 tiebreaker
- ❌ REV-1（2026-07-10）：v60 → v62 升级曾误删 deprecated API
  - 教训：升 major 版本前要写 EOL 检查清单

---

## §4 演进事件

- 2026-07-21 · ITER-3 · 接多仓库配置项
- 2026-07-15 · BUG-1 · 排序 tiebreaker 确定化
- 2026-07-10 · REV-1 · 升 go-github v60 → v62
- 2026-07-01 · INIT · v1.0 立项

---

## §5 产物清单

（按 commit 维护，见上方模板说明）

---

## §6 版本号

- **v1.0** · 立项
- **v1.1** · 当前（多仓库配置）

---

## §7 链接

- 总览：`README.md`
- 红线：`red_lines.yaml`
- 任务：`tasks/`
- 时间线：`runs/timeline.txt`
```

---

## 常见错误

| 错 | 正 |
|---|---|
| 写成项目宣传文案 | 写成"地图 + 边界 + 不变量 + 演进"，**不写品牌故事** |
| §3 不变式写得很抽象 | "数据要安全"（错）→ "token 走 env var，禁止 hardcode"（对） |
| §4 没维护 | 每周 commit 后补，**这是文档的"骨架"** |
| §6 版本号不更新 | 每次基础功能完整时升小版本（v1.x → v1.x+1） |

---

**版本**：v0.1 · §0-§3 是必填项，§4-§6 按需。文档体量大了按模块拆 `docs/modules/`。
