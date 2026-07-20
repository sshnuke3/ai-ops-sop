# gh-issue-summarizer — 跨 3 工具示例项目

> **这是本 SOP 的"完整端到端示例"**——把 5 个模板串在 1 个真实小项目里。
>
> 项目一句话：每周抓指定 GitHub 仓库的高活跃 issues，用 LLM 提炼 3 句话总结，推送到 Notion 数据库。
> 跨 3 个工具：GitHub REST API + LLM API + Notion API。

---

## 这是干什么的

| 用户视角 | 项目视角 |
|---|---|
| 想每周自动看 N 个仓库的"讨论热度 Top 10 issues" | 每周一自动跑一次，3 工具串联 |
| 不看英文长 issue body | LLM 提炼 3 句中文总结 |
| 在 Notion 笔记里集中查 | 推到 Notion 数据库，带排序/筛选 |

## 6 个产物文件 × 对应 SOP 章节

```
gh-issue-summarizer/
├── README.md                  ← 项目自己的入口
├── AGENTS.md                  ← AI 接力起点（对应 SOP §6 spec.md §0）
├── .gitignore                 ← examples 项目级忽略（演示产物不跟 git）
├── PROJECT_WIKI/
│   ├── overview.md            ← SOP §2 L1 总览（≤5KB）
│   └── .agent-rules           ← AI 自动化动作约束补充（OpenClaw 风格）
├── docs/
│   └── spec.md                ← SOP §6 项目总规（§0-§6）
├── red_lines.yaml             ← SOP §4 红线系统（启用 5 + 加 2 条）
├── tasks/
│   └── task-001-weekly-run.md ← SOP §1 任务产物清单 + §7 硬关卡
├── runs/
│   └── timeline.txt           ← SOP §6 三件套之"会话内时间线"
└── configs/                   ← 项目运行所需配置（不在 SOP 范围内）
    ├── repos.yaml.example
    ├── llm.yaml.example
    └── notion.yaml.example
├── prompts/                   ← LLM prompt 资产（含版本历史与 hash sidecar）
│   ├── README.md                （prompt 版本管理说明）
│   ├── summary_v3.txt           （当前主用 prompt）
│   ├── summary_v3.txt.sha256   （hash sidecar，sha256sum -c 验证）
│   └── summary_v2.txt           （已弃用 — DEP-N 反例）
├── commands/                  ← 命令入口（闭合文档-命令断链）
│   ├── Makefile                 （8 个 target 定义）
│   ├── README.md                （target 速查 + 设计原则）
│   └── scripts/run-once-dry.sh  （干跑脚本 demo）
```

每份文件都**完全填好**，且带**"为什么这样填"的设计注释**——读完会知道 SOP 的每条规则是怎么落到具体文件里的。

---

## 阅读顺序（建议）

如果你要把这个示例当作"完整 SOP 教程"读：

1. 先读 `PROJECT_WIKI/overview.md`（2 分钟）
   → 看清整个项目的物理布局 + 当前状态
2. 再读 `docs/spec.md`（8 分钟）
   → 看清"功能边界 + 模块地图 + 不变式 + 演进事件"
3. 然后读 `tasks/task-001-weekly-run.md`（3 分钟）
   → 看清一次"周跑"是怎么被切成 6 个阶段的
4. 接着读 `red_lines.yaml`（5 分钟）
   → 看清 AI 在这个项目里"绝对不能做的 7 件事"是哪 7 件
5. 最后读 `runs/timeline.txt`（2 分钟）
   → 看清实际跑下来事件是怎么落的

> 总共 ~20 分钟。

## 阅读顺序（如果你赶时间）

只想看模板怎么用？

- `PROJECT_WIKI/overview.md` —— 模板的"极限精简填空"
- `tasks/task-001-weekly-run.md` —— 模板的"完整填空 + 阶段拆解示范"
- `red_lines.yaml` —— 模板的"删 5 留 5 + 加 2 条跨工具专属"示范

> 这三份看 8 分钟就能回主 SOP 套用。

---

## 这个示例故意强调的几件事

| 强调点 | 在哪里体现 |
|---|---|
| **跨 3 工具的"输入即上一阶段产出"** | `tasks/task-001-weekly-run.md` 的 6 个阶段字段全部填了上游产物路径 |
| **跨工具的"边界不变量"** | `docs/spec.md` §3 列了 3 个工具各自的"不可越过边界" |
| **跨工具的"硬关卡 HK 应用"** | `tasks/task-001-weekly-run.md` 末尾列了 4 个 HK 在这个项目里的具体时机 |
| **跨工具的"失败分诊 A/B/C"** | `docs/spec.md` §6 + `tasks/task-001-weekly-run.md` 都有"这个项目里 A/B/C 长什么样" |
| **跨工具的"配置从不进 prompt"** | `red_lines.yaml` 加了 RL-55（**比标准模板里新增的一条**） |

---

## 怎么把这份示例套到你自己的项目上

```
1. 复制整个 examples/gh-issue-summarizer/ 到你的项目根
2. 把模块名、API 名字、配置项全替换成你的
3. 跑一次"纸上推演"：对着 tasks/task-001 走一遍你的 6 阶段，看哪里阻塞
4. 阻塞点 = 你项目里的"主问题"，先修这里
5. 套 red_lines.yaml 时，**禁用不相关的**，**新增你项目专属的红线**
```

> **不要原样照搬配置和 API key**——这是示例项目，不连任何真实凭证。

---

**版本**：v0.1（example 第一版 · 与 SOP v0.1 配套）
