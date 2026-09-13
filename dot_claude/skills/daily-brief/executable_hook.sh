#!/usr/bin/env bash
# hook.sh - SessionStart フック本体。
# その日 (JST 4時境界) の初回起動を検知し、初回のみ Claude へ
# 「daily-brief スキルを実行して朝のブリーフィングを提示せよ」という指示を
# hookSpecificOutput.additionalContext で注入する。
#
# 2 回目以降の起動 / resume / clear では無言で exit 0 (日付 dedup)。
# 定期タスクのセクションは期間ごと初回のみ "due" として通知する。
set -euo pipefail
export TZ=Asia/Tokyo

STATE_FILE="$HOME/.claude/daily-brief-state.json"
SKILL_SCRIPT="$HOME/.claude/skills/daily-brief/daily-brief.sh"

# フックの stdin (JSON) は読み捨て。日付 dedup があるため source 判定は不要。
cat >/dev/null 2>&1 || true

DAY="$(date -d '-4 hours' +%F)"   # 論理日 YYYY-MM-DD
Y="${DAY%%-*}"                    # YYYY
YM="${DAY%-*}"                    # YYYY-MM
M="$(date -d "$DAY" +%-m)"        # 月 (前ゼロなし)

# --- state 読み込み (なければ空) ---
read_field() {
  [ -f "$STATE_FILE" ] || { echo ""; return; }
  jq -r --arg k "$1" '.[$k] // ""' "$STATE_FILE" 2>/dev/null || echo ""
}
last_brief_date="$(read_field last_brief_date)"
last_month_start="$(read_field last_month_start)"
last_even_month="$(read_field last_even_month)"
last_year_end="$(read_field last_year_end)"

# 当日処理済みなら無言で終了。
if [ "$last_brief_date" = "$DAY" ]; then
  exit 0
fi

# --- 当日該当の定期セクションを算出し state を更新 ---
due=()
if [ "$last_month_start" != "$YM" ]; then
  due+=("月始めにやること")
  last_month_start="$YM"
fi
if [ $((M % 2)) -eq 0 ] && [ "$last_even_month" != "$YM" ]; then
  due+=("偶数月のはじめにやること")
  last_even_month="$YM"
fi
if [ "$M" -eq 12 ] && [ "$last_year_end" != "$Y" ]; then
  due+=("1年の終わりにやること")
  last_year_end="$Y"
fi

# state 保存
jq -n \
  --arg d "$DAY" --arg ms "$last_month_start" --arg em "$last_even_month" --arg ye "$last_year_end" \
  '{last_brief_date:$d, last_month_start:$ms, last_even_month:$em, last_year_end:$ye}' \
  >"$STATE_FILE"

# 該当セクションが無い日は提示するものが無いので無言で終了。
if [ "${#due[@]}" -eq 0 ]; then
  exit 0
fi

# --- 該当セクションの文言を組み立て ---
due_csv="$(IFS='、'; echo "${due[*]}")"
due_line="本日該当する定期タスクのセクション: ${due_csv}。これらのみをチェックリストから抽出して提示すること。"

# --- additionalContext を JSON で出力 ---
CTX="【デイリーブリーフ】本日 ${DAY} はこのセッションがその日の初回起動です。\
ユーザーへの最初の応答に先立ち、まず \`bash ${SKILL_SCRIPT}\` を実行してください。\
その出力を元に、日本語で今日該当する定期タスクを提示します。\
${due_line} \
提示後にユーザーの用件へ進んでください。"

jq -n --arg ctx "$CTX" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
