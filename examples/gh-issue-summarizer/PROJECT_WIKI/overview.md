# gh-issue-summarizer 项目总览

> 创建：2026-07-15
> 最近更新：2026-07-21（接入 Notion 推送 ITER-3）
> 维护者：<name>

## 项目一句话

# === 字段 1：项目一句话 ===
# 【填法】≤ 30 字 · 说清"解决谁的什么问题"。
# 【为什么这样填】这是 L1 文档被引用最频繁的一句——AI 接力 / 新人入门 / 自己半年后回看
# 都靠这一句判断"我在不在对的项目里"。写得含糊，下面所有内容都白搭。

每周自动把指定 GitHub 仓库的高活跃 issue 提炼成中文 3 句总结，推到 Notion 数据库。

## 当前状态

# === 字段 2：当前状态 ===
# 【填法】永远 3 行——正在做、下一步、暂停。**不写"未来要做的所有事"**。
# 【为什么这样填】新人 / AI 接手第一秒要知道的就是"现在在干啥"。把"待办池"放别处。

- 🎯 **正在做**：v1.2 加 webhook 触发（从每周 cron → PR 事件触发）
- ⏭️ **下一步**：实现 Notion 推送失败时的本地 fallback（写 .ndjson 而不是丢数据）
- 🚫 **暂停**：Slack 推送（API 凭证没到位，等配置）

## 模块地图

# === 字段 3：模块地图 ===
# 【填法】一张表 · 模块名 / 路径 / 一句话职责 · 行数 ≤ 8。
# 【为什么这样填】"用户的需求该改哪个模块"——AI 看完这张表应直接答出来。
# 不写依赖关系（依赖在 spec.md §2）；不写内部函数（细节在 spec.md §2）。

| 模块 | 路径 | 一句话职责 |
|---|---|---|
| fetcher | `internal/fetcher/` | 调 GitHub API 拉指定仓库 issues + comments |
| ranker | `internal/ranker/` | 按"讨论热度"给 issues 排序，时间衰减 |
| summarizer | `internal/summarizer/` | 调 LLM API 把 issue body 提炼成 3 句中文 |
| writer | `internal/writer/` | 把结果写入 Notion 数据库，含重试 |
| run | `cmd/gh-issue-summarizer/main.go` | 编排加载配置 + 4 个模块 + 写时间线 |

## 关键不变量（Invariants）

# === 字段 4：关键不变量 ===
# 【填法】3-5 条 · 每条"具体规则"而不是"模糊原则"。
# 【为什么这样填】新人 / AI 改之前必须三思的东西——具体到能 grep。

1. **不调用生产凭证**：所有 API token 走 env var：`GH_TOKEN` / `LLM_API_KEY` / `NOTION_API_KEY`。
   仓库里**禁止** commit 任何真实凭证，配置 `.yaml` 文件必须仅含 key 名。
2. **LLM 输出必须可重放**：相同 `issue_id` + 相同 model + 相同 prompt 版本 → 必须产出相同总结。
   # 实施：`prompts/summary_v3.txt` hash 入库 + LLM temperature=0
3. **Notion API 限流保护**：官方 3 req/s；本项目硬上限 **2 req/s**。
   # 实施：`internal/writer/notion_client.go` 用 `golang.org/x/time/rate` 限流器
4. **失败不能丢数据**：任一工具失败，必须把该 issue 落到 `runs/fallback/<date>.ndjson` 而不是吞掉。
5. **窗口固定**：当前版本只看"过去 7 天的已关闭 + 已开启 issues"。改窗口 → ITER-N。

## 技术栈与依赖

# === 字段 5：技术栈与依赖 ===
# 【填法】只列 3-5 个最关键的依赖，不列小工具（linter、formatter 单列）。
# 【为什么这样填】新人要装环境时——按这 4 行装就够。

- **语言**：Go 1.23+
- **核心依赖**：`github.com/google/go-github/v62`、`github.com/sashabaranov/go-openai`、`github.com/jomei/notionapi`、`gopkg.in/yaml.v3`
- **运行要求**：网络可达 `api.github.com` / `api.openai.com` / `api.notion.com`
- **部署方式**：本地二进制 + cron（每周一 09:00 Asia/Shanghai）

## 常见任务入口

# === 字段 6：常见任务入口 ===
# 【填法】3-5 行 · 每个新任务一行"做什么 → 改哪里"。
# 【为什么这样填】让第一次接手的 AI / 新人不需要"先全局读一遍代码"就知道动手点。

- "加一个新排序维度" → 改 `internal/ranker/ranker.go` 的 `Score()` 函数，先看后写模仿已有约定
- "换一个 LLM 模型" → 改 `configs/llm.yaml` 的 `model` + 更新 `prompts/summary_v{N}.txt` 并升 v{N}
- "加一个新目标平台（不用 Notion）" → 复制 `internal/writer/notion_client.go` 为 `<platform>_client.go`，实现 `Writer` interface
- "GitHub 限流触发了" → 等 1 小时或为 `GH_TOKEN` 配 personal access token
- "某次运行失败要看回放" → 读 `runs/<date>/run.log` + `runs/fallback/<date>.ndjson`

## 失败处理（本项目专属 A/B/C）

# === 字段 7：失败处理 ===
# 【填法】本项目里的"具体 A/B/C 例子"，不要只抄 SOP §5 通用版。
# 【为什么这样填】失败分诊 SOP 通用版是抽象的；每个项目都有自己的具体长相。

| 类 | 本项目的"长相" | 处理 |
|---|---|---|
| **A 真问题** | LLM 总结出 nonsense（"无法理解"）、Notion 写字段名错、sort 排序稳定 tiebreaker 失效 | 回「实现」阶段 |
| **B 路径不通** | GitHub token 过期 / Notion database 没 share 给 integration / 限流触发 / LLM 余额为 0 | 改 `verify_plan` + 修凭证 |
| **C 脚本时序** | time.Sleep 不够长 / Notion API 重试时 backoff 不够 / yaml 解析时区错 | 阶段内重试 ≤ 2 轮 |

## 链接

- 项目规约：`docs/spec.md`
- 任务台账：`tasks/`
- 时间线：`runs/timeline.txt`
- SOP 主文档：`../../README.md`
- 模板来源：
  - 本文件 ← `../../templates/overview.md`

---

# === 注释 · 元信息 ===
# 【本文件示例特意展示的 3 件事】
# 1. 每节内联"【填法】+【为什么这样填】"注释 —— 复制时这些注释也要带着，读者看了知道怎么改
# 2. §"模块地图"严格 5 行内（4 个模块 + run）—— 5KB 限制的本质就是"模块数 ≤ 5"
# 3. §"失败处理"给本项目专属的 A/B/C 例子 —— 比 SOP §5 通用版更可操作

# === 文件末尾自检 ===
# - 字节数：约 3.2KB（≤ 5KB ✓）
# - 章节数：7 + 链接（≤ 10 ✓）
# - 不变量数：5（3-5 条 ✓）
# - 模块数：5（≤ 8 ✓）
