#!/bin/bash

# noctchill-agent セットアップスクリプト

set -e

PROJECT_ROOT="$(cd \"$(dirname \"$0\")/../\" && pwd)"

echo \"🎵 ノクチル マルチエージェント開発システム\"
echo \"セットアップを開始します...\"
echo \"\"

# 必須ツールチェック
echo \"📋 必須ツールの確認中...\"

if ! command -v tmux &> /dev/null; then
    echo \"❌ tmux がインストールされていません。\"
    echo \"Ubuntu: sudo apt-get install tmux\"
    exit 1
fi
echo \"✅ tmux OK\"

if ! command -v claude &> /dev/null; then
    echo \"⚠️  Claude Code がインストールされていない可能性があります。\"
    echo \"手動で以下を実行してください: npm install -g @anthropic-ai/claude-code\"
fi
echo \"✅ Claude Code 準備確認\"

# ディレクトリ確認
echo \"\"
echo \"📂 ディレクトリ構造の確認中...\"

REQUIRED_DIRS=(
    \"instructions\"
    \"queue/tasks\"
    \"queue/reports\"
    \"status\"
    \"web\"
    \"scripts\"
)

for dir in \"${REQUIRED_DIRS[@]}\"; do
    if [ ! -d \"$PROJECT_ROOT/$dir\" ]; then
        echo \"❌ ディレクトリが見つかりません: $dir\"
        exit 1
    fi
    echo \"✅ $dir\"
done

# 必須ファイル確認
echo \"\"
echo \"📄 ファイル構造の確認中...\"

REQUIRED_FILES=(
    \"instructions/manager.md\"
    \"instructions/asahara.md\"
    \"instructions/higuchi.md\"
    \"instructions/fukumaru.md\"
    \"instructions/ichikawa.md\"
    \"queue/producer_to_manager.yaml\"
    \"status/dashboard.md\"
    \"README.md\"
)

for file in \"${REQUIRED_FILES[@]}\"; do
    if [ ! -f \"$PROJECT_ROOT/$file\" ]; then
        echo \"❌ ファイルが見つかりません: $file\"
        exit 1
    fi
    echo \"✅ $file\"
done

# テスト出力ディレクトリ作成
echo \"\"
echo \"📁 ワーキングディレクトリを初期化中...\"
mkdir -p \"$PROJECT_ROOT/test_output\"
echo \"✅ test_output ディレクトリ作成\"

# .gitignore 作成（存在しない場合）
if [ ! -f \"$PROJECT_ROOT/.gitignore\" ]; then
    cat > \"$PROJECT_ROOT/.gitignore\" << 'EOF'
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
    echo \"✅ .gitignore 作成\"
else
    echo \"✅ .gitignore 既存\"
fi

echo \"\"
echo \"✨ セットアップ完了！\"
echo \"\"
echo \"次のステップ：\"
echo \"  1. WSL2 ターミナルで以下を実行\"
echo \"     cd $PROJECT_ROOT\"
echo \"  2. tmux セッション開始\"
echo \"     bash scripts/start.sh\"
echo \"\"
echo \"詳細は README.md を参照してください。\"
