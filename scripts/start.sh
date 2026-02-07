#!/bin/bash

# noctchill-agent tmux セッション起動スクリプト

SESSION_NAME="noctchill"
PROJECT_ROOT=$(pwd)

echo \"🎵 ノクチル マルチエージェント開発システム\"
echo \"tmux セッション起動中...\"
echo \"\"

# 既存セッションをチェック
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo \"⚠️  セッション '$SESSION_NAME' は既に実行中です。\"
    echo \"既存セッションに接続しますか？ \(y/n\)\"
    read -r response
    if [ \"$response\" != \"y\" ]; then
        echo \"キャンセルしました。\"
        exit 0
    fi
    tmux attach-session -t $SESSION_NAME
    exit 0
fi

# 1. 新規セッション作成 
# 最初から Window 0 を "producer" という名前で作成し、ディレクトリも指定します
tmux new-session -d -s $SESSION_NAME -n "producer" -c "$PROJECT_ROOT" -x 200 -y 50

# Window 0 で初期コマンド実行
tmux send-keys -t $SESSION_NAME:0 "clear" Enter

# 2. Window 1: ダッシュボード
tmux new-window -t $SESSION_NAME:1 -n "dashboard" -c "$PROJECT_ROOT"
tmux send-keys -t $SESSION_NAME:1 "clear" Enter

# 3. Window 2: マネージャー
tmux new-window -t $SESSION_NAME:2 -n "manager" -c "$PROJECT_ROOT"
tmux send-keys -t $SESSION_NAME:2 "clear" Enter

# 4. Window 3: アイドル実行環境（4分割）
tmux new-window -t $SESSION_NAME:3 -n "idols" -c "$PROJECT_ROOT"

# ペイン分割のロジック
# 最初（左上：浅倉 透）
tmux send-keys -t $SESSION_NAME:3.0 "clear; echo '--- 浅倉 透 ---'" Enter

# 右に分割（右上：樋口 円香）
tmux split-window -h -t $SESSION_NAME:3.0 -c "$PROJECT_ROOT"
tmux send-keys -t $SESSION_NAME:3.1 "clear; echo '--- 樋口 円香 ---'" Enter

# 左側を下に分割（左下：福丸 小糸）
tmux split-window -v -t $SESSION_NAME:3.0 -c "$PROJECT_ROOT"
tmux send-keys -t $SESSION_NAME:3.2 "clear; echo '--- 福丸 小糸 ---'" Enter

# 右側を下に分割（右下：市川 雛菜）
tmux split-window -v -t $SESSION_NAME:3.1 -c "$PROJECT_ROOT"
tmux send-keys -t $SESSION_NAME:3.3 "clear; echo '--- 市川 雛菜 ---'" Enter

# レイアウトを整えて、最初の画面に戻る
tmux select-layout -t $SESSION_NAME:3 tiled
tmux select-window -t $SESSION_NAME:0

# セッションにアタッチ
tmux attach-session -t $SESSION_NAME

echo \"✅ tmux セッション '$SESSION_NAME' を作成しました\"
echo \"\"
echo \"📊 ウィンドウ構成：\"
echo \"  0: producer   - プロデューサー用（管理画面）\"
echo \"  1: dashboard  - ダッシュボード表示\"
echo \"  2: manager    - マネージャー Claude Code\"
echo \"  3: idols      - 4人のアイドル（4ペイン分割）\"
echo \"\"
echo \"🚀 セッションに接続中...\"
echo \"\"

tmux attach-session -t $SESSION_NAME
