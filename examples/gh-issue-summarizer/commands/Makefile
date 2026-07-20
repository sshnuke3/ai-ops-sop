# Makefile —— gh-issue-summarizer 的命令入口
#
# 这是"教学示例"的 Makefile —— 演示一份合格的 Make 长什么样。
# 【填法】8 个 target · 每个 target 配套红线校验 · 退出码 0 唯一判据
# 【为什么这样写】AGENTS.md / spec.md / red_lines.yaml 都引用了命令，
# 没这份 Makefile = 文档引用了不存在的命令 = 命令引用断链 = AI 一跑就崩
#
# 使用方式：
#   cp -r examples/gh-issue-summarizer/ /path/to/your-project/
#   cd /path/to/your-project/
#   make doctor          # 验证 3 个 API 联通
#
# === 本 Makefile 示例特意展示的 5 件事 ===
# 1. target 名字跟文档里引用的命令完全一致（`make doctor` 不是 `make check`）
# 2. 每个 target 都 .PHONY（避免文件名冲突）
# 3. 每个 target 退出码由 bash 严格传递，`set -e` 不让中间步骤吞失败
# 4. 危险 target（如 clean）要求 FORCE=yes 才执行（防 rm -rf 误伤）
# 5. .DEFAULT_GOAL 明确，避免 `make` 单独跑出意外 target

# === 基础配置 ===
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

# === Phony target 声明 ===
.PHONY: help doctor run-once-dry test build validate-config verify-prompts lint-config clean

# === help target（默认）===
# 显示所有可用的 target + 一句话说明
help:  ## 显示本帮助
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n\nTargets:\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "Example workflow:"
	@echo "  1. make doctor            # 验证环境/API 联通"
	@echo "  2. make test              # 跑单元测试"
	@echo "  3. make run-once-dry      # 干跑一次，看完整流水线"
	@echo "  4. make verify-prompts    # 验证 prompt hash sidecar"
	@echo "  5. (部署时) make build"

# === doctor：环境 + 3 个 API 联通检查 ===
# AGENTS.md §1 第 3 步、§5 沉淀动作、spec.md §0 入场自检清单都引用此命令
# 【填法】检查 3 件事：(1) env vars 非空 (2) yaml 配置 schema 合法 (3) 3 个 API 联通
# 【为什么这样写】每个 API check 单独跑 + 单独报 OK/FAIL，让维护者秒看懂哪条断了
doctor:  ## 检查 3 个 API + 配置 schema + env vars
	@echo "🔍 doctor: 环境自检"
	@echo ""
	@echo "1. env vars:"
	@for var in GH_TOKEN LLM_API_KEY NOTION_API_KEY; do \
		if [ -z "$${!var:-}" ]; then \
			echo "   ❌ $$var 未设置"; \
			exit 1; \
		else \
			echo "   ✅ $$var 已设置"; \
		fi; \
	done
	@echo ""
	@echo "2. yaml schema 校验:"
	@if command -v yamllint >/dev/null 2>&1; then \
		yamllint -d "{extends: default, rules: {line-length: disable}}" configs/*.yaml.example; \
		echo "   ✅ yaml schema 合法"; \
	else \
		echo "   ⚠️  yamllint 未安装，跳过（建议: pip install yamllint）"; \
	fi
	@echo ""
	@echo "3. 3 个 API 联通（演示代码层，真实项目里实现）："
	@echo "   （demo 级别：本示例项目无真实 Go 代码，此步仅打印示意）"
	@echo "   真实实现见项目代码 internal/fetcher/probe.go 同构检查"

# === test：单元测试 ===
# red_lines.yaml RL-15 / .agent-rules §ci_hooks.pre_commit 都引用
test:  ## 跑单元测试（go test ./...）
	@echo "🧪 test: 单元测试"
	@if [ -f go.mod ]; then \
		go test ./...; \
	else \
		echo "   ⚠️  go.mod 不存在（demo 级，跳过——真项目会跑 go test ./...）"; \
	fi

# === test-strict：严格测试（CI pre-push 用）===
# .agent-rules §ci_hooks.pre_push 引用
test-strict:  ## 严格测试（race + 多次跑）
	@echo "🧪 test-strict: race + count=2"
	@if [ -f go.mod ]; then \
		go test ./... -race -count=2; \
	else \
		echo "   ⚠️  go.mod 不存在（demo 级，跳过）"; \
	fi

# === build：编译 ===
# red_lines.yaml RL-15 引用
build:  ## 编译（go build）
	@echo "🔨 build: 编译"
	@if [ -f go.mod ]; then \
		go build -o bin/gh-issue-summarizer ./cmd/gh-issue-summarizer; \
	else \
		echo "   ⚠️  go.mod 不存在（demo 级，跳过）"; \
	fi

# === validate-config：配置 schema 验证 ===
# red_lines.yaml RL-60 / task-001 阶段 1 都引用
# 真项目会有 cmd/config-validator/main.go；这里给演示用 echo + yaml 简单校验
validate-config:  ## 配置 schema 验证（go run ./cmd/config-validator）
	@echo "📋 validate-config: 配置 schema"
	@if [ -f cmd/config-validator/main.go ]; then \
		go run ./cmd/config-validator; \
	else \
		echo "   ⚠️  cmd/config-validator/main.go 不存在（demo 级）"; \
		echo "   真实项目里此步跑 schema 校验，退出码 0 才算 PASS"; \
	fi

# === verify-prompts：prompt hash sidecar 校验 ===
# prompts/README.md + AGENTS.md 引用的 sha256sum -c 流程
verify-prompts:  ## 校验 prompt hash sidecar 一致性
	@echo "🔐 verify-prompts: hash 校验"
	@cd prompts && for sf in *.sha256; do \
		if [ -f "$$sf" ]; then \
			echo "   验证 $$sf ..."; \
			sha256sum -c "$$sf" || exit 1; \
		fi; \
	done
	@echo "   ✅ 所有 prompt hash 一致"

# === lint-config：yaml 配置 lint ===
# .agent-rules §ci_hooks.pre_commit 引用
lint-config:  ## lint yaml 配置文件
	@echo "🧹 lint-config: yaml 配置"
	@if command -v yamllint >/dev/null 2>&1; then \
		yamllint -d "{extends: default, rules: {line-length: disable}}" configs/*.yaml.example; \
	else \
		echo "   ⚠️  yamllint 未安装，跳过"; \
		echo "   安装: pip install yamllint 或 brew install yamllint"; \
	fi

# === run-once-dry：干跑一次完整流水线（不真写）===
# .agent-rules §ci_hooks.pre_push 引用
run-once-dry:  ## 干跑一次（不真写 Notion / 不真调 LLM，仅 trace + cost 估算）
	@echo "🏃 run-once-dry: 干跑"
	@echo "   ⚠️  demo 级：本示例项目无真实 main.go"
	@echo "   真实项目里此步："
	@echo "     - 加载配置但不验真凭证"
	@echo "     - 调 fetcher 但截断到 1 条 issue"
	@echo "     - 调 LLM 但用 'dry-run' 模型（NoOp）"
	@echo "     - 写 Notion API 但立刻撤回"
	@echo "     - 全程写 runs/<date>-dry/ 目录"
	@echo ""
	@echo "   真实示例（go run + dry-run 标志）:"
	@echo "     go run ./cmd/gh-issue-summarizer --dry-run"
	@echo ""
	@echo "   退出码 0 = 全程没出错（包括 dry-run 内部断言）"

# === clean：清理产物 ===
# 【填法】clean 用 FORCE=yes 保护，避免 `make clean` 误删
# 【为什么这样写】spec/AGENTS.md §2 反向护栏"含 rm -rf 必须停下"在 Makefile 同样适用
clean:  ## 清理产物（需 FORCE=yes 才执行）
	@if [ "$${FORCE:-}" != "yes" ]; then \
		echo "⚠️  clean 是危险操作，需 FORCE=yes 才执行"; \
		echo "    make clean FORCE=yes"; \
		exit 1; \
	fi
	@echo "🧹 clean: 清理"
	@rm -rf bin/ runs/ configs/*.local.yaml
	@echo "   清理完成（注意：prompts/ 的 .sha256 sidecar 没删——hash 是资产不删）"
