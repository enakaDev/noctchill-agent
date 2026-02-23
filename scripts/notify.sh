#!/bin/bash

# noctchill-agent ntfy 通知ヘルパー
# Usage: bash scripts/notify.sh <title> <message> [priority] [tags] [click_url]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 設定ファイル読み込み
NTFY_CONFIG="$PROJECT_ROOT/config/ntfy.conf"
if [ -f "$NTFY_CONFIG" ]; then
    source "$NTFY_CONFIG"
fi

NTFY_URL="${NTFY_URL:-https://ntfy.sh}"
NTFY_TOPIC="${NTFY_TOPIC:-}"
NTFY_TOKEN="${NTFY_TOKEN:-}"

# トピック未設定ならサイレントに終了（通知無効）
if [ -z "$NTFY_TOPIC" ]; then
    exit 0
fi

TITLE="${1:-noctchill}"
MESSAGE="${2:-}"
PRIORITY="${3:-default}"  # min, low, default, high, urgent
TAGS="${4:-}"             # emoji tags: white_check_mark, warning, inbox_tray 等
CLICK_URL="${5:-${DASHBOARD_URL:-}}"

# curl コマンド組み立て
CURL_ARGS=(
    -s
    -H "Title: $TITLE"
    -H "Priority: $PRIORITY"
)

if [ -n "$TAGS" ]; then
    CURL_ARGS+=(-H "Tags: $TAGS")
fi

if [ -n "$NTFY_TOKEN" ]; then
    CURL_ARGS+=(-H "Authorization: Bearer $NTFY_TOKEN")
fi

if [ -n "$CLICK_URL" ]; then
    CURL_ARGS+=(-H "Click: $CLICK_URL")
fi

# バックグラウンドで送信（呼び出し元をブロックしない）
curl "${CURL_ARGS[@]}" -d "$MESSAGE" "$NTFY_URL/$NTFY_TOPIC" &>/dev/null &
