# AGENTS.md —— gh-issue-summarizer 的 AI 接力点

> **这是 AI 接手本项目的第一份文件**。读完下面 §1 才算"已入场"。
> 对应文档：`docs/spec.md` §0 AI 入场自检清单。本文件是 §0 的"操作版"。

## §0 你的角色

你是 gh-issue-summarizer 的 AI 协作助手。

# === 这一节是"给 AI 的人设" ===
# 【填法】1 句话 / 用"AI 协作助手"而不是"AI 模型"。
# 【为什么这样写】OpenClaw 风格——给 AI 一个明确身份，让 prompt 里"你"不模糊。

**当前维护者**：人类 1 名（不在场时不主动 push / 改线上 / 触发不可逆动作）。
**协作对象**：跨 3 工具的自动化项目（GitHub + LLM + Notion）。

## §1 接力入口 · 5 件必做

# === 这一节是"AI 一入场就要做的事" ===
# 【填法】5 件按顺序，每件后跟"没做会怎样"。
# 【为什么这样填】比 spec.md §0 的 checkbox 更"命令"——让 AI 知道这是 action，不是 todo。

1. **读 `docs/spec.md` §0-§3** —— 不读 = 越界风险
   # 没读：可能会去改"v2.0 才做"的 PR 拉取功能
2. **读 `PROJECT_WIKI/overview.md`** —— 5 分钟看清项目物理布局
   # 没读：会改错模块路径 / 加错不变量
3. **读 `red_lines.yaml` 的 `load_policy.on_session_start`** —— 拿启动必加载的 6 条红线
   # 没读：会无意触发 LLM 调用（每次都花钱）
4. **看 `runs/timeline.txt` 最近 30 行** —— 知道上周发生了什么 / 哪里在卡
   # 没看：会重做别人已修过的 bug（spec §3 BUG-N 都列了）
5. **确认当前唯一进行中的任务**（见 `PROJECT_WIKI/overview.md` 的"正在做"）
   # 没确认：会让 AI 同时推进多任务 = 跑飞

## §2 别动什么

# === 这一节是"反向护栏" — 比 spec.md §1.2 更具体 ===
# 【填法】6 条"绝对不要碰的事"，每条配"为什么 + 越界代价"。
# 【为什么这样写】spec.md §1.2 是"项目边界"；AGENTS.md §2 是"动作边界"——更具体到 AI 看得懂的动作。

| 不要做 | 为什么 | 越界代价 |
|---|---|---|
| **改 `prompts/summary_v3.txt` 不升版本号** | hash 锁定就失效了 | 所有旧 issue 的 Notion 字段对不上"prompt_version" |
| **跳过 `runs/<date>/<stage>.json` 落盘步骤** | SOP §1 退出标准 = 唯一判据 | 失败分诊没法 A/B/C |
| **单次跑 LLM 调超过 ¥5 不问就继续** | 触发 RL-PRJ-1 = 红线 | 维护者不知情扣费 / 月底账单爆炸 |
| **改 `docs/spec.md` §1.2 "不做项"** | 这是项目级越界 | 整项目范围漂移 |
| **写新 commit 不更新 `runs/timeline.txt`** | 时间线 = 跨会话知识传承 | 下次接班 AI 看不见上下文 |
| **删 `runs/fallback/*.ndjson`** | 失败数据 = 调试资产 | 重复 bug 复现不出 |
| **不读 `red_lines.yaml` 直接调 LLM** | 标准流程 = 先算成本再调 | 触发 RL-PRJ-1 必停下 |

## §3 失败时分诊 · 决策树指针

# === 这一节是"失败第一动作" ===
# 【填法】不是把 A/B/C 决策树再写一遍，而是指针到哪去查。
# 【为什么这样写】决策树只有一个权威源（templates/failure-triage.md）；AGENTS.md 只放指针避免双维护。

**第一动作**：失败 → 打开 `docs/spec.md` §"失败处理" 的 A/B/C 表 → 仍不确定 → 看 task 文件里的"失败回退"表。

```
失败发生
  │
  ├─ 是测试/编译错？        → §spec §"不变式" → §red_lines RL-15
  ├─ 是 LLM 输出问题？      → §prompts/README.md → §spec §"不变式 2"
  ├─ 是 Notion 写失败？    → §red_lines RL-PRJ-2 → §tasks stage 5
  ├─ 是 GitHub 拉失败？    → §red_lines RL-31 → §tasks stage 2
  └─ 都对不上？            → 立即停下问维护者，不硬试
```

> **核心规则**：判断不出 A/B/C 时，**停下问**比"硬试"便宜。LLM 重试 1 次 = ¥0.05，问问题 = ¥0。

## §4 触发硬关卡 HK · 何时叫人

# === 这一节是 SOP §7 在项目里的具体化 ===
# 【填法】4 条 HK 触发时机，每条带"找维护者用什么渠道"。
# 【为什么这样填】AGENTS.md 是 AI 醒来看的；HK 列表比 spec.md 那张表更"现在是该 HK-X 了吗"。

| HK | 触发时机（满足任一即触发） | 找维护者 |
|---|---|---|
| **HK-0** | 新会话接手 + 现场快报 | 在 PR / commit message 提到 @maintainer |
| **HK-1** | PENDING 条目（任务拆解完成） | 等 spec.md §1.3 的"待定"决策 |
| **HK-2** | `runs/<date>/run.log` 落盘后 | 贴最后 20 行让维护者看 |
| **HK-3** | 任何写 Notion / 触发 LLM 前 | 报告待操作清单 + est_cost + 等 "go" |
| **HK-5** | 准备回退到「实现」阶段时 | 报"A 分诊 + 回退方案"等 "回退 / 改方案" |

> **不触发 HK-4**（本项目每次跑 ≤ 10 分钟）。
> **不触发 HK-3** 仅当：当前在跑 `make doctor` 或本地 dry-run（不写外部）。

## §5 跑完 / 提交时 · 5 件沉淀动作

# === 这一节是"commit 前 5 件" ===
# 【填法】跟 spec.md §5 产物清单 + §8 维护说明一致，但更命令语气。
# 【为什么这样写】AI 提交 commit 前看一眼这 5 件。

- [ ] **追加 `runs/timeline.txt`** —— append only，hash 不算
- [ ] **更新 `docs/spec.md` §5 产物清单** —— commit hash + 改/加/不动文件
- [ ] **更新 `docs/spec.md` §4 演进事件**（新加 ITER-N / BUG-N / REV-N / DEP-N）
- [ ] **跑 `make doctor`** —— 确认改动没破坏其他工具的 API 联通
- [ ] **commit message 写 "X/Y files pass" 必须先确认测试文件真存在**
  # === 这一条是踩过的坑 ===
  # 【填法】写成强约束而不是"建议"
  # 【为什么这样写】项目历史上有 commit message 谎称"5/5 tests pass"但实际 _test.go 文件不存在的案例——这种"假绿色 commit" 会让后来人 / 后续 AI 误判项目健康度

## §6 兜底 · 严重错误时

# === 这一节是"实在不行就停下" ===

**满足任一立刻停下问维护者**，不要硬试：

1. 涉及外部 API 写且影响范围超本项目边界（删 Notion database / 清 LLM 账户）
2. 失败现象完全没见过，无从判断 A/B/C
3. 同一阶段已回上游改过 2 次，仍失败
4. 任何包含 `rm -rf` / `DROP TABLE` / `git push --force` / `kubectl delete` 的命令
5. 跑出数据明显错了但复现不出来（可能模型 / 配置都变了）

> **问问题不丢人，闯祸才丢人。**

## §7 链接

- 项目规约：`docs/spec.md`（AI 自检清单在 §0）
- 项目总览：`PROJECT_WIKI/overview.md`
- 红线配置：`red_lines.yaml`
- 任务台账：`tasks/`
- 时间线：`runs/timeline.txt`
- Prompt 资产：`prompts/`
- SOP 主文档：`../../README.md`

---

# === 本 AGENTS.md 示例特意展示的 3 件事 ===
# 1. §1 "5 件必做" 是 action 不只是 checkbox——比 spec.md §0 那张清单更"实操化"
# 2. §2 "别动什么" 表 = 7 条反向护栏——把红线"翻译"成 AI 看得懂的动作清单
# 3. §3 失败分诊只放指针不复制决策树——避免 SOP 双源同步问题（决策树只在 templates/failure-triage.md）
