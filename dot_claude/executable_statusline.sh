#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')

PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
IN=$(echo  "$input" | jq -r '.context_window.total_input_tokens  // 0')
OUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

RL5H_USED=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
RL7D_USED=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
RL7D_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

RATE_PART=""
if [ -n "$RL5H_USED" ]; then
    RL5H_LEFT=$(echo "$RL5H_USED" | awk '{printf "%d", 100 - $1}')
    RL7D_LEFT=$(echo "$RL7D_USED" | awk '{printf "%d", 100 - $1}')
    RESET_PART=""
    if [ -n "$RL7D_RESET" ]; then
        NOW=$(date +%s)
        RESET_PART=$(awk -v r="$RL7D_RESET" -v n="$NOW" 'BEGIN {
            s = r - n
            if (s <= 0)        printf "(0)"
            else if (s >= 86400) printf "(%dd)", int(s / 86400)
            else if (s >= 3600)  printf "(%dh)", int(s / 3600)
            else                 printf "(%dm)", int(s / 60)
        }')
    fi
    RATE_PART=" | 5h:${RL5H_LEFT}% 7d:${RL7D_LEFT}%${RESET_PART}"
fi

COST_FMT=$(printf '$%.4f' "$COST")
echo "$MODEL | ctx ${PCT}%${RATE_PART} | IN ${IN} / OUT ${OUT} | ${COST_FMT}"
