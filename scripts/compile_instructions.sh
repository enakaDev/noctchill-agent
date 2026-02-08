#!/bin/bash

# commu データを分析して instructions を更新するスクリプト
# 使い方: bash scripts/compile_instructions.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTRUCTIONS_DIR="$PROJECT_ROOT/instructions"
COMMU_DIR="$PROJECT_ROOT/commu"

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

出力形式（Markdown）:
### コミュから読み取れる性格
- 箇条書きで3-5個

### コミュから読み取れる口調の特徴
- 箇条書きで3-5個

### 印象的なセリフ
- 原文のまま3-5個引用"

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

        # instructions ファイルを更新
        # 1) 分析出力の末尾に含まれる "Total usage" 以降を切り捨てる
        marker="## コミュ分析結果"
        analysis_clean=$(printf "%s\n" "$analysis" | sed '/^Total usage/,$d')

        # 2) instruction_file を正規化して末尾に必ず単独行の "---" を置く
        tmp_norm=$(mktemp)
        awk '
        { lines[NR] = $0 }
        END {
            last = NR
            while (last > 0 && (lines[last] == "" || lines[last] == "---")) last--
            for (i = 1; i <= last; i++) print lines[i]
            print "---"
        }' "$instruction_file" > "$tmp_norm" && mv "$tmp_norm" "$instruction_file"

        # 3) 既存のマーカーがあれば除去（マーカー行以降を最後の --- の前まで削除）
        tmp_strip=$(mktemp)
        awk -v marker="$marker" '
        { lines[NR] = $0 }
        END {
            # find marker position (first occurrence)
            m = 0
            for (i = 1; i <= NR; i++) if (lines[i] == marker) { m = i; break }
            # print up to either marker-1 (if found) or up to NR-1 (last --- is NR)
            end_line = (m > 0) ? m-1 : NR-1
            for (i = 1; i <= end_line; i++) print lines[i]
        }' "$instruction_file" > "$tmp_strip"

        # 4) 最後にマーカー + 分析結果（整形済み） + --- を挿入
        mv "$tmp_strip" "$instruction_file"
        {
            echo ""
            echo "$marker"
            echo ""
            printf "%s\n" "$analysis_clean"
            echo "---"
        } >> "$instruction_file"

    echo "  ✅ 完了: $instruction_file"
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
