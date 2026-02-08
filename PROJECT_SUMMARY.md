# 🎵 ノクチル マルチエージェント開発システム - プロジェクト概要

**作成日**: 2026年2月5日  
**プロジェクト名**: noctchill-agent  
**ステータス**: Phase 1 完了、Phase 2 準備中

---

## 📌 プロジェクト概要

このプロジェクトは、**アイドルマスター シャイニーカラーズ**のユニット「**ノクチル**」をモチーフにしたAIマルチエージェント開発フレームワークです。

### 🎯 ビジョン

ユーザーが指示を出すだけで、AIプロデューサーが4人のアイドルにタスクを分配し、**スマホからもリアルタイムで進捗を確認**でき、**出先からでも開発が進められる**システムの実現。

### 💡 参考元

- [元記事](https://zenn.dev/shio_shoppaize/articles/5fee11d03a11a1) - おしお著「Claude Codeで『AI部下10人』を作ったら...」
- 戦国時代の軍制をモチーフにした階層構造
- tmux + Claude Code によるマルチエージェント実装

---

## 🎭 キャスト（エージェント）

### 階層構造

```
ユーザー（あなた）
    ↓ 「XXXをしてくれ」
プロデューサー（Claude Code）
    ↓ 「浅倉、テストして」「円香、デザイン考えて」...
┌──┬──┬──┬──┐
浅倉透 │ 樋口円香 │ 福丸小糸 │ 市川雛菜
（並列実行）
```

### 各ロール

| ロール | 名前 | 性質 | 得意分野 |
|--------|------|------|--------|
| **プロデューサー** | - | 戦略家 | タスク分解、全体統括 |
| **浅倉 透** | リーダー | 落ち着き、判断力 | チーム調整、品質基準設定 |
| **樋口 円香** | ムードメーカー | 前向き、創意工夫 | アイデア出し、UI/UX提案 |
| **福丸 小糸** | 完璧主義者 | 細心、こだわり | テスト、品質管理、校正 |
| **市川 雛菜** | 献身的 | 勤勉、安定感 | 実装、ドキュメント作成 |

---

## 📁 ファイル構成

```
noctchill-agent/
├── 📄 README.md                    # プロジェクト説明（詳細版）
├── 📄 QUICKSTART.md                # クイックスタートガイド
├── 📄 ROADMAP.md                   # 実装ロードマップ
├── 📄 PROJECT_SUMMARY.md           # このファイル
│
├── 📂 instructions/                # 各ロール用の指示書
│   ├── producer.md                  # プロデューサー役割定義
│   ├── asakura.md                  # 浅倉 透の役割定義
│   ├── higuchi.md                  # 樋口 円香の役割定義
│   ├── fukumaru.md                 # 福丸 小糸の役割定義
│   └── ichikawa.md                 # 市川 雛菜の役割定義
│
├── 📂 queue/                       # タスク・報告ファイル
│   ├── task_input.yaml             # ユーザー → プロデューサー指示
│   ├── 📂 tasks/                   # プロデューサー → 各アイドル タスク
│   │   ├── asakura.yaml
│   │   ├── higuchi.yaml
│   │   ├── fukumaru.yaml
│   │   └── ichikawa.yaml
│   └── 📂 reports/                 # 各アイドル → プロデューサー 報告
│       ├── asakura_report.yaml
│       ├── higuchi_report.yaml
│       ├── fukumaru_report.yaml
│       └── ichikawa_report.yaml
│
├── 📂 status/                      # システム状態
│   └── dashboard.md                # 進捗ダッシュボード
│
├── 📂 scripts/                     # ツール・スクリプト
│   ├── setup.sh                    # セットアップスクリプト
│   ├── start.sh                    # tmux セッション起動
│   ├── launch_agents.sh            # エージェント一括起動
│   ├── send_task.sh                # タスク送信ヘルパー
│   └── prompts/                    # Claude Code 用システムプロンプト
│
├── 📂 web/                         # Webダッシュボード（実装予定）
│   └── （実装ディレクトリ）
│
└── 📂 .git/                        # Git リポジトリ
```

---

## 🚀 Phase 1 完了内容

✅ **基本構造構築**
- プロジェクトディレクトリ完全構成
- 5つの詳細な役割定義書作成（producer + 4 アイドル）
- YAML ベースの通信フォーマット設計

✅ **ドキュメント整備**
- README.md - プロジェクト概要・使い方（詳細版）
- QUICKSTART.md - すぐに始められるガイド
- ROADMAP.md - 実装計画・ロードマップ
- 各ロール用の役割定義・プロンプト

✅ **ツール・スクリプト**
- setup.sh - 環境セットアップスクリプト
- start.sh - tmux セッション自動構成スクリプト
- launch_agents.sh - エージェント一括起動
- send_task.sh - タスク送信ヘルパー

✅ **Git 初期化**
- git リポジトリ初期化
- 初期コミット完了

---

## 📋 Phase 2 実装予定（マルチエージェント本体）

### プロデューサーエージェント（Claude Code）

```
機能:
1. task_input.yaml を監視
2. ユーザーからの指示を読み込む
3. タスクを分析・分解
4. 各アイドル用タスクファイル自動生成
5. tmux send-keys で各アイドルを起動
6. queue/reports/ から報告を集約
7. status/dashboard.md を自動更新
8. エラーハンドリング
```

### 4人のアイドルエージェント（Claude Code × 4）

各アイドルが並列で動作：

```
浅倉 透（pane 0）
  ├─ queue/tasks/asakura.yaml 監視
  ├─ リーダーシップベースのタスク処理
  └─ queue/reports/asakura_report.yaml に報告

樋口 円香（pane 1）
  ├─ queue/tasks/higuchi.yaml 監視
  ├─ 創意工夫のプロンプティング
  └─ queue/reports/higuchi_report.yaml に報告

福丸 小糸（pane 2）
  ├─ queue/tasks/fukumaru.yaml 監視
  ├─ 品質チェック・テスト実行
  └─ queue/reports/fukumaru_report.yaml に報告

市川 雛菜（pane 3）
  ├─ queue/tasks/ichikawa.yaml 監視
  ├─ ドキュメント生成・データ処理
  └─ queue/reports/ichikawa_report.yaml に報告
```

---

## 📊 Phase 3 実装予定（Webダッシュボード）

### バックエンド（Node.js/Express）
- REST API
- WebSocket リアルタイム通知
- ファイルウォッチャー
- YAML パーサー

### フロントエンド（React）
- ダッシュボード表示
- リアルタイム更新
- タスク指示インターフェース
- レスポンシブデザイン（スマホ対応）

### 機能
- スマホから進捗確認
- リアルタイムで各アイドルのステータス表示
- 出先から新規タスク指示送信

---

## 🔄 ワークフロー（全体像）

```
1️⃣ ユーザー指示
   └─ queue/task_input.yaml に指示を書き込み

2️⃣ プロデューサー受け取り
   └─ ファイルを監視して指示を検出

3️⃣ タスク分解
   └─ プロデューサーがタスクを分析・分解

4️⃣ 4人同時実行
   ├─ 浅倉透：任務開始
   ├─ 樋口円香：任務開始
   ├─ 福丸小糸：任務開始
   └─ 市川雛菜：任務開始（並列）

5️⃣ 報告集約
   └─ プロデューサーが各報告を集約

6️⃣ ダッシュボード更新
   └─ 進捗がリアルタイム表示

7️⃣ ユーザーへ報告
   └─ 完了状況をまとめて報告
```

---

## ⚠️ システムの重要ルール

### 🔴 「違反は切腹」ルール
各エージェント（プロデューサー・アイドル）は以下を厳守：
- **自分の指示ファイルのみ処理**
- 他のエージェントのファイルを見てはいけない
- タスクファイルは各自の YAML のみ信頼

### tmux send-keys 2回分割ルール
エージェント間通信時、`send-keys` コマンドは必ず2回に分割実行：
```bash
# ❌ ダメ
tmux send-keys -t session:pane "message" Enter

# ✅ OK
tmux send-keys -t session:pane "message"
tmux send-keys -t session:pane Enter
```
2回に分けないと Enter キーが効かず、プロンプト待ちで永遠に停止します。

---

## 🛠️ 技術スタック

| レイヤー | 技術 | 理由 |
|---------|------|------|
| **OS** | WSL2 + Ubuntu | Linux 環境、Claude Code 対応 |
| **ターミナル** | tmux | 複数セッション管理、バックグラウンド実行 |
| **エージェント** | Claude Code | 高度な AI 推論、ツール統合 |
| **通信** | YAML ファイル | 人間が読みやすい、デバッグしやすい |
| **バックエンド** | Node.js/Express | リアルタイム対応、WebSocket |
| **フロントエンド** | React | モダン UI、レスポンシブデザイン |
| **デプロイ** | Vercel/Firebase | スケーラブル、スマホ対応 |

---

## 📊 マイルストーン

| Phase | 内容 | 期限 | ステータス |
|-------|------|------|-----------|
| Phase 1 | 基本構造・ドキュメント | 2/5 | ✅ 完了 |
| Phase 2 | Claude Code エージェント実装 | 2月中旬 | 🔄 準備中 |
| Phase 3 | Web ダッシュボード開発 | 2月下旬 | 📋 計画中 |
| Phase 4 | テスト・最適化 | 3月上旬 | 📋 計画中 |
| Phase 5 | 拡張機能 | 継続的 | 📋 計画中 |

---

## 🚀 クイックスタート

### 前提条件
- WSL2 + Ubuntu
- Node.js 16+
- Claude Code がインストール済み
- tmux がインストール済み

### セットアップ
```bash
cd /home/shoot/work/noctchill-agent
bash scripts/setup.sh
bash scripts/start.sh
```

詳細は [QUICKSTART.md](QUICKSTART.md) を参照してください。

---

## 🎯 実装ロードマップの詳細

詳細な実装計画は [ROADMAP.md](ROADMAP.md) を参照してください。

---

## 📚 ドキュメント一覧

| ドキュメント | 内容 |
|-------------|------|
| [README.md](README.md) | プロジェクト詳細説明・使い方 |
| [QUICKSTART.md](QUICKSTART.md) | すぐに始められるガイド |
| [ROADMAP.md](ROADMAP.md) | 実装計画・ロードマップ |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | このファイル（概要） |
| instructions/*.md | 各ロール用の役割定義書 |

---

## 💭 プロジェクト理念

> **「ユーザーは指示と承認だけ。あとはAIに任せる」**

参考元の記事「Claude Codeで『AI部下10人』を作ったら...」と同じく、このプロジェクトもユーザーの負担を最小化し、AIエージェント群に仕事を任せるシステムの実現を目指しています。

ノクチルの4人のアイドルが、現実のチームメンバーのように、それぞれの得意分野で活躍し、協力して目標を達成する未来を描いています。

---

## 📞 備考

- このプロジェクトは個人学習・開発用です
- アイドルマスター シャイニーカラーズは Cygames/Bandai Namco Entertainment が著作権を保有します
- 参考元の記事作成者：おしお氏 (@shio_shoppaize)

---

**作成日**: 2026年2月5日  
**次の実装開始予定**: 2026年2月中旬（Phase 2）
