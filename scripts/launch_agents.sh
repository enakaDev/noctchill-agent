#!/bin/bash

# ノクチル エージェント一括起動スクリプト
# 各 tmux ペインで Claude Code をシステムプロンプト付きで起動します

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROMPT_DIR="$PROJECT_ROOT/scripts/prompts"

# 引数: TARGET_DIR と INSTANCE_NAME
TARGET_DIR="${1:-$PROJECT_ROOT}"
INSTANCE_NAME="${2:-default}"

# インスタンス固有の変数
SESSION_NAME="noctchill-$INSTANCE_NAME"
QUEUE_DIR="$PROJECT_ROOT/instances/$INSTANCE_NAME/queue"
STATUS_DIR="$PROJECT_ROOT/instances/$INSTANCE_NAME/status"

# セッション存在チェック
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "エラー: tmux セッション '$SESSION_NAME' が見つかりません"
    echo "先に scripts/start.sh を実行してください"
    exit 1
fi

# プロンプトファイル存在チェック
for prompt_file in producer_system.md asakura_system.md higuchi_system.md fukumaru_system.md ichikawa_system.md; do
    if [ ! -f "$PROMPT_DIR/$prompt_file" ]; then
        echo "エラー: プロンプトファイルが見つかりません: $PROMPT_DIR/$prompt_file"
        exit 1
    fi
done

# プロンプト内のプレースホルダーを実際のパスに置換して返す
resolve_prompt() {
    local prompt_file="$1"
    sed "s|{{NOCTCHILL_HOME}}|$PROJECT_ROOT|g; \
         s|{{TARGET_DIR}}|$TARGET_DIR|g; \
         s|{{QUEUE_DIR}}|$QUEUE_DIR|g; \
         s|{{STATUS_DIR}}|$STATUS_DIR|g; \
         s|{{SESSION_NAME}}|$SESSION_NAME|g" "$prompt_file"
}

echo "エージェント起動中..."
echo "  管理ディレクトリ: $PROJECT_ROOT"
echo "  対象リポジトリ:   $TARGET_DIR"
echo ""

# Producer (Window 0)
echo "  プロデューサー起動中..."
tmux send-keys -t "$SESSION_NAME:0" "claude --system-prompt \"\$(sed 's|{{NOCTCHILL_HOME}}|$PROJECT_ROOT|g; s|{{TARGET_DIR}}|$TARGET_DIR|g; s|{{QUEUE_DIR}}|$QUEUE_DIR|g; s|{{STATUS_DIR}}|$STATUS_DIR|g; s|{{SESSION_NAME}}|$SESSION_NAME|g' $PROMPT_DIR/producer_system.md)\""
tmux send-keys -t "$SESSION_NAME:0" Enter
sleep 3

# Asakura (Window 2, Pane 0)
echo "  浅倉 透 起動中..."
tmux send-keys -t "$SESSION_NAME:2.0" "claude --system-prompt \"\$(sed 's|{{NOCTCHILL_HOME}}|$PROJECT_ROOT|g; s|{{TARGET_DIR}}|$TARGET_DIR|g; s|{{QUEUE_DIR}}|$QUEUE_DIR|g; s|{{STATUS_DIR}}|$STATUS_DIR|g; s|{{SESSION_NAME}}|$SESSION_NAME|g' $PROMPT_DIR/asakura_system.md)\""
tmux send-keys -t "$SESSION_NAME:2.0" Enter
sleep 2

# Higuchi (Window 2, Pane 1)
echo "  樋口 円香 起動中..."
tmux send-keys -t "$SESSION_NAME:2.1" "claude --system-prompt \"\$(sed 's|{{NOCTCHILL_HOME}}|$PROJECT_ROOT|g; s|{{TARGET_DIR}}|$TARGET_DIR|g; s|{{QUEUE_DIR}}|$QUEUE_DIR|g; s|{{STATUS_DIR}}|$STATUS_DIR|g; s|{{SESSION_NAME}}|$SESSION_NAME|g' $PROMPT_DIR/higuchi_system.md)\""
tmux send-keys -t "$SESSION_NAME:2.1" Enter
sleep 2

# Fukumaru (Window 2, Pane 2)
echo "  福丸 小糸 起動中..."
tmux send-keys -t "$SESSION_NAME:2.2" "claude --system-prompt \"\$(sed 's|{{NOCTCHILL_HOME}}|$PROJECT_ROOT|g; s|{{TARGET_DIR}}|$TARGET_DIR|g; s|{{QUEUE_DIR}}|$QUEUE_DIR|g; s|{{STATUS_DIR}}|$STATUS_DIR|g; s|{{SESSION_NAME}}|$SESSION_NAME|g' $PROMPT_DIR/fukumaru_system.md)\""
tmux send-keys -t "$SESSION_NAME:2.2" Enter
sleep 2

# Ichikawa (Window 2, Pane 3)
echo "  市川 雛菜 起動中..."
tmux send-keys -t "$SESSION_NAME:2.3" "claude --system-prompt \"\$(sed 's|{{NOCTCHILL_HOME}}|$PROJECT_ROOT|g; s|{{TARGET_DIR}}|$TARGET_DIR|g; s|{{QUEUE_DIR}}|$QUEUE_DIR|g; s|{{STATUS_DIR}}|$STATUS_DIR|g; s|{{SESSION_NAME}}|$SESSION_NAME|g' $PROMPT_DIR/ichikawa_system.md)\""
tmux send-keys -t "$SESSION_NAME:2.3" Enter

echo ""
echo "全エージェント起動完了"
echo ""
echo "ペイン構成："
echo "  Window 0: プロデューサー（直接操作）"
echo "  Window 2.0: 浅倉 透"
echo "  Window 2.1: 樋口 円香"
echo "  Window 2.2: 福丸 小糸"
echo "  Window 2.3: 市川 雛菜"
echo ""
echo "プロデューサーに直接 [TASK] メッセージを入力してタスクを開始できます"
