#!/usr/bin/env bash
# run-once-dry.sh —— gh-issue-summarizer 的干跑脚本（demo 级）
#
# 用途：模拟完整流水线但不真写外部（不调 Notion / 不调真 LLM）
# 引用方：.agent-rules §ci_hooks.pre_push / commands/Makefile `run-once-dry` target
#
# === 本脚本示例特意展示的 3 件事 ===
# 1. set -euo pipefail —— 严格 bash 设置，失败立刻停
# 2. 输出带上标签（"[fetcher]" / "[ranker]" 等），方便 grep 找阶段
# 3. dry-run 通过"假装 success + 写本地 ndjson"实现，不直接删真写逻辑

set -euo pipefail

# === 配置：演示用路径 ===
# 真实项目里这些是 cmd/.../main.go 调 internal/ 的各个模块
# demo 级用一个总脚本按 SOP §1 阶段顺序跑

# === 0. 前置 ===
DATE=$(date +%Y-%m-%d)
DRY_DIR="runs/${DATE}-dry"
mkdir -p "${DRY_DIR}/stages"

# === 1. 阶段 1：配置加载 ===
log() { echo "[$(date +%H:%M:%S)] $1"; }
log "[stage-1] 配置加载 (dry-run)"

# demo 级：不真验 env，但检查文件存在
if [ ! -f "configs/llm.yaml.example" ] || [ ! -f "configs/notion.yaml.example" ] || [ ! -f "configs/repos.yaml.example" ]; then
    log "  ❌ configs/ 缺 .yaml.example 文件"
    exit 1
fi

echo "    ✅ 3 份 yaml 配置存在"

# === 2. 阶段 2：fetcher（dry-run）===
log "[stage-2] fetcher（dry-run: 不真调 GitHub API）"
FETCH_OUT="${DRY_DIR}/stages/issues.json"
echo '{
  "<owner>/<repo>": [
    {"id": 1, "title": "demo issue", "body_len": 1234, "comments": 5, "created_at": "2026-07-15"}
  ]
}' > "${FETCH_OUT}"
log "    ✅ fake issues 已写到 ${FETCH_OUT} (1 条)"

# === 3. 阶段 3：ranker（dry-run）===
log "[stage-3] ranker（dry-run: 不真排序）"
SCORED_OUT="${DRY_DIR}/stages/scored.json"
echo '{
  "top10": [
    {"issue_ref": "<owner>/<repo>#1", "score": 87.3, "tiebreaker_key": "<owner>/<repo>#1"}
  ]
}' > "${SCORED_OUT}"
log "    ✅ scored.json 已写（1 条 top10）"

# === 4. 阶段 4：summarizer（dry-run: 不真调 LLM）===
log "[stage-4] summarizer（dry-run: 用 fake 总结）"
SUMMARY_OUT="${DRY_DIR}/stages/summaries.json"
echo '{
  "summaries": [
    {
      "issue_ref": "<owner>/<repo>#1",
      "summary": "这是 DRY-RUN 生成的伪总结文本，用于测试流水线完整性。",
      "prompt_version": "v3",
      "prompt_hash": "dry-run-no-real-hash",
      "tokens_used": 0,
      "dry_run": true
    }
  ]
}' > "${SUMMARY_OUT}"
log "    ✅ summaries.json 已写（fake 总结）"

# === 5. 阶段 5：writer（dry-run: 不真写 Notion API）===
log "[stage-5] writer（dry-run: 模拟 Notion 200 但不真发）"
WRITER_OUT="${DRY_DIR}/stages/notion_response.json"
echo '{
  "success": [
    {"issue_ref": "<owner>/<repo>#1", "notion_page_id": "fake-page-id-dry-run"}
  ],
  "dry_run": true
}' > "${WRITER_OUT}"
log "    ✅ notion_response.json 已写（fake success）"

# === 6. 阶段 6：沉淀 ===
log "[stage-6] 沉淀"
RUN_LOG="${DRY_DIR}/run.log"
{
    echo "## gh-issue-summarizer dry run — ${DATE}"
    echo ""
    echo "阶段 1 配置加载: OK"
    echo "阶段 2 fetcher:   OK (1 条 fake issue)"
    echo "阶段 3 ranker:    OK (top10: 1 条)"
    echo "阶段 4 summarize: OK (1 条 fake 总结)"
    echo "阶段 5 writer:    OK (1 条 fake success)"
    echo ""
    echo "OK: wrote 1 issues (DRY-RUN)"
    echo ""
    echo "总耗时: < 1 秒"
    echo "真实 LLM 调用: 0 次"
    echo "真实 Notion 写: 0 次"
} > "${RUN_LOG}"
log "    ✅ run.log 已写"

# === 7. 退出 ===
log ""
log "🎉 dry-run 全程通过"
log "产物位置: ${DRY_DIR}/"
log "总退出码: 0"
exit 0
