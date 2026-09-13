#!/usr/bin/env bash
# daily-brief.sh - 定期タスクのチェックリストを取得する。
# 出力を元に Claude が日本語の朝のブリーフィングを整形する。
#
# env:
#   CHECKLIST_URL  チェックリストページ URL (既定あり)
set -euo pipefail
export TZ=Asia/Tokyo

CHECKLIST_URL="${CHECKLIST_URL:-https://ryosukedtomita.github.io/myblog/posts/checklist/index.html}"

# 4 時境界の論理日。00:00〜03:59 は前日扱い。
DAY="$(date -d '-4 hours' +%F)"

echo "=== DATE ==="
echo "logical_day: $DAY (JST, 4時境界)"
echo "weekday: $(date -d "$DAY" +%A)"

echo
echo "=== CHECKLIST ==="
echo "source: $CHECKLIST_URL"
if ! curl -fsSL "$CHECKLIST_URL"; then
  echo "(チェックリストの取得に失敗しました: $CHECKLIST_URL)"
fi
