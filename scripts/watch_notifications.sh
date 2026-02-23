#!/bin/bash

# noctchill-agent 通知ウォッチャー
# レポート完了と承認リクエストを監視し、ntfy 通知を送信する
#
# Usage: bash scripts/watch_notifications.sh [instance_name]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTANCE_NAME="${1:-default}"
QUEUE_DIR="$PROJECT_ROOT/instances/$INSTANCE_NAME/queue"
REPORTS_DIR="$QUEUE_DIR/reports"
APPROVALS_DIR="$QUEUE_DIR/approvals"

# 通知設定が存在するか確認
if [ ! -f "$PROJECT_ROOT/config/ntfy.conf" ]; then
    echo "ntfy 設定ファイルが見つかりません: config/ntfy.conf"
    echo "config/ntfy.conf.example を参考に作成してください"
    exit 1
fi

# inotifywait の存在確認
if ! command -v inotifywait &>/dev/null; then
    echo "inotifywait が見つかりません。インストールしてください:"
    echo "  sudo apt-get install inotify-tools"
    exit 1
fi

# 監視対象ディレクトリの作成（存在しない場合）
mkdir -p "$REPORTS_DIR" "$APPROVALS_DIR"

# 直前に通知した時刻（重複通知防止用）
LAST_REPORT_NOTIFY=0
LAST_APPROVAL_NOTIFY=0
NOTIFY_COOLDOWN=30  # 同じ種類の通知は30秒間隔

echo "通知ウォッチャー起動: インスタンス '$INSTANCE_NAME'"
echo "  レポート監視: $REPORTS_DIR"
echo "  承認監視:     $APPROVALS_DIR"
echo ""

# レポート完了チェック関数
check_reports() {
    local now
    now=$(date +%s)

    # クールダウン中はスキップ
    if [ $((now - LAST_REPORT_NOTIFY)) -lt $NOTIFY_COOLDOWN ]; then
        return
    fi

    # 非空のレポートファイル数をカウント
    local count=0
    for f in "$REPORTS_DIR"/*_report.yaml; do
        [ -f "$f" ] && [ -s "$f" ] && count=$((count + 1))
    done

    if [ "$count" -ge 4 ]; then
        # タスクIDを取得
        local task_id
        task_id=$(grep -m1 'task_id:' "$REPORTS_DIR/asakura_report.yaml" 2>/dev/null | sed 's/task_id: *//' | tr -d '"' || echo "unknown")

        # 失敗レポートの数をチェック
        local failures
        failures=$(grep -l 'status:.*失敗' "$REPORTS_DIR"/*_report.yaml 2>/dev/null | wc -l)

        if [ "$failures" -gt 0 ]; then
            bash "$PROJECT_ROOT/scripts/notify.sh" \
                "タスク完了（失敗あり）" \
                "[$INSTANCE_NAME] $task_id: ${failures}人が失敗を報告" \
                "high" \
                "warning"
        else
            bash "$PROJECT_ROOT/scripts/notify.sh" \
                "タスク完了" \
                "[$INSTANCE_NAME] $task_id: 全員完了" \
                "default" \
                "white_check_mark"
        fi

        LAST_REPORT_NOTIFY=$now
    fi
}

# 承認リクエストチェック関数
check_approvals() {
    local now
    now=$(date +%s)

    if [ $((now - LAST_APPROVAL_NOTIFY)) -lt $NOTIFY_COOLDOWN ]; then
        return
    fi

    local request_file="$APPROVALS_DIR/approval_request.yaml"
    local response_file="$APPROVALS_DIR/approval_response.yaml"

    # リクエストが存在し、レスポンスがまだ無い場合
    if [ -f "$request_file" ] && [ -s "$request_file" ] && [ ! -s "$response_file" ]; then
        local summary
        summary=$(grep -m1 'summary:' "$request_file" 2>/dev/null | sed 's/summary: *//' | tr -d '"' || echo "承認が必要です")

        local request_id
        request_id=$(grep -m1 'request_id:' "$request_file" 2>/dev/null | sed 's/request_id: *//' | tr -d '"' || echo "unknown")

        bash "$PROJECT_ROOT/scripts/notify.sh" \
            "承認依頼" \
            "[$INSTANCE_NAME] $summary" \
            "high" \
            "raising_hand"

        LAST_APPROVAL_NOTIFY=$now
    fi
}

# メインループ: inotifywait でファイル変更を監視
while true; do
    # reports/ と approvals/ の両方を監視
    inotifywait -q -r -e create -e modify -e moved_to \
        "$REPORTS_DIR" "$APPROVALS_DIR" \
        --timeout 60 2>/dev/null

    # タイムアウトまたはイベント発生時にチェック
    check_reports
    check_approvals
done
