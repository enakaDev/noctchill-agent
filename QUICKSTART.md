# ノクチル マルチエージェント開発 - クイックガイド

## システム概要

```
プロデューサー（あなた）
    ↓ 指示を出す
マネージャー（Claude Code）
    ↓ タスク分配
4人のアイドル（Claude Code × 4、並列実行）
```

## クイックスタート（WSL2ターミナル）

### 1. セットアップ

```bash
# プロジェクトディレクトリに移動
cd /home/shoot/work/noctchill-agent

# セットアップスクリプト実行
bash scripts/setup.sh
```

### 2. tmux セッション起動

```bash
# tmux セッション開始
bash scripts/start.sh
```

このコマンドでWSL2ターミナルが以下のウィンドウ構成で起動します：

```
Window 0: producer   - プロデューサー用（指示出し）
Window 1: dashboard  - ダッシュボード表示
Window 2: manager    - マネージャー Claude Code
Window 3: idols      - 4人のアイドル（4ペイン）
```

### 3. 各ウィンドウでの操作

#### Window 2: Manager（マネージャーエージェント）

```bash
# マネージャーを起動
claude

# プロンプトを貼り付け
# scripts/manager_prompt.txt の内容をコピーして貼り付け
```

マネージャーが起動すると、定期的に `queue/producer_to_manager.yaml` をチェックして指示を待機します。

#### Window 0: Producer（プロデューサー＝あなた）

```bash
# テキストエディタで指示を書き込み
nano queue/producer_to_manager.yaml

# または echo で追記
echo "task_id: test_001" >> queue/producer_to_manager.yaml
```

指示例：

```yaml
task_id: "test_001"
command: "テスト実行"
description: |
  各メンバーが test_output/ にテストファイルを作成して確認してください
deadline: "2026-02-05 16:00:00"
priority: "high"
```

#### Window 1: Dashboard（ダッシュボード）

```bash
# ダッシュボード監視
tail -f status/dashboard.md

# または VSCode で markdown プレビュー
code status/dashboard.md
```

#### Window 3: Idols（アイドルペイン）

通常、エージェント起動時に自動で Claude Code が実行されます。

4つのペインそれぞれが以下を実行：
- Pane 0: 浅倉 透
- Pane 1: 樋口 円香
- Pane 2: 福丸 小糸
- Pane 3: 市川 雛菜

## tmux 基本操作

```bash
# セッションに接続
tmux attach-session -t noctchill

# ウィンドウ切り替え
Ctrl+B, 0    # Window 0 (producer)
Ctrl+B, 1    # Window 1 (dashboard)
Ctrl+B, 2    # Window 2 (manager)
Ctrl+B, 3    # Window 3 (idols)

# Idols ウィンドウ内のペイン切り替え
Ctrl+B, ↑    # 上のペイン
Ctrl+B, ↓    # 下のペイン
Ctrl+B, ←    # 左のペイン
Ctrl+B, →    # 右のペイン

# セッション終了
tmux kill-session -t noctchill
```

## 実行ワークフロー例

### シナリオ：「テストを実行してくれ」

1. **Window 0 (Producer)**
   ```bash
   # プロデューサーが指示を書き込み
   cat > queue/producer_to_manager.yaml << 'EOF'
   task_id: "test_001"
   command: "テスト実行"
   description: "test_output フォルダにテストファイルを作成してください"
   EOF
   ```

2. **Window 2 (Manager)**
   - マネージャーが指示を検出
   - 各アイドル用タスクファイルを作成
   - 各アイドルに通知

3. **Window 3 (Idols)**
   - 4つのペインで各アイドルが並列にタスク実行
   - 各アイドルが `queue/reports/` に報告を作成

4. **Window 1 (Dashboard)**
   - ダッシュボード自動更新
   - 進捗がリアルタイム表示

## ファイル構造の確認

```bash
# プロジェクトルート表示
tree -L 2 /home/shoot/work/noctchill-agent
```

## よくある操作

### 指示を確認

```bash
cat queue/producer_to_manager.yaml
```

### 各アイドルのタスクを確認

```bash
cat queue/tasks/asahara.yaml
cat queue/tasks/higuchi.yaml
cat queue/tasks/fukumaru.yaml
cat queue/tasks/ichikawa.yaml
```

### 報告を確認

```bash
ls -la queue/reports/
cat queue/reports/asahara_report.yaml
```

### ダッシュボードを確認

```bash
cat status/dashboard.md
```

## エラーハンドリング

### マネージャーが起動しない

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

## 次のステップ

- [ ] Claude Code インストール確認
- [ ] tmux セッション起動
- [ ] マネージャー Claude Code 起動
- [ ] 初期テスト指示を実行
- [ ] 各アイドルの動作確認
- [ ] Web ダッシュボード開発（スマホ対応）

---

**準備完了！プロデューサーの指示をお待ちしています！**
