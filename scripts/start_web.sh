#!/bin/bash

# noctchill-agent Web ダッシュボードサーバー起動スクリプト
# Usage: bash scripts/start_web.sh [instance_name]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

export NOCTCHILL_INSTANCE="${1:-default}"

# 認証トークンの読み込み
TOKEN_FILE="$PROJECT_ROOT/config/web_token"
if [ -f "$TOKEN_FILE" ]; then
    export NOCTCHILL_API_TOKEN="$(cat "$TOKEN_FILE")"
fi

# 依存関係チェック
if ! python3 -c "import flask" 2>/dev/null; then
    echo "Flask がインストールされていません。"
    echo "  pip install flask pyyaml"
    exit 1
fi

if ! python3 -c "import yaml" 2>/dev/null; then
    echo "PyYAML がインストールされていません。"
    echo "  pip install pyyaml"
    exit 1
fi

echo "noctchill Web Dashboard 起動中..."
echo "  Instance: $NOCTCHILL_INSTANCE"
echo ""

python3 "$PROJECT_ROOT/web/server.py" --host 0.0.0.0 --port 5000
