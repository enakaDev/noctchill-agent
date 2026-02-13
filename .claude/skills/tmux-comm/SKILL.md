---
name: tmux-comm
description: Tmux通信パターンスキル。エージェント間のメッセージング、2回分割ルール、メッセージフォーマット
---

# Tmux Communication Skill

tmux send-keysを使用したエージェント間通信パターン。

## 基本ルール: 2回分割（厳守）

**必ず2回に分けて実行:**

```bash
# ❌ NG: Enter を同じ行に含める
tmux send-keys -t {{SESSION_NAME}}:2.0 "メッセージ" Enter

# ✅ OK: 必ず2回に分ける
tmux send-keys -t {{SESSION_NAME}}:2.0 "メッセージ"
tmux send-keys -t {{SESSION_NAME}}:2.0 Enter
```

**理由:** Enterを同じ行に含めると、メッセージが正しく送信されない場合がある。

## tmuxターゲット一覧

| 対象 | ターゲット | 用途 |
|------|-----------|------|
| Producer | `{{SESSION_NAME}}:0` | レポート受信 |
| Dashboard | `{{SESSION_NAME}}:1` | （通常は使用しない） |
| 浅倉 透 | `{{SESSION_NAME}}:2.0` | タスク通知 |
| 樋口 円香 | `{{SESSION_NAME}}:2.1` | タスク通知 |
| 福丸 小糸 | `{{SESSION_NAME}}:2.2` | タスク通知 |
| 市川 雛菜 | `{{SESSION_NAME}}:2.3` | タスク通知 |

## よくある通信パターン

### 1. タスク通知（プロデューサー → アイドル）

```bash
# 浅倉 透に通知
tmux send-keys -t {{SESSION_NAME}}:2.0 "[TASK] タスクが届きました"
tmux send-keys -t {{SESSION_NAME}}:2.0 Enter

# 樋口 円香に通知
tmux send-keys -t {{SESSION_NAME}}:2.1 "[TASK] タスクが届きました"
tmux send-keys -t {{SESSION_NAME}}:2.1 Enter

# 福丸 小糸に通知
tmux send-keys -t {{SESSION_NAME}}:2.2 "[TASK] タスクが届きました"
tmux send-keys -t {{SESSION_NAME}}:2.2 Enter

# 市川 雛菜に通知
tmux send-keys -t {{SESSION_NAME}}:2.3 "[TASK] タスクが届きました"
tmux send-keys -t {{SESSION_NAME}}:2.3 Enter
```

### 2. 完了報告（アイドル → プロデューサー）

```bash
# 浅倉 透からプロデューサーへ
tmux send-keys -t {{SESSION_NAME}}:0 "[REPORT:asakura] 完了"
tmux send-keys -t {{SESSION_NAME}}:0 Enter

# 樋口 円香からプロデューサーへ
tmux send-keys -t {{SESSION_NAME}}:0 "[REPORT:higuchi] 完了"
tmux send-keys -t {{SESSION_NAME}}:0 Enter

# 福丸 小糸からプロデューサーへ
tmux send-keys -t {{SESSION_NAME}}:0 "[REPORT:fukumaru] 完了"
tmux send-keys -t {{SESSION_NAME}}:0 Enter

# 市川 雛菜からプロデューサーへ
tmux send-keys -t {{SESSION_NAME}}:0 "[REPORT:ichikawa] 完了"
tmux send-keys -t {{SESSION_NAME}}:0 Enter
```

### 3. Instructions更新通知（プロデューサー → アイドル）

```bash
# 浅倉 透に更新通知
tmux send-keys -t {{SESSION_NAME}}:2.0 "[UPDATE] instructions が更新されました。{{NOCTCHILL_HOME}}/instructions/asakura.md を再読み込みしてください"
tmux send-keys -t {{SESSION_NAME}}:2.0 Enter
```

### 4. 終了処理（プロデューサー → 全アイドル）

```bash
# 全アイドルに /exit コマンド送信
tmux send-keys -t {{SESSION_NAME}}:2.0 "/exit"
tmux send-keys -t {{SESSION_NAME}}:2.0 Enter

tmux send-keys -t {{SESSION_NAME}}:2.1 "/exit"
tmux send-keys -t {{SESSION_NAME}}:2.1 Enter

tmux send-keys -t {{SESSION_NAME}}:2.2 "/exit"
tmux send-keys -t {{SESSION_NAME}}:2.2 Enter

tmux send-keys -t {{SESSION_NAME}}:2.3 "/exit"
tmux send-keys -t {{SESSION_NAME}}:2.3 Enter

# 5秒待機
sleep 5

# セッション終了
tmux kill-session -t {{SESSION_NAME}}
```

## メッセージフォーマット

### `[TASK]` - 新規タスク通知
- 送信者: プロデューサー
- 受信者: 各アイドル
- トリガー: タスクYAMLが作成された時

### `[REPORT:<name>]` - 完了報告
- 送信者: 各アイドル
- 受信者: プロデューサー
- トリガー: レポートYAMLが作成された時
- `<name>`: asakura/higuchi/fukumaru/ichikawa

### `[UPDATE]` - 設定更新通知
- 送信者: プロデューサー
- 受信者: 該当アイドル
- トリガー: instructions ファイルが更新された時

### `[FEEDBACK]` / `[FEEDBACK:<name>]` - 口調修正
- 送信者: ユーザー
- 受信者: プロデューサー
- トリガー: ユーザーが口調に違和感を覚えた時

### `[SHUTDOWN]` - システム終了
- 送信者: ユーザー
- 受信者: プロデューサー
- トリガー: システム全体を終了したい時

## 実行タイミング

### プロデューサーがsend-keysを使用するタイミング

1. **タスク分配後** - 全アイドルに `[TASK]` 通知
2. **フィードバック反映後** - 該当アイドルに `[UPDATE]` 通知
3. **終了処理時** - 全アイドルに `/exit` 送信

### アイドルがsend-keysを使用するタイミング

1. **タスク完了後** - プロデューサーに `[REPORT:<name>]` 通知

## エラーハンドリング

### セッションが存在しない

```bash
# 実行前にセッション存在確認
if ! tmux has-session -t {{SESSION_NAME}} 2>/dev/null; then
    echo "エラー: tmux セッションが見つかりません"
    exit 1
fi
```

### 2回分割を忘れた場合

メッセージが正しく送信されない可能性がある。必ず2回に分けること。

## ベストプラクティス

1. **常に2回分割**
   - これを守らないと動作が不安定になる

2. **メッセージは明確に**
   - 受信側が理解しやすいフォーマットを使用

3. **順序を守る**
   - タスクYAML作成 → send-keys の順

4. **並列送信OK**
   - 複数のアイドルへの通知は並列で実行可能

5. **エラーチェック**
   - send-keysの前にセッション存在確認
