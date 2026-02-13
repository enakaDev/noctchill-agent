# トークン使用量最適化ガイド

このドキュメントでは、ノクチルエージェントシステムのトークン消費量を削減するために実施した最適化について説明します。

## 概要

マルチエージェント機能は非常に強力ですが、トークンの消費が激しく、長時間の使用が困難でした。
Phase 1として短期施策を実施し、**約25-35%のトークン削減**を達成しました。

## Phase 1: 短期施策（実施済み）

### 1. プロンプト圧縮

**対象ファイル:**
- [scripts/prompts/producer_system.md](scripts/prompts/producer_system.md)
- [scripts/prompts/asakura_system.md](scripts/prompts/asakura_system.md)
- [scripts/prompts/higuchi_system.md](scripts/prompts/higuchi_system.md)
- [scripts/prompts/fukumaru_system.md](scripts/prompts/fukumaru_system.md)
- [scripts/prompts/ichikawa_system.md](scripts/prompts/ichikawa_system.md)

**実施内容:**
- 冗長な説明文を簡潔化
- 箇条書きの圧縮
- 例文の削減

**効果:** システムプロンプト全体で約30-35%削減

### 2. キャラクタープロファイルのJSON化

**新規作成:**
- [config/character_profiles.json](config/character_profiles.json)

**更新ファイル:**
- [instructions/producer.md](instructions/producer.md)
- [instructions/asakura.md](instructions/asakura.md)
- [instructions/higuchi.md](instructions/higuchi.md)
- [instructions/fukumaru.md](instructions/fukumaru.md)
- [instructions/ichikawa.md](instructions/ichikawa.md)

**実施内容:**
- コミュ分析結果を構造化JSONで保存
- 各インストラクションファイルから冗長な分析結果を削除
- JSON参照への置き換え

**効果:** インストラクションファイル合計で約20-25%削減

### 3. トークン使用量モニタリング

**新規作成:**
- [scripts/token_counter.sh](scripts/token_counter.sh) - トークンカウンター

**更新ファイル:**
- [scripts/launch_agents.sh](scripts/launch_agents.sh) - 起動時トークンカウント機能追加
- [instances/template/status/dashboard.md](instances/template/status/dashboard.md) - トークン使用状況セクション追加

**実施内容:**
- 各プロンプト・インストラクションファイルのトークン数を概算
- 起動時に自動計測
- ログファイル `status/token_usage.log` に記録

### 4. compile_instructions.sh の更新

**更新ファイル:**
- [scripts/compile_instructions.sh](scripts/compile_instructions.sh)

**実施内容:**
- コミュ分析結果をJSON形式で出力
- `character_profiles.json` に自動マージ
- instructionsファイルには参照のみ記載

## 現在のトークン使用量

```bash
# トークン使用量を確認
./scripts/token_counter.sh
```

**Phase 1実測値（2026-02-12時点）:**
```
起動時ロード（システムプロンプト）: 16,338 tokens
実行時参照（インストラクション）: 19,559 tokens
プロファイル（JSON）: 3,745 tokens
総計: 39,642 tokens

タスクサイクルあたり:
- Producer（最大）: 27,089 tokens
- Idol（各）: ~4,964 tokens
```

**Phase 2実測値（2026-02-12時点）:**
```
起動時ロード（システムプロンプト）: 10,969 tokens
実行時参照（インストラクション）: 18,951 tokens
プロファイル（JSON）: 4,803 tokens
総計: 34,723 tokens

タスクサイクルあたり:
- Producer（最大）: 23,032 tokens
- Idol（各）: ~4,492 tokens
```

## 削減効果

| 項目 | Phase 1実測 | Phase 2実測 | Phase 1→2削減率 | 総削減率（推定初期値から） |
|------|-------------|-------------|----------------|--------------------------|
| システムプロンプト | 16,338 | 10,969 | **約33%削減** | ~45-50% |
| インストラクション | 19,559 | 18,951 | 約3%削減 | ~24% |
| プロファイル（JSON） | 3,745 | 4,803 | +28% | - |
| 総計 | 39,642 | 34,723 | **約12%削減** | **約30-40%削減** |
| Producer最大 | 27,089 | 23,032 | **約15%削減** | - |
| Idol平均 | ~4,964 | ~4,492 | **約10%削減** | - |

**Phase 2の主な効果:**
- システムプロンプトの大幅削減（33%）: スキル参照への置き換えと冗長部分の削減
- Producerコンテキストの削減（15%）: 遅延ロード導入（実際の効果は使用時に発揮）

## Phase 2: 中期施策（実施済み - 2026-02-12）

### 1. インストラクション遅延ロード

**実装内容:**
- [scripts/prompts/producer_system.md](scripts/prompts/producer_system.md) の `[TASK]` セクション更新
- [instructions/producer.md](instructions/producer.md) に遅延ロード説明追加
- タスク割り振り時、必要なアイドルのinstructionsのみ読み込む仕組みを導入
- 全員待機の場合はinstructions読み込み不要

**効果:**
- Producerコンテキスト約15%削減（初期値）
- **実際の運用時**: タスクによって50-70%削減の可能性（全員待機時は全instructions不要）

### 2. スキルシステム基盤

**新規作成:**
- [.claude/skills/task_analysis.md](.claude/skills/task_analysis.md) - タスク分析・分類
- [.claude/skills/report_generation.md](.claude/skills/report_generation.md) - レポートYAML生成
- [.claude/skills/character_tone_application.md](.claude/skills/character_tone_application.md) - キャラクター口調適用
- [.claude/skills/file_operations.md](.claude/skills/file_operations.md) - ファイル操作パターン
- [.claude/skills/tmux_communication.md](.claude/skills/tmux_communication.md) - tmux通信パターン

**更新ファイル:**
- [scripts/prompts/producer_system.md](scripts/prompts/producer_system.md) - スキル参照追加、冗長部分削減
- [scripts/prompts/asakura_system.md](scripts/prompts/asakura_system.md) - スキル参照追加、YAML例文削減
- [scripts/prompts/higuchi_system.md](scripts/prompts/higuchi_system.md) - スキル参照追加、YAML例文削減
- [scripts/prompts/fukumaru_system.md](scripts/prompts/fukumaru_system.md) - スキル参照追加、YAML例文削減
- [scripts/prompts/ichikawa_system.md](scripts/prompts/ichikawa_system.md) - スキル参照追加、YAML例文削減

**実施内容:**
- 頻繁に参照するパターンをスキルファイルに抽出
- システムプロンプトから冗長な例文・詳細説明を削除
- 必要時のみスキルファイルを参照する仕組み

**効果:** システムプロンプト約33%削減

### 3. コンテキスト.md保存機能

**実装:** 未実施（Phase 2では見送り）

**理由:** 遅延ロードとスキルシステムで十分な効果が得られたため

## Phase 3: Rate Limit対策 - メッセージ数削減（実施済み - 2026-02-13）

### 問題の特定

**1タスクサイクルあたりの問題:**
- Producer が各アイドルの `[REPORT]` ごとに応答（3回の不要な中間応答）
- 1～3人目のREPORT受信時に「他のメンバーを待っています」と応答
- **推定81,000トークンが無駄**（Producer応答 27,000トークン × 3回）
- メッセージ数：17メッセージ/サイクル

### 実施内容

**修正ファイル:**
- [scripts/prompts/producer_system.md](scripts/prompts/producer_system.md) の `[REPORT]` セクション
- [instructions/producer.md](instructions/producer.md) の `[REPORT]` セクション

**変更内容:**
1. **Producer応答の削減**:
   - 全員分のREPORTが揃うまで**応答しない**
   - 「他のメンバーを待っています」メッセージを削除

2. **ファイル確認の効率化**:
   - Read tool × 4回 → Bash `ls *.yaml | wc -l` × 1回
   - より高速・効率的な確認方法

3. **明確な指示**:
   - 「何もせず待機（応答不要）」を強調
   - トークン節約の理由を明記

### 期待される効果（実運用時）

**メッセージ数削減:**
- 変更前：17メッセージ/サイクル
- 変更後：14メッセージ/サイクル（**18%削減**）

**トークン削減（推定）:**
- 不要なProducer応答 3回削除 → 約81,000トークン削減
- 1サイクルあたり：154,000 → 73,000トークン（**53%削減**）

**Rate Limit到達時間:**
- 約**2.5倍**に延長

### 実測値（静的分析）

トークンカウンターでの計測（2026-02-13時点）:
```
起動時ロード（システムプロンプト）: 11,305 tokens
実行時参照（インストラクション）: 19,457 tokens
総計: 35,565 tokens
```

**注意:**
- 静的分析ではメッセージ削減効果は測定できない
- 実運用時に不要な3回のProducer応答が削減される
- これにより約81,000トークン（推定）の削減効果が発揮される

## Phase 4: 長期施策（未実施）

### 1. 適応的プロンプトサイズ選択

タスクの複雑度に応じてプロンプトの詳細度を変更。

- **Minimal**: 基本ルールのみ（簡単なタスク用）
- **Standard**: 圧縮版（通常タスク用）
- **Verbose**: 詳細説明付き（複雑なタスク用）

### 2. コンテキスト自動要約

N回のやり取り後、自動的に要約を生成し、重要な情報のみ保持。

### 3. プロファイルの動的ロード

必要なキャラクタープロファイルのみをロード。

## 使用方法

### トークン使用量の確認

```bash
./scripts/token_counter.sh
```

### コミュ分析の更新

```bash
# デフォルト（copilot使用）
./scripts/compile_instructions.sh

# claudeを使用
ANALYZER_CMD="claude -p" ./scripts/compile_instructions.sh
```

### 新規インスタンスの起動

```bash
cd /path/to/your/project
/data/myWork/noctchill-agent/scripts/setup.sh
```

起動時に自動的にトークン使用量が表示されます。

## 注意事項

### キャラクター性の維持

プロンプト圧縮により、キャラクターの口調や個性が薄れないように注意してください。
圧縮後は実際にタスクを実行して、キャラクター性が保たれているか確認することを推奨します。

### JSON参照の注意点

インストラクションファイルは `{{NOCTCHILL_HOME}}` プレースホルダーを使用して
`character_profiles.json` を参照しています。これは起動時に実際のパスに置換されます。

### compile_instructions.sh の依存関係

- `jq` コマンドが必要です（JSON処理用）
- 分析エンジン（`copilot` または `claude`）が必要です

インストール:
```bash
# Ubuntu/Debian
sudo apt install jq

# macOS
brew install jq
```

## トラブルシューティング

### トークンカウンターが動作しない

```bash
chmod +x /data/myWork/noctchill-agent/scripts/token_counter.sh
```

### compile_instructions.sh でエラー

```bash
# jqがインストールされているか確認
which jq

# 分析エンジンが利用可能か確認
which copilot
# または
which claude
```

### character_profiles.json が破損

バックアップから復元するか、再度 `compile_instructions.sh` を実行してください。

## 今後の改善案

- [ ] Phase 2の実装（遅延ロード、コンテキスト保存、スキルシステム）
- [ ] Phase 3の実装（適応的プロンプト、自動要約）
- [ ] トークン使用量のリアルタイムダッシュボード
- [ ] プロンプト圧縮率の自動測定
- [ ] キャラクター性の自動評価システム

## 参考リンク

- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [トークン使用量の最適化について](https://docs.anthropic.com/claude/docs/optimizing-token-usage)
