#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
SESSION_ID=$(echo "$input" | jq -r '.session_id // ""')

PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
IN=$(echo  "$input" | jq -r '.context_window.total_input_tokens  // 0')
OUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

MODE_FILE="/tmp/claude-mode-${SESSION_ID}"
if [ -n "$SESSION_ID" ] && [ -r "$MODE_FILE" ]; then
    MODE=$(cat "$MODE_FILE")
else
    MODE="default"
fi

COST_FMT=$(printf '$%.4f' "$COST")
echo "$MODEL | $MODE | ctx ${PCT}% | IN ${IN} / OUT ${OUT} | ${COST_FMT}"
