#!/usr/bin/env bash
# Sync all articles of a Qiita tag into a PUBLIC stock list (idempotent / differential).
# Requires an attached everyday Chrome session named "chrome" (see attach-local-chrome skill).
#
# Env vars:
#   QIITA_USER    Qiita username whose articles to enumerate (e.g. sigma_devsecops)   [required]
#   TAG           Tag / category name, case-insensitive (e.g. Haskell)                [required]
#   LIST_NAME     Exact name of the PUBLIC stock list (created if missing)            [required]
#   REMOVE_LATER  1 = remove auto-added private "あとで読む" from newly stocked items  [default 1]
#   CREATE_IF_MISSING 1 = auto-create the public list if not found                    [default 1]
set -uo pipefail

QUSER="${QIITA_USER:?Set QIITA_USER}"
TAG="${TAG:?Set TAG}"
LIST_NAME="${LIST_NAME:?Set LIST_NAME}"
REMOVE_LATER="${REMOVE_LATER:-1}"
CREATE_IF_MISSING="${CREATE_IF_MISSING:-1}"

PW="npx -y @playwright/cli@latest --s=chrome"
PWRAW="npx -y @playwright/cli@latest --raw --s=chrome"
CBLABEL="公開 ${LIST_NAME}"

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT; cd "$WORK"
ref_of(){ grep -oE 'ref=e[0-9]+' | head -1 | cut -d= -f2; }

# 0. must be attached
if ! $PW tab-list >/dev/null 2>&1; then
  echo "ERROR: no attached 'chrome' session. First run: npx -y @playwright/cli@latest attach --cdp=chrome" >&2
  echo "(Enable chrome://inspect/#remote-debugging 'Allow remote debugging' and approve the prompt — see attach-local-chrome skill.)" >&2
  exit 1
fi

# 1. target article ids by tag (public API, no auth needed)
echo "Enumerating '$TAG' articles for @$QUSER ..." >&2
target_ids=$(python3 - "$QUSER" "$TAG" <<'PY'
import sys, json, urllib.request
user, tag = sys.argv[1], sys.argv[2].lower()
ids=[]
for p in range(1, 21):
    url=f"https://qiita.com/api/v2/users/{user}/items?per_page=100&page={p}"
    try:
        data=json.load(urllib.request.urlopen(url))
    except Exception as e:
        sys.stderr.write(f"API error page {p}: {e}\n"); break
    if not data: break
    for it in data:
        if any((t.get("name","").lower()==tag) for t in it.get("tags",[])):
            ids.append(it["id"])
    if len(data)<100: break
print("\n".join(ids))
PY
)
target_ids=$(echo "$target_ids" | grep -v '^$' | sort -u)
[ -z "$target_ids" ] && { echo "No '$TAG' articles for @$QUSER." >&2; exit 0; }
echo "Target articles: $(echo "$target_ids" | wc -l)" >&2

first_id=$(echo "$target_ids" | head -1)

find_list_url(){
  $PWRAW goto "https://qiita.com/$QUSER/stocks" >/dev/null 2>&1; sleep 2
  $PWRAW snapshot > snap.yml 2>/dev/null
  awk -v n="$LIST_NAME" '
    index($0, "link \"" n "\"") {f=1}
    f && /\/url:/ {print; exit}' snap.yml \
    | grep -oE "/$QUSER/stocks/[a-f0-9]+" | head -1
}

create_public_list(){
  echo "Creating public list \"$LIST_NAME\" ..." >&2
  $PWRAW goto "https://qiita.com/$QUSER/items/$first_id" >/dev/null 2>&1; sleep 1
  $PWRAW snapshot > c.yml 2>/dev/null
  local b; b=$(grep -E 'button "ストック(する|を編集する)"' c.yml | head -1 | ref_of)
  $PW click "$b" >/dev/null 2>&1; sleep 2
  $PWRAW snapshot > c.yml 2>/dev/null
  local create; create=$(grep -E 'button "ストックリストを作成する"' c.yml | head -1 | ref_of)
  $PW click "$create" >/dev/null 2>&1; sleep 1
  $PWRAW snapshot > c.yml 2>/dev/null
  local namebox pubradio mkbtn
  namebox=$(grep -E 'textbox "ストックリストの名前"' c.yml | head -1 | ref_of)
  pubradio=$(grep -E 'radio "公開"' c.yml | head -1 | ref_of)
  mkbtn=$(grep -E 'button "作成する"' c.yml | head -1 | ref_of)
  $PW fill "$namebox" "$LIST_NAME" >/dev/null 2>&1
  $PW click "$pubradio" >/dev/null 2>&1; sleep 1
  $PW click "$mkbtn" >/dev/null 2>&1; sleep 2
  $PW press Escape >/dev/null 2>&1; sleep 1
}

list_url="$(find_list_url)"
if [ -z "$list_url" ]; then
  if [ "$CREATE_IF_MISSING" = "1" ]; then
    create_public_list
    list_url="$(find_list_url)"
  fi
fi
[ -z "$list_url" ] && { echo "ERROR: public list \"$LIST_NAME\" not found and not created." >&2; exit 1; }
echo "List: https://qiita.com$list_url" >&2

# 2. existing ids in the list (paginate until no new ids)
existing=""
for p in $(seq 1 30); do
  $PWRAW goto "https://qiita.com${list_url}?page=$p" >/dev/null 2>&1; sleep 1
  $PWRAW snapshot > lst.yml 2>/dev/null
  pageids=$(grep -oE "/$QUSER/items/[a-f0-9]+" lst.yml | sed -E 's#.*/items/##' | sort -u)
  [ -z "$pageids" ] && break
  before=$(echo "$existing" | grep -v '^$' | sort -u | wc -l)
  existing=$(printf "%s\n%s" "$existing" "$pageids")
  after=$(echo "$existing" | grep -v '^$' | sort -u | wc -l)
  [ "$after" -eq "$before" ] && break
done
existing=$(echo "$existing" | grep -v '^$' | sort -u)
echo "Already in list: $(echo "$existing" | grep -c . )" >&2

# 3. diff
to_add=$(comm -23 <(echo "$target_ids") <(echo "$existing" | grep -v '^$'))
to_add=$(echo "$to_add" | grep -v '^$')
[ -z "$to_add" ] && { echo "In sync — nothing to add."; exit 0; }
echo "To add: $(echo "$to_add" | wc -l)" >&2

# 4. stock each missing article (proven snapshot->ref->click method)
added=0; failed=0
while IFS= read -r id; do
  [ -z "$id" ] && continue
  $PWRAW goto "https://qiita.com/$QUSER/items/$id" >/dev/null 2>&1; sleep 1
  $PWRAW snapshot > s.yml 2>/dev/null
  btn=$(grep -E 'button "ストック(する|を編集する)"' s.yml | head -1 | ref_of)
  [ -z "$btn" ] && { echo "  $id: stock button not found"; failed=$((failed+1)); continue; }
  $PW click "$btn" >/dev/null 2>&1; sleep 2
  $PWRAW snapshot > d.yml 2>/dev/null
  publine=$(grep -F "checkbox \"$CBLABEL\"" d.yml | head -1)
  laterline=$(grep 'checkbox "非公開 あとで読む"' d.yml | head -1)
  pubref=$(echo "$publine" | ref_of)
  laterref=$(echo "$laterline" | ref_of)
  if [ -z "$pubref" ]; then echo "  $id: list checkbox not found"; failed=$((failed+1)); $PW press Escape >/dev/null 2>&1; continue; fi
  echo "$publine" | grep -q '\[checked\]' || { $PW click "$pubref" >/dev/null 2>&1; sleep 1; }
  if [ "$REMOVE_LATER" = "1" ] && echo "$laterline" | grep -q '\[checked\]'; then
    [ -n "$laterref" ] && { $PW click "$laterref" >/dev/null 2>&1; sleep 1; }
  fi
  $PW press Escape >/dev/null 2>&1; sleep 1
  added=$((added+1)); echo "  + $id"
done <<< "$to_add"

echo "Done. added=$added failed=$failed (target=$(echo "$target_ids"|wc -l) already=$(echo "$existing"|grep -c .))"
