#!/bin/bash

# noctchill-agent tmux セッション起動スクリプト

SESSION_NAME="noctchill"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CALLER_DIR="$(pwd)"
TARGET_DIR=""
WITH_AGENTS=true

# オプション解析
while [[ "$1" =~ ^-- ]]; do
    case "$1" in
        --no-agents)
            WITH_AGENTS=false
            shift
            ;;
        --target)
            TARGET_DIR="$2"
            shift 2
            ;;
        *)
            echo "不明なオプション: $1"
            exit 1
            ;;
    esac
done

# TARGET_DIR のデフォルト: start.sh を実行したディレクトリ
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$CALLER_DIR"
fi

# TARGET_DIR を絶対パスに正規化
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "ノクチル マルチエージェント開発システム"
echo "tmux セッション起動中..."
echo ""
echo "管理ディレクトリ: $PROJECT_ROOT"
echo "対象リポジトリ:   $TARGET_DIR"
echo ""

# 既存セッションをチェック
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "セッション '$SESSION_NAME' は既に実行中です。"
    echo "既存セッションに接続しますか？ (y/n)"
    read -r response
    if [ "$response" != "y" ]; then
        echo "キャンセルしました。"
        exit 0
    fi
    tmux attach-session -t "$SESSION_NAME"
    exit 0
fi

# 1. Window 0: プロデューサー（ユーザーが直接操作）— CWD は対象リポジトリ
tmux new-session -d -s "$SESSION_NAME" -n "producer" -c "$TARGET_DIR" -x 200 -y 50
tmux send-keys -t "$SESSION_NAME:0" "clear" Enter

# 2. Window 1: ダッシュボード（絶対パスで参照）
tmux new-window -t "$SESSION_NAME:1" -n "dashboard" -c "$TARGET_DIR"
tmux send-keys -t "$SESSION_NAME:1" "watch -n 2 cat $PROJECT_ROOT/status/dashboard.md" Enter

# 3. Window 2: アイドル実行環境（4分割）— CWD は対象リポジトリ
tmux new-window -t "$SESSION_NAME:2" -n "idols" -c "$TARGET_DIR"

# ペイン分割のロジック
# 最初（左上：浅倉 透）
tmux send-keys -t "$SESSION_NAME:2.0" "clear; echo '--- 浅倉 透 ---'" Enter

# 右に分割（右上：樋口 円香）
tmux split-window -h -t "$SESSION_NAME:2.0" -c "$TARGET_DIR"
tmux send-keys -t "$SESSION_NAME:2.1" "clear; echo '--- 樋口 円香 ---'" Enter

# 左側を下に分割（左下：福丸 小糸）
tmux split-window -v -t "$SESSION_NAME:2.0" -c "$TARGET_DIR"
tmux send-keys -t "$SESSION_NAME:2.2" "clear; echo '--- 福丸 小糸 ---'" Enter

# 右側を下に分割（右下：市川 雛菜）
tmux split-window -v -t "$SESSION_NAME:2.1" -c "$TARGET_DIR"
tmux send-keys -t "$SESSION_NAME:2.3" "clear; echo '--- 市川 雛菜 ---'" Enter

# レイアウトを整えて、プロデューサー画面に戻る
tmux select-layout -t "$SESSION_NAME:2" tiled
tmux select-window -t "$SESSION_NAME:0"

echo "tmux セッション '$SESSION_NAME' を作成しました"
echo ""
echo "ウィンドウ構成："
echo "  0: producer   - プロデューサー Claude Code（直接操作）"
echo "  1: dashboard  - ダッシュボード表示（自動更新）"
echo "  2: idols      - 4人のアイドル（4ペイン分割）"
echo ""

# エージェント自動起動（デフォルト）
if [ "$WITH_AGENTS" = true ]; then
    echo "エージェント自動起動中..."
    bash "$PROJECT_ROOT/scripts/launch_agents.sh" "$TARGET_DIR"
    echo ""
fi

echo "セッションに接続中..."
tmux attach-session -t "$SESSION_NAME"
