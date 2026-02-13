#!/bin/bash

# commu データを分析して instructions を更新するスクリプト
# 使い方: bash scripts/compile_instructions.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTRUCTIONS_DIR="$PROJECT_ROOT/instructions"
COMMU_DIR="$PROJECT_ROOT/commu"
CONFIG_DIR="$PROJECT_ROOT/config"
PROFILES_JSON="$CONFIG_DIR/character_profiles.json"

echo "🎵 ノクチル instructions コンパイラ"
echo "=================================="
echo ""

# キャラクター設定（プロデューサー + アイドル4人）
declare -A CHAR_NAMES
CHAR_NAMES=(
    ["producer"]="プロデューサー"
    ["asakura"]="浅倉 透"
    ["higuchi"]="樋口 円香"
    ["fukumaru"]="福丸 小糸"
    ["ichikawa"]="市川 雛菜"
)

analyze_and_update() {
    local idol=$1
    local name=${CHAR_NAMES[$idol]}
    local instruction_file="$INSTRUCTIONS_DIR/${idol}.md"
    local commu_personal="$COMMU_DIR/${idol}"
    local commu_noctchill="$COMMU_DIR/noctchill"

    echo "📝 ${name} (${idol}) を分析中..."

    # コミュファイルを収集
    local commu_content=""

    # 個人コミュ
    if [ -d "$commu_personal" ]; then
        for file in "$commu_personal"/*.md "$commu_personal"/*.txt; do
            if [ -f "$file" ] && [[ "$(basename "$file")" != "README.md" ]] && [[ "$(basename "$file")" != "template.md" ]]; then
                commu_content+="=== $(basename "$file") ===
$(cat "$file")

"
            fi
        done
    fi

    # ノクチル全員コミュ
    if [ -d "$commu_noctchill" ]; then
        for file in "$commu_noctchill"/*.md "$commu_noctchill"/*.txt; do
            if [ -f "$file" ] && [[ "$(basename "$file")" != "README.md" ]] && [[ "$(basename "$file")" != "template.md" ]]; then
                commu_content+="=== $(basename "$file") ===
$(cat "$file")

"
            fi
        done
    fi

    # コミュがなければスキップ
    if [ -z "$commu_content" ]; then
        echo "  ⏭️  コミュデータなし、スキップ"
        return
    fi

    # 分析エンジン（デフォルトは `copilot -p）
    # 環境変数 `ANALYZER_CMD` で差し替え可能。例:
    # ANALYZER_CMD="claude -p" bash scripts/compile_instructions.sh
    ANALYZER_CMD="${ANALYZER_CMD:-copilot -p}"

    echo "  🔍 分析コマンドを実行: ${ANALYZER_CMD}"

    local prompt="以下は「${name}」の原作コミュの文字起こしです。
文字起こしの精度が悪く、日本語として不自然な箇所があるかもしれません。
日本語として意味のある箇所のみを参考にしてください。

---
${commu_content}
---

上記のコミュから読み取れる「${name}」の性格・口調の特徴を分析してください。

出力形式（JSON）:
{
  \"性格特徴\": [\"特徴1\", \"特徴2\", ...],
  \"口調特徴\": [\"特徴1\", \"特徴2\", ...],
  \"印象的セリフ\": [\"セリフ1\", \"セリフ2\", ...]
}

※ 純粋なJSONのみを出力してください。説明文は不要です。"

    local analysis
    # `ANALYZER_CMD` でプロンプトを実行
    # copilot -p の場合、プロンプトは引数として渡す必要がある
    analysis=$($ANALYZER_CMD "$prompt" 2>&1)

    local exit_code=$?
    if [ $exit_code -ne 0 ] || [ -z "$analysis" ]; then
        echo "  ⚠️  分析に失敗しました（終了コード: $exit_code）"
        echo "  実行コマンド: $ANALYZER_CMD \"<prompt>\""
        echo "  エラー出力:"
        echo "$analysis" | head -5
        return
    fi

    # JSONをクリーンアップ（Total usageなど余分な出力を削除）
    analysis_json=$(printf "%s\n" "$analysis" | sed '/^Total usage/,$d' | sed -n '/{/,/}/p')

    # JSONが有効か確認
    if ! echo "$analysis_json" | jq empty 2>/dev/null; then
        echo "  ⚠️  分析結果が有効なJSONではありません"
        echo "  出力: $analysis_json"
        return
    fi

    # character_profiles.jsonを更新
    if [ ! -f "$PROFILES_JSON" ]; then
        echo "{}" > "$PROFILES_JSON"
    fi

    # 既存のプロファイルデータを取得し、分析結果をマージ
    tmp_json=$(mktemp)
    jq --arg idol "$idol" --argjson analysis "$analysis_json" \
        'if .[$idol] then
            .[$idol] += $analysis
        else
            .[$idol] = $analysis
        end' "$PROFILES_JSON" > "$tmp_json" && mv "$tmp_json" "$PROFILES_JSON"

    # instructions ファイルには「JSONを参照」というメッセージのみ追加
    # 既存の「## キャラクター詳細」セクションがなければ追加
    if ! grep -q "## キャラクター詳細" "$instruction_file"; then
        # instruction_file を正規化して末尾に必ず単独行の "---" を置く
        tmp_norm=$(mktemp)
        awk '
        { lines[NR] = $0 }
        END {
            last = NR
            while (last > 0 && (lines[last] == "" || lines[last] == "---")) last--
            for (i = 1; i <= last; i++) print lines[i]
            print ""
            print "## キャラクター詳細"
            print ""
            print "詳細なキャラクタープロファイルは `{{NOCTCHILL_HOME}}/config/character_profiles.json` の `" ENVIRON["idol"] "` を参照。"
            print "口調・性格の要点はそこに集約されています。"
            print ""
            print "---"
        }' idol="$idol" "$instruction_file" > "$tmp_norm" && mv "$tmp_norm" "$instruction_file"
    fi

    echo "  ✅ 完了: $PROFILES_JSON (${idol} 更新)"
}

# 各キャラクターを処理
for idol in producer asakura higuchi fukumaru ichikawa; do
    analyze_and_update "$idol"
    echo ""
done

echo "=================================="
echo "✨ コンパイル完了！"
echo ""
echo "instructions/ 内のファイルが更新されました。"
