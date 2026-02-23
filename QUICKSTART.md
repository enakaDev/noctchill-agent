# ノクチル マルチエージェント開発 - クイックガイド

## システム概要

```
ユーザー（あなた）
    ↓ 指示を出す
プロデューサー（Claude Code）
    ↓ タスク分配
4人のアイドル（Claude Code × 4、並列実行）
```

## クイックスタート（WSL2ターミナル）

### 1. セットアップ

```bash
# プロジェクトディレクトリに移動
cd <your-clone-directory>

# セットアップスクリプト実行
bash scripts/setup.sh
```

### 2. tmux セッション起動

```bash
# tmux セッション開始（エージェント自動起動）
bash scripts/start.sh
```

このコマンドで tmux セッションが以下のウィンドウ構成で起動します：

```
Window 0: producer   - プロデューサー Claude Code（直接操作）
Window 1: dashboard  - ダッシュボード表示（自動更新）
Window 2: idols      - 4人のアイドル（4ペイン分割）
```

セッション名は `noctchill-<instance>` です（デフォルト: `noctchill-default`）。

#### 外部リポジトリで使う場合

```bash
# 別のリポジトリから起動（そのリポジトリを作業対象にする）
cd /path/to/your/project
/path/to/noctchill-agent/scripts/start.sh
```

### 3. 各ウィンドウでの操作

#### Window 0: Producer（プロデューサーエージェント）

プロデューサーはイベント駆動で動作します。`[TASK]` メッセージを受け取るまで待機します。

```bash
# エージェントは start.sh で自動起動されます
# 手動起動する場合:
bash scripts/launch_agents.sh
```

#### タスクの送信方法

```bash
# task_input.yaml にタスクを書き込み
nano instances/<name>/queue/task_input.yaml
```

指示例：

```yaml
task_id: "test_001"
command: "テスト実行"
description: |
  各メンバーが test_output/ にテストファイルを作成して確認してください
priority: "high"
```

書き込み後、プロデューサーの Window 0 で `[TASK]` と入力して送信します。

#### Window 1: Dashboard（ダッシュボード）

ダッシュボードは `watch` コマンドで自動更新されます。手動で確認する場合：

```bash
cat instances/<name>/status/dashboard.md
```

#### Window 2: Idols（アイドルペイン）

エージェント起動時に自動で Claude Code が実行されます。

4つのペインそれぞれが以下を担当：
- Pane 0: 浅倉 透
- Pane 1: 樋口 円香
- Pane 2: 福丸 小糸
- Pane 3: 市川 雛菜

## tmux 基本操作

```bash
# セッションに接続
tmux attach-session -t noctchill-default

# ウィンドウ切り替え
Ctrl+B, 0    # Window 0 (producer)
Ctrl+B, 1    # Window 1 (dashboard)
Ctrl+B, 2    # Window 2 (idols)

# Idols ウィンドウ内のペイン切り替え
Ctrl+B, ↑    # 上のペイン
Ctrl+B, ↓    # 下のペイン
Ctrl+B, ←    # 左のペイン
Ctrl+B, →    # 右のペイン

# セッション終了
tmux kill-session -t noctchill-default
```

## 実行ワークフロー例

### シナリオ：「テストを実行してくれ」

1. **task_input.yaml を作成**
   ```bash
   cat > instances/default/queue/task_input.yaml << 'EOF'
   task_id: "test_001"
   command: "テスト実行"
   description: "test_output フォルダにテストファイルを作成してください"
   EOF
   ```

2. **Window 0 (Producer) で `[TASK]` を送信**
   - プロデューサーが指示を検出
   - 各アイドル用タスクファイルを作成
   - 各アイドルに通知

3. **Window 2 (Idols)**
   - 4つのペインで各アイドルが並列にタスク実行
   - 各アイドルが `instances/<name>/queue/reports/` に報告を作成

4. **Window 1 (Dashboard)**
   - ダッシュボード自動更新
   - 進捗がリアルタイム表示

## よくある操作

```bash
# 指示を確認
cat instances/<name>/queue/task_input.yaml

# 各アイドルのタスクを確認
cat instances/<name>/queue/tasks/asakura.yaml

# 報告を確認
ls -la instances/<name>/queue/reports/
cat instances/<name>/queue/reports/asakura_report.yaml

# ダッシュボードを確認
cat instances/<name>/status/dashboard.md
```

※ `<name>` はインスタンス名です。デフォルトは `default` です。

## エラーハンドリング

### プロデューサーが起動しない

```bash
# Claude Code がインストールされているか確認
which claude

# インストール
npm install -g @anthropic-ai/claude-code
```

### tmux が起動しない

```bash
# tmux がインストールされているか確認
which tmux

# インストール（Ubuntu）
sudo apt-get install tmux
```

### ファイル権限エラー

```bash
# スクリプトに実行権限を付与
chmod +x scripts/*.sh
```

---

**詳細は [README.md](README.md) を参照してください。**
