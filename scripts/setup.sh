#!/bin/bash

# noctchill-agent セットアップスクリプト

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "ノクチル マルチエージェント開発システム"
echo "セットアップを開始します..."
echo ""

# 必須ツールチェック
echo "必須ツールの確認中..."

if ! command -v tmux &> /dev/null; then
    echo "[NG] tmux がインストールされていません。"
    echo "Ubuntu: sudo apt-get install tmux"
    exit 1
fi
echo "[OK] tmux"

if ! command -v claude &> /dev/null; then
    echo "[WARN] Claude Code がインストールされていない可能性があります。"
    echo "手動で以下を実行してください: npm install -g @anthropic-ai/claude-code"
else
    echo "[OK] Claude Code"
fi

# ディレクトリ確認
echo ""
echo "ディレクトリ構造の確認中..."

REQUIRED_DIRS=(
    "instructions"
    "queue/tasks"
    "queue/reports"
    "status"
    "scripts"
    "scripts/prompts"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$PROJECT_ROOT/$dir" ]; then
        echo "[NG] ディレクトリが見つかりません: $dir"
        exit 1
    fi
    echo "[OK] $dir"
done

# 必須ファイル確認
echo ""
echo "ファイル構造の確認中..."

REQUIRED_FILES=(
    "instructions/producer.md"
    "instructions/asakura.md"
    "instructions/higuchi.md"
    "instructions/fukumaru.md"
    "instructions/ichikawa.md"
    "queue/task_input.yaml"
    "status/dashboard.md"
    "scripts/prompts/producer_system.md"
    "scripts/prompts/asakura_system.md"
    "scripts/prompts/higuchi_system.md"
    "scripts/prompts/fukumaru_system.md"
    "scripts/prompts/ichikawa_system.md"
    "scripts/launch_agents.sh"
    "scripts/send_task.sh"
    "README.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$PROJECT_ROOT/$file" ]; then
        echo "[NG] ファイルが見つかりません: $file"
        exit 1
    fi
    echo "[OK] $file"
done

# テスト出力ディレクトリ作成
echo ""
echo "ワーキングディレクトリを初期化中..."
mkdir -p "$PROJECT_ROOT/test_output"
echo "[OK] test_output ディレクトリ作成"

# .gitignore 作成（存在しない場合）
if [ ! -f "$PROJECT_ROOT/.gitignore" ]; then
    cat > "$PROJECT_ROOT/.gitignore" << 'EOF'
# テスト成果物
test_output/

# ローカルテスト用ファイル
*.local.yaml
queue/tasks/*.yaml
queue/reports/*.yaml

# Node.js
node_modules/
.env.local

# IDE
.vscode/settings.json
.idea/

# macOS
.DS_Store
EOF
    echo "[OK] .gitignore 作成"
else
    echo "[OK] .gitignore 既存"
fi

echo ""
echo "セットアップ完了！"
echo ""
echo "次のステップ："
echo "  1. tmux セッション起動（エージェント自動起動）"
echo "     bash scripts/start.sh"
echo "  2. エージェントなしで起動する場合"
echo "     bash scripts/start.sh --no-agents"
echo ""
echo "詳細は README.md を参照してください。"
