# prompts/ —— gh-issue-summarizer 的所有 prompt 文件

> 本目录是项目"知识资产"的一部分，按 spec.md §"事件类型"治理。

## 当前文件

| 文件 | 状态 | 用途 |
|---|---|---|
| `summary_v3.txt` | **生效中** | 当前主用 prompt，hash 由 sidecar 锁定 |
| `summary_v3.txt.sha256` | 配套 | hash sidecar，`sha256sum -c` 验证一致性 |
| `summary_v2.txt` | **已弃用**（DEP-N） | 历史反例，保留作"为什么 v3 那样写"对照 |

## 版本规则

1. **任何字符变动 → 升版本号**
   - 改 `summary_v3.txt` 哪怕只改一个空格，都必须改名为 `summary_v4.txt`（不能覆盖）
   - 不允许的写法：保留同名改内容 —— 破坏 hash 锁定意义

2. **升版本必须连动 5 件套**
   - [ ] 旧版文件保留为 `.txt`（DEP-N 弃用，不要删）
   - [ ] 新版文件名 +1（`summary_v3.txt` → `summary_v4.txt`）
   - [ ] 新版 `*.sha256` sidecar 重新生成
   - [ ] `configs/llm.yaml.example` 的 `prompt_path` 改指新文件
   - [ ] `docs/spec.md` §"不变式 2" 与 §4 演进事件加 ITER-N 行
   - [ ] Notion 数据库加 viewer 标签 `prompt-version=v{N}` 用于筛选历史

3. **hash 必须放 sidecar 文件**
   - ❌ 不要在 prompt 正文里写 `# SHA256: abc...` —— "写 hash 这一行"会改变 hash
   - ✅ 写到 `.sha256` 文件，格式：`hex  filename`
   - 验证：`cd prompts && sha256sum -c summary_v3.txt.sha256`

## 升版本流程示例（v3 → v4）

```bash
# 1. 复制当前 v3 作 v4 的起点
cp prompts/summary_v3.txt prompts/summary_v4.txt

# 2. 修改 v4 内容
$EDITOR prompts/summary_v4.txt

# 3. 重新生成 sidecar
sha256sum prompts/summary_v4.txt > prompts/summary_v4.txt.sha256

# 4. 验证
cd prompts && sha256sum -c summary_v4.txt.sha256

# 5. 更新 spec + configs（手动）
$EDITOR configs/llm.yaml.example   # prompt_path: prompts/summary_v4.txt
$EDITOR docs/spec.md               # §"不变式 2" + §4 ITER-N

# 6. 标记 v3 弃用（移到 DEP-N）
# 在 docs/spec.md §4 加：
#   2026-XX-XX · DEP-1 · 弃用 summary_v3.txt，改用 summary_v4.txt
#     原因：<一句话>
#     影响：summarizer 加载 prompt 时走 v{N}，旧 issue 总结保留 prompt_version=v3 不变
```

## 为什么 prompt 写这么严

> 这套 prompt 设计的"硬约束"不是凭感觉，是被**真实的 20 次跑出来的 4 类失败**逼出来的（见 v2 文件内的对比）。
>
> 跨工具 LLM 项目的核心可信度 = **prompt 行为可预期 + 幻觉率接近 0**。
> 上面这套做法是在信任 LLM 之前，先把"会让它跑偏的 5 件事"堵上。

## 维护说明

- **本目录不进 LLM prompt 自身**——目录里的 `.md` / `.sha256` / 旧版本文件都没被 summarizer 加载
- summarizer 加载只看 `configs/llm.yaml.example` 的 `prompt_path` 指向的那一个文件
- 旧版本文件用 git 历史/直接读确认存在，不参与运行时

---

# === 本 README 示例特意展示的 3 件事 ===
# 1. 升版本必须有"5 件套"清单——避免漏改配置文件 / 文档
# 2. sidecar hash 是 lock，hash 必须在独立文件里（之前踩过内嵌 hash 自循环的坑）
# 3. 旧版本**不删**作为反例——读者看到 v2 vs v3 差异比 git log diff 直观
