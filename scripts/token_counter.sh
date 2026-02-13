#!/bin/bash
# トークンカウンター - プロンプトとインストラクションファイルのトークン数を概算

# 文字数からトークン数を概算（英数は1.3倍、日本語は2倍で計算）
estimate_tokens() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "0"
        return
    fi

    # 文字数をカウント
    local char_count=$(wc -m < "$file")
    # 概算トークン数（文字数 × 1.5 が日英混在の平均的な値）
    local tokens=$((char_count * 3 / 2))
    echo "$tokens"
}

# NOCTCHILL_HOME の取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOCTCHILL_HOME="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== トークン使用量概算 ==="
echo ""

# プロンプトファイル
echo "## システムプロンプト"
producer_tokens=$(estimate_tokens "$NOCTCHILL_HOME/scripts/prompts/producer_system.md")
asakura_tokens=$(estimate_tokens "$NOCTCHILL_HOME/scripts/prompts/asakura_system.md")
higuchi_tokens=$(estimate_tokens "$NOCTCHILL_HOME/scripts/prompts/higuchi_system.md")
fukumaru_tokens=$(estimate_tokens "$NOCTCHILL_HOME/scripts/prompts/fukumaru_system.md")
ichikawa_tokens=$(estimate_tokens "$NOCTCHILL_HOME/scripts/prompts/ichikawa_system.md")

echo "Producer: ${producer_tokens} tokens"
echo "Asakura: ${asakura_tokens} tokens"
echo "Higuchi: ${higuchi_tokens} tokens"
echo "Fukumaru: ${fukumaru_tokens} tokens"
echo "Ichikawa: ${ichikawa_tokens} tokens"

system_total=$((producer_tokens + asakura_tokens + higuchi_tokens + fukumaru_tokens + ichikawa_tokens))
echo "合計: ${system_total} tokens"
echo ""

# インストラクションファイル
echo "## インストラクションファイル"
producer_inst_tokens=$(estimate_tokens "$NOCTCHILL_HOME/instructions/producer.md")
asakura_inst_tokens=$(estimate_tokens "$NOCTCHILL_HOME/instructions/asakura.md")
higuchi_inst_tokens=$(estimate_tokens "$NOCTCHILL_HOME/instructions/higuchi.md")
fukumaru_inst_tokens=$(estimate_tokens "$NOCTCHILL_HOME/instructions/fukumaru.md")
ichikawa_inst_tokens=$(estimate_tokens "$NOCTCHILL_HOME/instructions/ichikawa.md")

echo "Producer: ${producer_inst_tokens} tokens"
echo "Asakura: ${asakura_inst_tokens} tokens"
echo "Higuchi: ${higuchi_inst_tokens} tokens"
echo "Fukumaru: ${fukumaru_inst_tokens} tokens"
echo "Ichikawa: ${ichikawa_inst_tokens} tokens"

inst_total=$((producer_inst_tokens + asakura_inst_tokens + higuchi_inst_tokens + fukumaru_inst_tokens + ichikawa_inst_tokens))
echo "合計: ${inst_total} tokens"
echo ""

# キャラクタープロファイル
echo "## キャラクタープロファイル"
profile_tokens=$(estimate_tokens "$NOCTCHILL_HOME/config/character_profiles.json")
echo "character_profiles.json: ${profile_tokens} tokens"
echo ""

# 総計
grand_total=$((system_total + inst_total + profile_tokens))
echo "## 総計"
echo "起動時ロード（システムプロンプト）: ${system_total} tokens"
echo "実行時参照（インストラクション）: ${inst_total} tokens"
echo "プロファイル（JSON）: ${profile_tokens} tokens"
echo "---"
echo "総計: ${grand_total} tokens"
echo ""

# タスクサイクル概算
echo "## タスクサイクルあたりの概算"
echo "Producer（最大）: $((producer_tokens + producer_inst_tokens + asakura_inst_tokens + higuchi_inst_tokens + fukumaru_inst_tokens + ichikawa_inst_tokens)) tokens"
echo "  ※全アイドルのインストラクションを読み込んだ場合"
echo "Idol（各）: $((asakura_tokens + asakura_inst_tokens)) tokens （透の例）"
echo ""

# ログファイルに記録
LOG_DIR="$NOCTCHILL_HOME/status"
mkdir -p "$LOG_DIR"
{
    echo "# トークン使用量ログ"
    echo "日時: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "システムプロンプト合計: ${system_total} tokens"
    echo "インストラクション合計: ${inst_total} tokens"
    echo "プロファイル: ${profile_tokens} tokens"
    echo "総計: ${grand_total} tokens"
} > "$LOG_DIR/token_usage.log"

echo "ログを ${LOG_DIR}/token_usage.log に保存しました"
