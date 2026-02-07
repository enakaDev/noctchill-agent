# noctchill-agent - 実装ロードマップ

## ✅ 完了した項目

### Phase 1: 基本構造構築
- [x] プロジェクトディレクトリ構成作成
- [x] 各ロール用の詳細な役割定義書作成
  - [x] manager.md - マネージャー
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

### Phase 1a: ドキュメント・プロンプト
- [x] manager_prompt.txt - マネージャー用 Claude Code プロンプト
- [x] 各アイドルの役割定義と行動原則

---

## 🚀 次のステップ - 実装予定

### Phase 2: Claude Code エージェント実装

#### 2.1 マネージャーエージェント実装
- [ ] Claude Code インタラクティブ起動スクリプト
- [ ] `producer_to_manager.yaml` 監視機能
- [ ] タスク分解ロジック実装
- [ ] 各アイドル用タスクファイル自動生成
- [ ] `queue/reports/` 監視と集約
- [ ] ダッシュボード自動更新機能
- [ ] エラーハンドリング

#### 2.2 アイドルエージェント実装（×4）
- [ ] 浅倉 透エージェント
  - [ ] `queue/tasks/asakura.yaml` 監視
  - [ ] リーダーシップベースのタスク処理
  - [ ] 報告ファイル自動生成
- [ ] 樋口 円香エージェント
  - [ ] `queue/tasks/higuchi.yaml` 監視
  - [ ] 創意工夫のプロンプティング
  - [ ] 改善提案の生成
- [ ] 福丸 小糸エージェント
  - [ ] `queue/tasks/fukumaru.yaml` 監視
  - [ ] 品質チェック関数
  - [ ] 詳細な不具合報告
- [ ] 市川 雛菜エージェント
  - [ ] `queue/tasks/ichikawa.yaml` 監視
  - [ ] ドキュメント生成
  - [ ] 地道な作業処理

### Phase 3: Webダッシュボード開発

#### 3.1 バックエンド (Node.js/Express)
- [ ] Express サーバー構築
- [ ] `/api/status` - 進捗情報 API
- [ ] `/api/dashboard` - ダッシュボード情報 API
- [ ] ファイルウォッチャー（YAML 監視）
- [ ] WebSocket リアルタイム通知

#### 3.2 フロントエンド (React)
- [ ] React アプリケーション構築
- [ ] ダッシュボード表示コンポーネント
  - [ ] タスク進捗表
  - [ ] 各アイドルのステータス
  - [ ] リアルタイム報告表示
- [ ] タスク指示インターフェース
- [ ] レスポンシブデザイン（スマホ対応）

#### 3.3 デプロイ
- [ ] ローカル実行ガイド
- [ ] クラウドデプロイ検討（Firebase/Vercel）
- [ ] スマホアプリ化検討（Capacitor など）

### Phase 4: テスト・最適化

#### 4.1 統合テスト
- [ ] 全エージェント通信確認
- [ ] 並列実行の確認
- [ ] エラーハンドリング検証
- [ ] パフォーマンステスト

#### 4.2 ユーザーテスト
- [ ] ユーザビリティ検証
- [ ] UX 改善

#### 4.3 最適化
- [ ] API コスト最適化
- [ ] レスポンス速度改善
- [ ] メモリ使用量削減

### Phase 5: 拡張機能

- [ ] 複数の「ノクチル」ユニット対応
- [ ] 他のユニット対応（Luminous Smile, Saint Impression など）
- [ ] スキル自動生成（参考: 戦国 shogun）
- [ ] 長期学習・改善機能
- [ ] 音声入力対応（スマホ）
- [ ] 多言語対応

---

## 🎯 マイルストーン

| フェーズ | 期限目安 | ゴール |
|---------|---------|-------|
| Phase 1 | ✅ 完了 | 基本構造構築、ドキュメント完成 |
| Phase 2 | 2-3週間 | Claude Code エージェント動作確認 |
| Phase 3 | 3-4週間 | Web ダッシュボード β版リリース |
| Phase 4 | 1-2週間 | テスト完了、最適化 |
| Phase 5 | 継続的 | 拡張機能追加 |

---

## 📋 詳細実装タスク

### A. マネージャーエージェント実装

```python
# 疑似コード
class Manager:
    def __init__(self):
        self.status = "待機中"
        
    def run(self):
        while True:
            # 指示確認
            instruction = self.read_instruction()
            if instruction:
                # タスク分解
                tasks = self.decompose_task(instruction)
                # 各アイドルに分配
                for idol_name, task in tasks.items():
                    self.write_task(idol_name, task)
                # アイドル起動
                self.notify_idols()
                # 報告待機
                reports = self.wait_reports()
                # ダッシュボード更新
                self.update_dashboard(reports)
            time.sleep(5)
```

### B. ダッシュボード Web API

```javascript
// 疑似コード
app.get('/api/status', (req, res) => {
    const dashboard = fs.readFileSync('status/dashboard.md', 'utf-8');
    const reports = fs.readdirSync('queue/reports/');
    res.json({
        dashboard,
        reports,
        timestamp: new Date()
    });
});
```

### C. React ダッシュボード

```jsx
// 疑似コード
function Dashboard() {
    const [status, setStatus] = useState(null);
    
    useEffect(() => {
        const ws = new WebSocket('ws://localhost:3001/api/updates');
        ws.onmessage = (e) => setStatus(JSON.parse(e.data));
    }, []);
    
    return (
        <div className="dashboard">
            <TaskProgress />
            <IdolStatus />
            <ReportList />
        </div>
    );
}
```

---

## 🔧 技術スタック決定

### バックエンド
- **言語**: Node.js (JavaScript/TypeScript)
- **フレームワーク**: Express
- **ファイル監視**: chokidar
- **リアルタイム**: WebSocket (ws)

### フロントエンド
- **フレームワーク**: React
- **状態管理**: Redux または Zustand
- **UI ライブラリ**: Material-UI または Tailwind CSS
- **グラフ**: Chart.js または Recharts

### インフラ
- **開発**: WSL2 + Node.js
- **デプロイ**: Vercel または Firebase Hosting
- **スマホ**: React + Capacitor 検討

---

## 📖 参考

- [元記事](https://zenn.dev/shio_shoppaize/articles/5fee11d03a11a1) - 戦国マルチエージェント
- [Claude API Docs](https://docs.anthropic.com)
- [tmux チートシート](https://qiita.com/search?q=tmux+%E3%83%81%E3%83%BC%E3%83%88%E3%82%B7%E3%83%BC%E3%83%88)
- [アイドルマスター シャイニーカラーズ](https://shinycolors.idolmaster.jp/)

---

## 💬 プロジェクト概要

**ノクチル マルチエージェント開発フレームワーク**

アイドルマスター シャイニーカラーズのユニット「ノクチル」をモチーフにしたAIマルチエージェント開発システムです。プロデューサー（ユーザー）からの指示を、マネージャーが4人のアイドルに分配し、協力して目標を達成する仕組みです。

**目標**: スマホからもリアルタイムで進捗を確認でき、出先からでも開発を進めることができるシステムの構築

---

**実装開始予定：2026年2月中旬**
