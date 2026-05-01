#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')

PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
IN=$(echo  "$input" | jq -r '.context_window.total_input_tokens  // 0')
OUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

RL5H_USED=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
RL7D_USED=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

RATE_PART=""
if [ -n "$RL5H_USED" ]; then
    RL5H_LEFT=$(echo "$RL5H_USED" | awk '{printf "%d", 100 - $1}')
    RL7D_LEFT=$(echo "$RL7D_USED" | awk '{printf "%d", 100 - $1}')
    RATE_PART=" | 5h:${RL5H_LEFT}% 7d:${RL7D_LEFT}%"
fi

COST_FMT=$(printf '$%.4f' "$COST")
echo "$MODEL | ctx ${PCT}%${RATE_PART} | IN ${IN} / OUT ${OUT} | ${COST_FMT}"
