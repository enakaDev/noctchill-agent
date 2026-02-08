# noctchill-agent - 実装ロードマップ

## ✅ 完了した項目

### Phase 1: 基本構造構築
- [x] プロジェクトディレクトリ構成作成
- [x] 各ロール用の詳細な役割定義書作成
  - [x] producer.md - プロデューサー
  - [x] asakura.md - 浅倉 透
  - [x] higuchi.md - 樋口 円香
  - [x] fukumaru.md - 福丸 小糸
  - [x] ichikawa.md - 市川 雛菜
- [x] YAML ベース通信フォーマット設計
- [x] ダッシュボード初期化
- [x] セットアップスクリプト作成（setup.sh）
- [x] tmux セッション起動スクリプト作成（start.sh）
- [x] README 作成（日本語）
- [x] QUICKSTART ガイド作成
- [x] git 初期化

### Phase 2: Claude Code エージェント実装
- [x] イベント駆動アーキテクチャ設計（ポーリング → send-keys 通知方式）
- [x] エージェント一括起動スクリプト作成（launch_agents.sh）
- [x] タスク送信ヘルパー作成（send_task.sh）
- [x] プロデューサーエージェント実装
  - [x] システムプロンプト作成（producer_system.md）
  - [x] `[TASK]` 受信 → task_input.yaml 読み込み → タスク分解
  - [x] 各アイドル用タスクYAML自動生成（queue/tasks/）
  - [x] `[REPORT:<name>]` 受信 → レポート集約 → ダッシュボード更新
  - [x] エラーハンドリング（失敗レポート検知、YAML読み込みエラー）
- [x] アイドルエージェント実装（×4）
  - [x] 浅倉 透（asakura_system.md）— 直感的判断、全体統括
  - [x] 樋口 円香（higuchi_system.md）— 冷静な分析、品質チェック
  - [x] 福丸 小糸（fukumaru_system.md）— 地道で丁寧な作業
  - [x] 市川 雛菜（ichikawa_system.md）— アイデア出し、ポジティブ発想
- [x] 初回動作テスト完了（自己紹介タスク）

---

## 🚀 次のステップ - 実装予定

### Phase 3: テスト・最適化

#### 3.1 統合テスト
- [ ] 全エージェント通信確認（タスク配信 → 実行 → レポート回収の一連フロー）
- [ ] 並列実行の確認（4人同時タスク実行）
- [ ] エラーハンドリング検証（失敗レポート、YAML 不正など）
- [ ] `[FEEDBACK]` コマンドの動作確認
- [ ] `[SHUTDOWN]` コマンドの動作確認

#### 3.2 トークン最適化
- [ ] 各エージェントのシステムプロンプトのトークン数計測
- [ ] instructions ファイルの読み込みコスト分析
- [ ] プロンプト圧縮・不要情報の削減
- [ ] コミュ分析結果の要約度合い調整
- [ ] 1タスクあたりの API コスト計測・目標設定

#### 3.3 運用改善
- [ ] タスク履歴・ログの永続化
- [ ] エラーリカバリ（タスク再実行の仕組み）
- [ ] ダッシュボード表示フォーマットの最適化

### Phase 4: 拡張機能

- [ ] コミュデータ追加・人格精度向上
- [ ] スキル自動生成（参考: 戦国 shogun）
- [ ] 長期学習・改善機能
- [ ] Web ダッシュボード開発（バックエンド + フロントエンド）
- [ ] 音声入力対応（スマホ）

---

## 🎯 マイルストーン

| フェーズ | 状態 | ゴール |
|---------|------|-------|
| Phase 1 | ✅ 完了 | 基本構造構築、ドキュメント完成 |
| Phase 2 | ✅ 完了 | Claude Code エージェント動作確認 |
| Phase 3 | 次 | テスト完了、トークン最適化 |
| Phase 4 | 継続的 | 拡張機能追加 |

---

## 📋 アーキテクチャ概要

### A. イベント駆動フロー（Phase 2 で実装済み）

```
ユーザー
  │  queue/task_input.yaml に指示を書き込み
  │  プロデューサーに [TASK] メッセージを入力
  ▼
プロデューサー (Window 0) ── Claude Code --system-prompt
  │  task_input.yaml 読み込み → タスク分解
  │  queue/tasks/{idol}.yaml 作成 → send-keys で [TASK] 通知
  ▼
アイドル×4 (Window 2, Pane 0-3) ── 各 Claude Code --system-prompt
  │  タスク実行 → queue/reports/{idol}_report.yaml 作成
  │  send-keys で [REPORT:<name>] 通知
  ▼
プロデューサー
  │  全員分揃ったら集約 → dashboard.md 更新
  ▼
ユーザーに完了報告
```

### B. ダッシュボードの現行方式

- `status/dashboard.md` をプロデューサーがリアルタイム更新
- tmux Window 1 で `watch cat status/dashboard.md` により自動表示
- SSH 越し（スマホ含む）でそのまま閲覧可能

---

## 📖 参考

- [元記事](https://zenn.dev/shio_shoppaize/articles/5fee11d03a11a1) - 戦国マルチエージェント
- [Claude API Docs](https://docs.anthropic.com)
- [tmux チートシート](https://qiita.com/search?q=tmux+%E3%83%81%E3%83%BC%E3%83%88%E3%82%B7%E3%83%BC%E3%83%88)
- [アイドルマスター シャイニーカラーズ](https://shinycolors.idolmaster.jp/)

---

## 💬 プロジェクト概要

**ノクチル マルチエージェント開発フレームワーク**

アイドルマスター シャイニーカラーズのユニット「ノクチル」をモチーフにしたAIマルチエージェント開発システムです。ユーザーからの指示を、プロデューサーが4人のアイドルに分配し、協力して目標を達成する仕組みです。

**目標**: スマホからもリアルタイムで進捗を確認でき、出先からでも開発を進めることができるシステムの構築

---

**Phase 2 完了：2026年2月7日**
