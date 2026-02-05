#!/bin/bash

# noctchill-agent tmux セッション起動スクリプト

PROJECT_ROOT=\"$(cd \\\"$(dirname \\\"$0\\\")/../\\\" && pwd)\"
SESSION_NAME=\"noctchill\"

echo \"🎵 ノクチル マルチエージェント開発システム\"
echo \"tmux セッション起動中...\"
echo \"\"

# 既存セッションをチェック
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo \"⚠️  セッション '$SESSION_NAME' は既に実行中です。\"
    echo \"既存セッションに接続しますか？ (y/n)\"
    read -r response
    if [ \"$response\" != \"y\" ]; then
        echo \"キャンセルしました。\"
        exit 0
    fi
    tmux attach-session -t $SESSION_NAME
    exit 0
fi

# 新規セッション作成
tmux new-session -d -s $SESSION_NAME -x 200 -y 50

# ウィンドウ構成作成
# Window 0: プロデューサー（管理画面）
tmux new-window -t $SESSION_NAME:0 -n \"producer\"
tmux send-keys -t $SESSION_NAME:0 \"cd $PROJECT_ROOT && clear\" Enter

# Window 1: ダッシュボード
tmux new-window -t $SESSION_NAME:1 -n \"dashboard\"
tmux send-keys -t $SESSION_NAME:1 \"cd $PROJECT_ROOT && clear\" Enter

# Window 2: マネージャー
tmux new-window -t $SESSION_NAME:2 -n \"manager\"
tmux send-keys -t $SESSION_NAME:2 \"cd $PROJECT_ROOT && clear\" Enter

# Window 3: アイドル実行環境
# 4つのペインを作成
tmux new-window -t $SESSION_NAME:3 -n \"idols\"

# 最初のペイン（浅倉 透）
tmux send-keys -t $SESSION_NAME:3 \"cd $PROJECT_ROOT && clear\" Enter

# 2番目のペイン（樋口 円香）
tmux split-window -h -t $SESSION_NAME:3
tmux send-keys -t $SESSION_NAME:3.1 \"cd $PROJECT_ROOT && clear\" Enter

# 3番目のペイン（福丸 小糸）
tmux split-window -v -t $SESSION_NAME:3.0
tmux send-keys -t $SESSION_NAME:3.2 \"cd $PROJECT_ROOT && clear\" Enter

# 4番目のペイン（市川 雛菜）
tmux split-window -v -t $SESSION_NAME:3.1
tmux send-keys -t $SESSION_NAME:3.3 \"cd $PROJECT_ROOT && clear\" Enter

# ペインのレイアウト設定
tmux select-layout -t $SESSION_NAME:3 tiled

# Window 0 に戻る
tmux select-window -t $SESSION_NAME:0

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
