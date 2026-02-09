#!/bin/bash

# ノクチル タスク送信スクリプト
# YAMLファイルを task_input.yaml に書き込み、プロデューサーに通知する
#
# 使い方:
#   bash scripts/send_task.sh <task.yaml>   # YAMLファイルを指定して送信
#   bash scripts/send_task.sh               # エディタで直接編集して送信
#
# プロデューサーの Claude Code に直接 [TASK] メッセージを送信します。

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# インスタンス名の検出（環境変数または引数から）
INSTANCE_NAME="${NOCTCHILL_INSTANCE:-}"

# インスタンス名が未設定の場合、実行中のセッションを探す
if [ -z "$INSTANCE_NAME" ]; then
    # tmuxセッション一覧から noctchill-* を探す
    SESSIONS=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^noctchill-' || true)
    SESSION_COUNT=$(echo "$SESSIONS" | grep -c '^noctchill-' || echo 0)

    if [ "$SESSION_COUNT" -eq 0 ]; then
        echo "エラー: noctchillセッションが見つかりません"
        exit 1
    elif [ "$SESSION_COUNT" -eq 1 ]; then
        # 1つだけの場合、それを使う
        SESSION_NAME="$SESSIONS"
        INSTANCE_NAME="${SESSION_NAME#noctchill-}"
    else
        # 複数ある場合、選択させる
        echo "複数のnoctchillインスタンスが実行中です:"
        echo "$SESSIONS" | nl
        echo ""
        echo -n "インスタンス名を入力してください: "
        read -r INSTANCE_NAME
        SESSION_NAME="noctchill-$INSTANCE_NAME"
    fi
else
    SESSION_NAME="noctchill-$INSTANCE_NAME"
fi

QUEUE_DIR="$PROJECT_ROOT/instances/$INSTANCE_NAME/queue"
TASK_FILE="$QUEUE_DIR/task_input.yaml"

# セッション存在チェック
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "エラー: tmux セッション '$SESSION_NAME' が見つかりません"
    exit 1
fi

if [ -n "$1" ]; then
    # 引数でYAMLファイルが指定された場合
    if [ ! -f "$1" ]; then
        echo "エラー: ファイルが見つかりません: $1"
        exit 1
    fi
    cp "$1" "$TASK_FILE"
    echo "タスクファイルをコピーしました: $1 -> $TASK_FILE"
else
    # 引数なしの場合、エディタで編集
    EDITOR="${EDITOR:-vi}"
    # テンプレートを書き込み
    cat > "$TASK_FILE" << 'EOF'
task_id: "task_001"
command: "タスクの概要をここに"
description: |
  詳細な説明をここに記述してください。
deadline: "2026-02-07 18:00:00"
priority: "high"
notes: ""
EOF
    echo "エディタでタスクを編集してください..."
    "$EDITOR" "$TASK_FILE"

    # 編集がキャンセルされたかチェック
    if [ ! -s "$TASK_FILE" ]; then
        echo "タスクが空です。送信をキャンセルしました。"
        exit 1
    fi
fi

echo ""
echo "送信するタスク:"
echo "---"
cat "$TASK_FILE"
echo "---"
echo ""
echo "⚠️  注意：プロデューサーはこのタスクを直接実行しません"
echo "    タスクは4人のアイドル（浅倉透、樋口円香、福丸小糸、市川雛菜）に分配されます"
echo ""

# プロデューサーに通知（Window 0 = producer）
tmux send-keys -t "$SESSION_NAME:0" "[TASK] 新しいタスクが届きました。$TASK_FILE を確認してください。"
tmux send-keys -t "$SESSION_NAME:0" Enter

echo "プロデューサーに通知しました"
