#!/bin/bash

# noctchill-agent セットアップスクリプト

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CALLER_DIR="$(pwd)"

echo "ノクチル マルチエージェント開発システム"
echo "セットアップを開始します..."
echo ""
echo "noctchill-agent: $PROJECT_ROOT"
echo "実行ディレクトリ: $CALLER_DIR"
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

# Python3 チェック（Web ダッシュボード用）
if ! command -v python3 &> /dev/null; then
    echo "[WARN] python3 がインストールされていません（Web ダッシュボードに必要）"
    echo "Ubuntu: sudo apt-get install python3 python3-pip"
else
    echo "[OK] python3"
    # Flask / PyYAML チェック
    if ! python3 -c "import flask" 2>/dev/null; then
        echo "[WARN] Flask がインストールされていません（Web ダッシュボードに必要）"
        echo "インストール: pip install flask pyyaml"
    else
        echo "[OK] flask"
    fi
fi

# inotifywait チェック（通知ウォッチャー用）
if ! command -v inotifywait &> /dev/null; then
    echo "[WARN] inotifywait がインストールされていません（ntfy通知ウォッチャーに必要）"
    echo "Ubuntu: sudo apt-get install inotify-tools"
else
    echo "[OK] inotifywait"
fi

# ディレクトリ確認
echo ""
echo "ディレクトリ構造の確認中..."

REQUIRED_DIRS=(
    "instructions"
    "instances"
    "instances/template"
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
    "instances/template/queue/task_input.yaml"
    "instances/template/status/dashboard.md"
    "scripts/prompts/producer_system.md"
    "scripts/prompts/asakura_system.md"
    "scripts/prompts/higuchi_system.md"
    "scripts/prompts/fukumaru_system.md"
    "scripts/prompts/ichikawa_system.md"
    "scripts/launch_agents.sh"
    "scripts/send_task.sh"
    "scripts/start.sh"
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
instances/*/queue/tasks/*.yaml
instances/*/queue/reports/*.yaml

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

# Claude Code 権限設定ファイルの生成
echo ""
echo "Claude Code 権限設定ファイルの生成..."

SETTINGS_FILE="$CALLER_DIR/.claude/settings.local.json"
mkdir -p "$CALLER_DIR/.claude"

# 基本権限リスト
BASE_PERMISSIONS=(
    "Bash(env)"
    "Bash(cat:*)"
    "Bash(tmux:*)"
    "Bash(do)"
    "Bash(echo:*)"
    "Bash(done)"
    "Bash(tree:*)"
    "Bash(find:*)"
    "WebFetch(domain:github.com)"
)

# noctchill-agent 用の必須権限リスト（動的にパスを構築）
# 注意: // の後にスラッシュで始まるパスを置くと /// になってしまうので、
# PROJECT_ROOT の先頭スラッシュを除去してから // と結合する
NOCTCHILL_BASE="${PROJECT_ROOT#/}"  # 先頭の / を除去
NOCTCHILL_PERMISSIONS=(
    "Edit(//${NOCTCHILL_BASE}/instances/*/queue/**)"
    "Edit(//${NOCTCHILL_BASE}/instances/*/status/**)"
    "Write(//${NOCTCHILL_BASE}/instances/*/queue/**)"
    "Write(//${NOCTCHILL_BASE}/instances/*/status/**)"
    "Read(//${NOCTCHILL_BASE}/instances/*/queue/**)"
    "Read(//${NOCTCHILL_BASE}/instances/*/status/**)"
    "Read(//${NOCTCHILL_BASE}/instructions/**)"
    "Write(//${NOCTCHILL_BASE}/instructions/**)"
    "Edit(//${NOCTCHILL_BASE}/instructions/**)"
    "Bash(rm://${NOCTCHILL_BASE}/instances/*/queue/reports/*)"
)

# すべての権限をマージ
ALL_PERMISSIONS=("${BASE_PERMISSIONS[@]}" "${NOCTCHILL_PERMISSIONS[@]}")

if command -v jq &> /dev/null; then
    echo "[OK] jq を使用して設定ファイルを生成します"

    if [ -f "$SETTINGS_FILE" ]; then
        # 既存の設定ファイルがある場合はマージ
        echo "  既存の設定ファイルにマージします"
        TEMP_FILE=$(mktemp)
        jq --argjson new_perms "$(printf '%s\n' "${ALL_PERMISSIONS[@]}" | jq -R . | jq -s .)" \
           '.permissions.allow = (.permissions.allow + $new_perms | unique)' \
           "$SETTINGS_FILE" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$SETTINGS_FILE"
        echo "[OK] 権限を追加しました: $SETTINGS_FILE"
    else
        # 新規作成
        echo "  新規に設定ファイルを作成します"
        jq -n --argjson perms "$(printf '%s\n' "${ALL_PERMISSIONS[@]}" | jq -R . | jq -s .)" \
           '{permissions: {allow: $perms, deny: [], ask: []}}' \
           > "$SETTINGS_FILE"
        echo "[OK] 設定ファイルを作成しました: $SETTINGS_FILE"
    fi
else
    echo "[WARN] jq がインストールされていません"
    echo "  手動で $SETTINGS_FILE を作成してください"
    echo ""
    echo "以下の内容を記述してください："
    echo '{'
    echo '  "permissions": {'
    echo '    "allow": ['
    for perm in "${ALL_PERMISSIONS[@]}"; do
        echo "      \"$perm\","
    done
    echo '    ],'
    echo '    "deny": [],'
    echo '    "ask": []'
    echo '  }'
    echo '}'
fi

# ntfy 設定ファイルの生成（存在しない場合）
echo ""
echo "通知設定の初期化..."

NTFY_CONF="$PROJECT_ROOT/config/ntfy.conf"
if [ ! -f "$NTFY_CONF" ]; then
    mkdir -p "$PROJECT_ROOT/config"
    cp "$PROJECT_ROOT/config/ntfy.conf.example" "$NTFY_CONF"
    echo "[OK] config/ntfy.conf を作成しました（設定が必要です）"
else
    echo "[OK] config/ntfy.conf 既存"
fi

# Web API トークンの生成（存在しない場合）
WEB_TOKEN_FILE="$PROJECT_ROOT/config/web_token"
if [ ! -f "$WEB_TOKEN_FILE" ]; then
    if command -v python3 &> /dev/null; then
        python3 -c "import secrets; print(secrets.token_urlsafe(32))" > "$WEB_TOKEN_FILE"
        echo "[OK] config/web_token を生成しました"
    else
        echo "[WARN] python3 がないため config/web_token を生成できません"
        echo "手動で以下を実行してください:"
        echo "  openssl rand -base64 32 > $WEB_TOKEN_FILE"
    fi
else
    echo "[OK] config/web_token 既存"
fi

echo ""
echo "セットアップ完了！"
echo ""
echo "次のステップ："
echo "  1. config/ntfy.conf を編集して ntfy トピックを設定"
echo "     NTFY_TOPIC に UUID などのユニークな文字列を設定してください"
echo "  2. スマートフォンに ntfy アプリをインストール"
echo "     Android/iOS: ntfy.sh アプリをダウンロードし、同じトピックを登録"
echo "  3. Tailscale のセットアップ（リモートアクセス用）"
echo "     WSL2: curl -fsSL https://tailscale.com/install.sh | sh"
echo "  4. 対象リポジトリで起動"
echo "     cd /path/to/your/project && bash $PROJECT_ROOT/scripts/start.sh"
echo "     ブラウザで http://localhost:5000 を開くと Web ダッシュボードが表示されます"
echo ""
echo "詳細は README.md を参照してください。"
