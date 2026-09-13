---
name: super-insights
description: 直近1ヶ月の活動（Obsidianノート・GitHubコミット・Qiita投稿・個人ブログ）を横断的に収集し、月次ふりかえりノートを Obsidian の Permanent/furikaeri/monthly/ に作成する。「月次ふりかえり」「/super-insights」と言われたときに使う。
when_to_use: ユーザーが直近1ヶ月の活動をまとめた月次ふりかえりを作りたいとき。
argument-hint: [対象月 yyyy-mm (省略時は今月)]
allowed-tools: Bash Read Write WebFetch
---

# Super Insights (月次ふりかえり)

直近1ヶ月の活動を複数ソースから収集し、月次ふりかえりノートを作成する。

## 手順

### 0. 期間を決める（前回とかぶらないようにする）

- **まず前回のふりかえりファイルを確認する。** `~/obsidian/Permanent/furikaeri/monthly/` の
  既存ファイルを一覧し、最新のもの（ファイル名 `yyyy-mm` の降順で先頭）を Read する。
  そのファイルの「対象期間: A 〜 B」の **終了日 B** を読み取り、**開始日を B の翌日**にする
  （取得期間が前回と重複しないようにするため）。
  ```bash
  ls ~/obsidian/Permanent/furikaeri/monthly/*.md 2>/dev/null | sort | tail -1
  ```
- **前回ファイルが無い / 期間が読めない場合のみ**、`今日から30日前` を開始日にする:
  `date -d '30 days ago' +%Y-%m-%d`（今日は `date +%Y-%m-%d`）。
- 決めた開始日 (`SINCE`) と終了日 (`今日 = TODAY`) を、以降の全ソース（GitHub / Qiita /
  myblog / Obsidian）で共通の取得期間として使う。本文冒頭に「対象期間: SINCE 〜 TODAY」を明記する。
- **ファイル名の月 (`yyyy-mm`)** は「振り返る対象の完了した月」にする。引数で明示されればそれを使う。
  省略時、月初 (1〜3日) に実行した場合は直前の月 (先月) を使うのが自然
  （例: 2026-07-01 実行なら実質6月分なので `2026-06`）。判断に迷う場合はユーザーに確認する。

### 1. Obsidianノート（created が1ヶ月以内）

`~/obsidian` 配下の `.md` から frontmatter の `created:` が開始日以降のものを集める。
`created:` は `YYYY-MM-DD` 形式。

**注意: shell の `>` による日付文字列比較は使わない**（zsh ではリダイレクトと解釈され
`condition expected: >` で失敗する）。日付比較・frontmatterパースは Python で行うのが確実。
`.trash/` とテンプレート (`created: <% ... %>`) は除外する。例:

```bash
python3 - <<'PY'
import os, re, glob
SINCE="2026-06-01"  # date -d '30 days ago' の値に置き換える
root=os.path.expanduser("~/obsidian")
rows=[]
for f in glob.glob(root+"/**/*.md", recursive=True):
    if "/.trash/" in f: continue
    try:
        with open(f, encoding="utf-8") as fh: head=fh.read(800)
    except (UnicodeDecodeError, OSError): continue
    m=re.search(r'^created:\s*["\']?(\d{4}-\d{2}-\d{2})', head, re.M)
    if m and m.group(1) >= SINCE:
        rows.append((m.group(1), os.path.relpath(f, root)))
rows.sort()
print(f"COUNT={len(rows)}")
for d,p in rows: print(d, p)
PY
```

得られたファイルのうち主要なものは Read してタイトル/要点を把握する。
ノート一覧は日付順に並べ、`[[ノート名]]` リンクで書く。テーマ別（Haskell/開発/読書/キャリア/Daily 等）に
小見出しで分けると読みやすい。

### 2. GitHubコミットログ（直近1ヶ月）

`gh` CLI（認証済み、アカウント: RyosukeDTomita）で全リポジトリのコミットを取得する。

**`gh search commits` は1クエリ最大100件で打ち切られる。** 1ヶ月分をまとめて取ると100件を
超えて前半が欠けるため、**期間を半月ずつ（約15日窓）に分割して取得し、あとでマージする。**
各窓を取得したら件数を確認し、**もし窓が100件に達していたらその窓をさらに半分に分割**して
取り直す（取りこぼしゼロを保証する）。

```bash
SCRATCH=/path/to/scratchpad          # 実際のscratchpadパスに置き換える
SINCE=$(date -d '30 days ago' +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)
MID=$(date -d '15 days ago' +%Y-%m-%d)

# 窓1: SINCE .. MID-1 / 窓2: MID .. TODAY （日付範囲は committer-date="A..B" 形式）
DAY_BEFORE_MID=$(date -d "$MID -1 day" +%Y-%m-%d)
gh search commits --author=RyosukeDTomita --committer-date="$SINCE..$DAY_BEFORE_MID" \
  --sort=committer-date --order=desc --limit 100 \
  --json repository,sha,commit > "$SCRATCH/gh_1.json" 2>/dev/null
gh search commits --author=RyosukeDTomita --committer-date="$MID..$TODAY" \
  --sort=committer-date --order=desc --limit 100 \
  --json repository,sha,commit > "$SCRATCH/gh_2.json" 2>/dev/null

# 件数チェック（100なら要さらに分割）
for f in "$SCRATCH"/gh_*.json; do echo "$f: $(python3 -c "import json,sys;print(len(json.load(open('$f'))))")"; done
```

集計はマージして sha で重複排除する:

```bash
python3 - "$SCRATCH/gh_1.json" "$SCRATCH/gh_2.json" <<'PY'
import json,sys
from collections import defaultdict
seen=set(); data=[]
for path in sys.argv[1:]:
    for c in json.load(open(path)):
        if c["sha"] in seen: continue
        seen.add(c["sha"]); data.append(c)
byrepo=defaultdict(list)
for c in data:
    byrepo[c["repository"]["fullName"]].append(
        (c["commit"]["committer"]["date"][:10], c["commit"]["message"].splitlines()[0]))
print(f"TOTAL={len(data)} REPOS={len(byrepo)}")
for repo in sorted(byrepo, key=lambda r:-len(byrepo[r])):
    cs=sorted(byrepo[repo], reverse=True)
    print(f"\n### {repo} ({len(cs)} commits, {cs[-1][0]}..{cs[0][0]})")
    for d,m in cs: print(f"  {d} {m}")
PY
```

- **JSON はファイルに出力してから Python で集計する。** heredoc スクリプトへ pipe すると stdin が
  競合し、gh の JSON がスクリプトとして実行されて `NameError: name 'false'` 等になる。
  引数でファイルパスを渡すこと（上記のように複数パスを渡してマージできる）。
- リポジトリごとにコミット数と成果を要約する。

### 3. Qiita投稿（直近1ヶ月） — WebFetch でクロール

**Qiita API (v2) は使わない。WebFetch でクロールする。**

- **プロフィールページ `https://qiita.com/sigma_devsecops` はJS描画のため使わない。**
  WebFetch では投稿フィードが取れず、「ピックアップ」の古い人気記事（数年前）しか返ってこない。
- 代わりに **RSSフィード `https://qiita.com/sigma_devsecops/feed.atom`** をクロールする。
  これはサーバー側で最新記事が返るのでタイトル・URL・published/updated 日付を確実に取得できる
  （API v2 ではなく通常の fetch 対象）。
- フィードから開始日以降のエントリだけを抽出する（RSSは直近数件しか含まないことがある点に留意）。

### 4. 個人ブログ — WebFetch

`https://ryosukedtomita.github.io/myblog/` を WebFetch し、直近1ヶ月の記事・更新を抽出する。

### 5. ふりかえりノートを作成

保存先: `~/obsidian/Permanent/furikaeri/monthly/<yyyy-mm>.md`（対象月）。

frontmatter:

```
---
created: <今日の日付 YYYY-MM-DD>
author: sigma
tags:
  - ふりかえり
---
```

本文は収集したデータをもとに1ヶ月間の出来事を一覧にする。**4つの大項目を以下の順**で並べ、
**各大項目の区切りとして `---`（水平線）を入れる**（4つの大項目の前にそれぞれ `---` を置き、
合計4つの区切りを入れる）:

```
（先頭にサマリー等）

---

## GitHub — リポジトリごとのコミット/成果の要約

---

## Qiita — 投稿記事の一覧（タイトル + URL + 投稿日）

---

## myblog — 記事/更新の一覧

---

## Obsidian — 作成したノートの一覧（日付順、`[[ノート名]]` リンク。テーマ別に小見出し）
```

最後に `## まとめ` として1ヶ月の総括を数行で書く（まとめは4区切りの外でよい）。

Write でファイルを作成し、保存先パスと収集件数をユーザーに報告する。

## 表記規約（重要）

- 水平線は **4つの大項目（GitHub / Qiita / myblog / Obsidian）の区切りにのみ** 使い、
  文字は `---`（3文字）を使う（`___` や `***` は使わない）。それ以外の細かい区切りには使わない。
- 括弧は半角 `()`、前後にスペースを入れない。
- 日本語と隣り合う英字・識別子・型名・`O(n)` 記法・数値の間はスペースを入れない（詰める）。
  ただし英単語が地の文の語句・接続詞として現れる場合は自然な英語としてスペースを残す。
- 同名ファイルが既にあれば上書きせず、内容を確認してから追記/更新するかユーザーに確認する。
