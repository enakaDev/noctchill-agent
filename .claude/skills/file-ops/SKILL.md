---
name: file-ops
description: ファイル操作パターンスキル。ノクチルシステムで頻繁に使用するファイル操作のベストプラクティス
---

# File Operations Skill

ノクチルシステムで頻繁に使用するファイル操作パターン。

## 基本パス構造

```
{{NOCTCHILL_HOME}}/        # 管理ディレクトリ
├── instructions/          # キャラクター定義
├── config/               # 設定ファイル
└── scripts/              # スクリプト

{{QUEUE_DIR}}/            # インスタンス固有キュー
├── task_input.yaml       # ユーザー入力
├── tasks/                # タスクファイル
│   ├── asakura.yaml
│   ├── higuchi.yaml
│   ├── fukumaru.yaml
│   └── ichikawa.yaml
├── reports/              # レポートファイル
│   ├── asakura_report.yaml
│   ├── higuchi_report.yaml
│   ├── fukumaru_report.yaml
│   └── ichikawa_report.yaml
└── approvals/            # 承認リクエスト/レスポンス
    ├── approval_request.yaml   # プロデューサーが作成
    └── approval_response.yaml  # Webダッシュボードが作成

{{STATUS_DIR}}/           # ステータス
└── dashboard.md
```

## よくある操作パターン

### 1. タスク受信（プロデューサー）

```bash
# Read tool
{{QUEUE_DIR}}/task_input.yaml
```

### 2. インストラクション参照（必要時のみ）

```bash
# Read tool
{{NOCTCHILL_HOME}}/instructions/producer.md
{{NOCTCHILL_HOME}}/instructions/asakura.md  # 透が関係する時のみ
```

### 3. タスクYAML作成（プロデューサー）

```bash
# Write tool
{{QUEUE_DIR}}/tasks/asakura.yaml
{{QUEUE_DIR}}/tasks/higuchi.yaml
{{QUEUE_DIR}}/tasks/fukumaru.yaml
{{QUEUE_DIR}}/tasks/ichikawa.yaml
```

### 4. レポートクリア（次タスク前）

```bash
# Write tool で空ファイルに上書き（4ファイル）
# ファイルが存在しない場合は何もしない
{{QUEUE_DIR}}/reports/asakura_report.yaml
{{QUEUE_DIR}}/reports/higuchi_report.yaml
{{QUEUE_DIR}}/reports/fukumaru_report.yaml
{{QUEUE_DIR}}/reports/ichikawa_report.yaml

# 内容: 空文字列 "" で上書き
# これにより rm コマンドの実行確認を回避
```

### 5. レポート確認（プロデューサー）

```bash
# Read tool（4ファイル）
{{QUEUE_DIR}}/reports/asakura_report.yaml
{{QUEUE_DIR}}/reports/higuchi_report.yaml
{{QUEUE_DIR}}/reports/fukumaru_report.yaml
{{QUEUE_DIR}}/reports/ichikawa_report.yaml
```

### 6. ダッシュボード更新

```bash
# Write tool または Edit tool
{{STATUS_DIR}}/dashboard.md
```

### 7. タスク読込（各アイドル）

```bash
# Read tool
{{QUEUE_DIR}}/tasks/asakura.yaml  # 透の例
```

### 8. レポート作成（各アイドル）

```bash
# Write tool
{{QUEUE_DIR}}/reports/asakura_report.yaml  # 透の例
```

### 9. 承認リクエスト作成（プロデューサー）

```bash
# Write tool
{{QUEUE_DIR}}/approvals/approval_request.yaml
```

承認リクエスト YAML フォーマット:
```yaml
request_id: "approval_001"
task_id: "task_001"
type: "task_execution"  # task_execution / deployment / high_risk_change
summary: "承認が必要な操作の概要"
details: |
  詳細な説明
requested_at: "YYYY-MM-DD HH:MM:SS"
status: "pending"
```

### 10. 承認レスポンス確認（プロデューサー）

```bash
# Read tool - [APPROVED] / [REJECTED] メッセージ受信後に確認
{{QUEUE_DIR}}/approvals/approval_response.yaml
```

承認レスポンス YAML フォーマット:
```yaml
request_id: "approval_001"
decision: "approved"  # approved / rejected
decided_at: "YYYY-MM-DD HH:MM:SS"
decided_by: "web_dashboard"
```

### 11. 承認ファイルクリア（次の承認依頼前）

```bash
# Write tool で空ファイルに上書き
{{QUEUE_DIR}}/approvals/approval_request.yaml
{{QUEUE_DIR}}/approvals/approval_response.yaml
```

## ツール使用の承認ポリシー

### 承認不要（管理ファイル）

- `{{QUEUE_DIR}}/` 内の全ファイル（Read, Write, Edit, Bash rm）
- `{{STATUS_DIR}}/` 内の全ファイル（Read, Write, Edit）
- `{{NOCTCHILL_HOME}}/instructions/` 内のファイル（Read）
- `{{NOCTCHILL_HOME}}/config/` 内のファイル（Read）

### 要確認（実装ファイル）

- `{{TARGET_DIR}}/` (CWD) 内のファイル（Write, Edit）

## エラーハンドリング

### ファイルが存在しない

```bash
# タスクファイルが存在しない → エラー報告
if ! [ -f "{{QUEUE_DIR}}/tasks/asakura.yaml" ]; then
    echo "エラー: タスクファイルが見つかりません"
fi
```

### YAMLパースエラー

```yaml
# 不正なYAML → 報告でユーザーに伝える
status: "失敗"
content: |
  タスクファイルのYAMLフォーマットが不正です。
  確認してください。
```

### 複数レポートの確認

```bash
# 4ファイル全て存在するか確認
if [ -f "{{QUEUE_DIR}}/reports/asakura_report.yaml" ] && \
   [ -f "{{QUEUE_DIR}}/reports/higuchi_report.yaml" ] && \
   [ -f "{{QUEUE_DIR}}/reports/fukumaru_report.yaml" ] && \
   [ -f "{{QUEUE_DIR}}/reports/ichikawa_report.yaml" ]; then
    # 全員分揃った
else
    # まだ揃っていない → 待機
fi
```

## ベストプラクティス

1. **パスは常にプレースホルダーを使用**
   - ❌ `/data/myWork/noctchill-agent/queue/...`
   - ✅ `{{QUEUE_DIR}}/...`

2. **ファイル存在確認は Read tool で**
   - Read が失敗したらファイルが存在しない

3. **YAMLフォーマットを守る**
   - インデントは2スペース
   - `|` で複数行文字列
   - クオート不要な場合は省略

4. **タイムスタンプは正確に**
   - 形式: `YYYY-MM-DD HH:MM:SS`
   - 現在時刻を使用
