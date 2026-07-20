# task-001: gh-issue-summarizer 每周自动跑

> 模板来源：`../../../templates/task-output-spec.md`
> 创建：2026-07-15
> 最近更新：2026-07-21（接入 Notion 推送后阶段 5 重写）
> 关联版本：v1.2

## 任务一句话描述

每周一 09:00（Asia/Shanghai）自动执行：
1. 拉取 5 个 GitHub 仓库的过去 7 天高活跃 issues
2. 按"讨论热度"排序取 Top 10
3. LLM 提炼每条 issue 的 3 句中文总结
4. 写入 Notion 数据库
5. 落盘时间线 + 本次 run 日志

## 任务类型

跨 3 工具的复合长任务（GitHub + LLM + Notion）

---

## 阶段清单

# === 阶段字段的填法 ===
# 【每阶段 3 件套】
# - 输入：具体文件路径或 API 名
# - 产出：具体文件路径 + 内容摘要
# - 退出标准：机器可校验（exit code / file exists / JSON shape）
#
# 【为什么这样填】这是 SOP §1 的"流水线骨架"在跨工具项目里的具体长相
# 关键是：**后一阶段的输入 = 前一阶段的产出文件路径**，跨阶段不能依赖用户原话。

### 阶段 1：配置加载

- **输入**：
  - `configs/repos.yaml`（仓库列表）
  - `configs/llm.yaml`（LLM 配置：模型 + endpoint）
  - `configs/notion.yaml`（Notion 数据库 ID + 字段映射）
  - 环境变量：`GH_TOKEN` / `LLM_API_KEY` / `NOTION_API_KEY`
- **产出**：`/tmp/run-<date>/config_snapshot.json`（运行时配置快照 + token 引用，未含值）
- **退出标准**：
  - ✅ `config_snapshot.json` 存在
  - ✅ 3 个环境变量都非空（`os.Getenv()` 返回非空）
  - ✅ 仓库列表 ≤ 5 个（限流保护）
  - ✅ `go run ./cmd/config-validator` 退出码 0（schema 验证）

### 阶段 2：拉取 issues（fetcher）

- **输入**：`config_snapshot.json` 的 `repos` 字段
- **产出**：`runs/<date>/issues.json`（issues 列表，按仓库分组）
  ```json
  {
    "<owner>/<repo>": [
      {"id": 123, "title": "...", "body_len": 1234, "comments": 12, "created_at": "..."},
      ...
    ],
    ...
  }
  ```
- **退出标准**：
  - ✅ `runs/<date>/issues.json` 存在
  - ✅ 每个仓库至少 1 条 issue（否则 warn：是否限流？）
  - ✅ `X-RateLimit-Remaining >= 5`（剩 ≥ 5 才算 OK，剩 0 = 触发 B 分诊）
  - ✅ `total_count >= len(fetched)`（分页正确）

### 阶段 3：排序（ranker）

- **输入**：`runs/<date>/issues.json`（**不许回到原 config 或用户原话**）
- **产出**：`runs/<date>/scored.json`
  ```json
  {
    "top10": [
      {"issue_ref": "<owner>/<repo>#123", "score": 87.3, "tiebreaker_key": "..."},
      ...
    ]
  }
  ```
- **退出标准**：
  - ✅ `runs/<date>/scored.json` 存在
  - ✅ `len(top10) <= 10`
  - ✅ 排序确定：相同输入重跑产出完全一致（单元测试断言）
  - ✅ tiebreaker 显式（`tiebreaker_key` 字段非空）

### 阶段 4：LLM 提炼（summarizer）

- **输入**：`runs/<date>/scored.json` 的 `top10` 字段
- **产出**：`runs/<date>/summaries.json`
  ```json
  {
    "summaries": [
      {
        "issue_ref": "<owner>/<repo>#123",
        "summary": "中文 3 句话总结",
        "prompt_version": "v3",
        "prompt_hash": "sha256:abc...",
        "tokens_used": 456
      }
    ]
  }
  ```
- **退出标准**：
  - ✅ `runs/<date>/summaries.json` 存在
  - ✅ 每条 summary 中文 3 句（语言检测置信度 > 0.8）
  - ✅ 每条带 `prompt_version` + `prompt_hash`
  - ✅ `total_tokens_used <= 50000`（硬上限，超出 → 回 RL-PRJ-1）

### 阶段 5：写入 Notion（writer）

- **输入**：`runs/<date>/summaries.json` 的 `summaries` 字段
- **产出**：
  - Notion 数据库新增 N 条记录（N = `len(summaries)`）
  - `runs/<date>/notion_response.json`（API 响应摘要，200/错误码）
- **退出标准**：
  - ✅ 所有 API 调用 200（失败重试 ≤ 3 次）
  - ✅ `len(notion_response.success) == len(summaries)`
  - ✅ 任何失败 issue 必须落 `runs/fallback/<date>.ndjson` 而非吞掉

### 阶段 6：沉淀 + 时间线

- **输入**：所有上游产物（`config_snapshot.json` / `issues.json` / `scored.json` / `summaries.json` / `notion_response.json`）
- **产出**：
  - `runs/<date>/run.log`（包含所有阶段摘要 + 时间戳 + token 用量 + 总时长）
  - `runs/<date>/heartbeat.txt`（每 60s 心跳）
  - 追加一行到 `runs/timeline.txt`
- **退出标准**：
  - ✅ `run.log` 含 `OK: wrote N issues` 行
  - ✅ `heartbeat.txt` 行数 ≥ 预期（如果跑 5 分钟应该 ≥ 4 心跳）
  - ✅ `timeline.txt` 追加成功（grep 能找到本次日期）

### 阶段 7：通知（如失败）

- **输入**：阶段 6 的 `run.log` + `runs/fallback/<date>.ndjson`（如果存在）
- **产出**：可选——本项目暂时不通知（见 spec §1.2 飞书/Slack 暂停）
- **退出标准**：本阶段本期跳过，但代码里必须留 hook（`internal/notifier/notifier.go` 为空 interface）

---

## 不允许的跳步

# === 这一节是"防御性清单"，是 SOP §1 的具体化 ===
# 【填法】每条都是真实可能发生的"AI 偷懒"模式。
# 【为什么这样填】光说"不许跳"没用——必须穷举"长什么样的算跳"。

- ❌ 阶段 3（ranker）不能直接读 `configs/repos.yaml` 再现场解析 issue
  → 必须读阶段 2 的 `issues.json`
- ❌ 阶段 4（summarizer）不能从 `fetcher.Fetch()` 实时拉
  → 必须读阶段 3 的 `scored.json` 里 issue_ref
- ❌ 阶段 5（writer）不能"凭印象已发送"——必须看 Notion API 响应码
- ❌ 阶段 6 不能"看着 run.log 像 OK 就报告完成"
  → 必须 `grep "OK: wrote" runs/<date>/run.log` 通过
- ❌ 任何阶段不能跨过另一阶段——比如阶段 3 直接读阶段 1（会绕过阶段 2 的限流检查）

## 失败时的回退路径

# === 这一节是 SOP §5 "失败双闸门"在跨工具项目里的具体长相 ===

| 阶段 | A 真问题 | B 路径不通 | C 脚本时序 |
|---|---|---|---|
| 1 配置 | schema 错 | token 过期（env 为空） | yaml 时区解析错 |
| 2 fetch | fetcher 报限流未报错（BUG-N） | token 过期 / 仓库不存在 | sleep 不够 / 重试 backoff 不对 |
| 3 rank | sort tiebreaker 失效 | 空数据（fetcher 0 条） | JSON 解析错 |
| 4 sumz | LLM 返回 nonsense | 余额为 0 / rate limit | context 太长截断 |
| 5 write | 字段名拼错 | database 没 share 给 integration | retry backoff 不足 |
| 6 log | run.log 写入失败 | 磁盘满 / 权限错 | 时区错乱 |

- 阶段 N 退出标准未达 → 回阶段 N-1 重做（**不跳阶段重读原话**）
- 阶段 N 连 2 次失败 → **停下问用户**，不硬试
- 阶段 6 沉淀心跳缺失 → 检查 watchdog，不一定是 stage 失败

## 阶段间共享的全局不变量（再强调）

# === 这里再复述一遍项目级不变量，避免 AI 在阶段间忘记 ===
1. token 永远走 env var，绝不写进落盘文件
2. 任一阶段失败必须落 `runs/fallback/<date>.ndjson`，不准吞掉
3. LLM cost > ¥5 触发 RL-PRJ-1，必须用户拍板

## 任务专属硬关卡 HK

# === SOP §7 "硬关卡 HK" 在这个项目里的具体触发点 ===
# 【填法】每条标"在哪个阶段的何时触发 + 用户回什么"。
# 【为什么这样填】HK 是抽象的；任务专属 HK 才是"现在、这里、该问什么"。

| HK | 触发时机 | 本项目具体动作 | 用户回什么 |
|---|---|---|---|
| **HK-0** 现场快报 | 新会话接手时 | 报告：上次跑通时间 + 当前 stage | "确认 / 改 N" |
| **HK-2** 沉淀 ok | `run.log` 落盘后 | 贴出 log 最后 20 行 | "沉淀 ok / 改 xxx" |
| **HK-3** 提交/发布 | Notion 推送完成前 | 列出待推 N 条 issue_ref + 预估 cost | "提交 / go / 改文案" |
| **HK-5** 失败回退 | 触发 RL-PRJ-1 LLM cost 超阈值 | 报告：est_cost / est_tokens / 已成功 N | "回退 / 减少到 top5 / 放弃" |

> 本任务不触发 HK-1 PENDING（已是 cron 自动任务，无需确认顺序）和 HK-4 长跑（5-10 分钟内会跑完）。

## 当前进度（接入 Notion 推送后）

```markdown
- [x] 阶段 1 配置加载        (2026-07-15 完成)
- [x] 阶段 2 拉 issues       (2026-07-15 完成)
- [x] 阶段 3 排序            (2026-07-19 完成)
- [x] 阶段 4 LLM 提炼        (2026-07-19 完成)
- [x] 阶段 5 写 Notion       (2026-07-21 完成)
- [x] 阶段 6 沉淀时间线      (2026-07-21 完成)
- [ ] 阶段 7 通知（暂停）    (等 spec §1.3 飞书凭证)
```

---

## 配套文件

- 项目总览：`../PROJECT_WIKI/overview.md`
- 项目规约：`../docs/spec.md`
- 红线配置：`../red_lines.yaml`
- 时间线：`../runs/timeline.txt`
- 配置示例：`../configs/*.yaml.example`

---

# === 本 task-001 示例特意展示的 3 件事 ===
# 1. 6 个阶段都有完整"输入=上游产物"——跨 3 工具的项目里"输入"必须具体到文件路径
# 2. 失败回退表是 7 行 × 3 列（A/B/C）——把 SOP §5 通用版压成项目专属可查表
# 3. HK 表是项目里的具体触发点（4 条），不是 SOP 默认的全部 6 条——按需取用
