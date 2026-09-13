---
name: insight-save-obsidian
description: Claude Code InsightsのHTMLレポートを日本語化し、Obsidianの Permanent/ai/ 配下に既存フォーマットで保存する。「Insightsレポートを日本語にして保存」「/insight-save-obsidian」と言われたときに使う。
when_to_use: ユーザーが Claude Code Insights の HTML レポート（~/.claude/usage-data/report-*.html）を日本語化して Obsidian に保存したいとき。
argument-hint: [HTMLレポートのパス (省略時は最新)]
allowed-tools: Bash Read Write
---

# Insight を日本語化して Obsidian に保存

Claude Code Insights の HTML レポートを読み取り、日本語のマークダウンに変換して
Obsidian vault (`~/obsidian/Permanent/ai/`) に既存のふりかえりファイルと同じフォーマットで保存する。

## 手順

1. **対象HTMLを特定する**
   - 引数でパスが渡されていればそれを使う（`file://` プレフィックスや `#section-...` アンカーは除去する）。
   - 渡されていなければ最新のレポートを使う:
     `ls -t ~/.claude/usage-data/report-*.html | head -1`

2. **HTMLを Read する**。以下の情報を抽出する:
   - 期間（例: `2026-06-08 to 2026-07-01`）と メッセージ数・セッション数
   - At a Glance（What's working / What's hindering / Quick wins / Ambitious workflows）
   - Stats（Messages, Sessions, Lines, Files, Days, Msgs/Day 等、レポートにある項目のみ）
   - What You Work On（各プロジェクト領域とセッション数・説明）
   - How You Use Claude Code（ナラティブ + Key pattern）
   - Top Tools Used / Languages / Session Types（表として）
   - Impressive Things You Did（各項目）+ What Helped Most / Outcomes（表）
   - Where Things Go Wrong（各カテゴリ + 例）+ Primary Friction Types（表）
   - Suggested CLAUDE.md Additions（コードブロック + Why）
   - Features to Try / Usage Patterns to Try（Copyable prompt 含む）
   - On the Horizon（各カード + Copyable prompt）
   - Fun Ending

3. **保存先ファイル名**は期間から `<開始>_<終了>.md`（例: `2026-06-08_2026-07-01.md`）とし、
   `~/obsidian/Permanent/ai/` に置く。

4. **フォーマット**は既存ファイル（`~/obsidian/Permanent/ai/2026-06-08_2026-07-01.md` や
   `2026-04-18_2026-05-18.md`）を参考にし、同じ構成で書く:
   - frontmatter:
     ```
     ---
     created: <終了日 YYYY-MM-DD>
     author:
       - claude
     tags:
       - claude-insights
       - ふりかえり
       - AI
     description: Claude Code Insightsレポート（<開始>〜<終了>）
     ---
     ```
   - 見出しは英語のセクション名を残す（`## At a Glance`, `## Impressive Things You Did` など）。
   - 本文・統計表・Copyable prompt はすべて日本語にする。

5. Write でファイルを作成し、保存先パスと含めたセクションをユーザーに報告する。

## 表記規約（重要）

- マークダウンの水平線は使わない。区切りは見出しで表現する（`---` は frontmatter のみ）。
- 括弧は半角 `()`、前後にスペースを入れない。
- 日本語と隣り合う英字・識別子・型名・`O(n)` 記法・数値の間はスペースを入れない（詰める）。
  ただし英単語が地の文の語句・接続詞として現れる場合は自然な英語としてスペースを残す。
- コード片・式の内部のスペースはそのまま残す。
- 固有名詞・技術用語（foldr, Set.empty, Sigstore, ByteString 等）はそのまま英語で残す。
- HTML内の統計値は改変せずそのまま転記する。レポートに無い項目（Hours 等）は表に入れない。
