---
name: qiita-stock-sync
description: Add all of a Qiita user's articles carrying a given tag/category to a PUBLIC stock list, idempotently and differentially — it enumerates the tag's articles via the public Qiita API, compares them against the list's current contents, and only stocks the ones that are missing (auto-creating the public list if needed, and removing the private "あとで読む" that Qiita auto-adds). Safe to re-run on a schedule to keep the list in sync as new articles are published.
when_to_use: When the user wants to put Qiita articles of a specific tag/category into a public stock list, or to "差分更新 / 定期更新 / sync" such a list (e.g. "Haskellタグの記事を公開ストックに追加", "公開ストックリストを最新に同期"). Pairs with the loop / schedule skills for recurring runs.
argument-hint: [tag] [list-name]
allowed-tools: Bash Read
---

# Sync a Qiita tag into a public stock list

Keeps a Qiita **public stock list** in sync with every article a user has published under a given tag. Idempotent: only the articles missing from the list are stocked, so re-running just picks up newly published ones.

## Prerequisite: an attached, logged-in Chrome

Stocking needs the user's login. Connect their everyday Chrome first (see the **attach-local-chrome** skill):

```bash
npx -y @playwright/cli@latest attach --cdp=chrome
```

(The user must have enabled `chrome://inspect/#remote-debugging` → "Allow remote debugging for this browser instance" and approved the connection prompt.) The script aborts with guidance if no `chrome` session is attached. When finished, leave Chrome running with `npx -y @playwright/cli@latest --s=chrome detach` (never `close`).

## Run

```bash
QIITA_USER=sigma_devsecops TAG=Haskell LIST_NAME="sigma's Haskell Articles" \
  bash "$CLAUDE_SKILL_DIR/sync.sh"
```

Confirm the three values with the user before the first run (especially the **exact** `LIST_NAME` — it must match the on-screen list name, since the stock dialog targets the checkbox labelled `公開 <LIST_NAME>`).

Options (env vars):

| Var | Default | Meaning |
|-----|---------|---------|
| `QIITA_USER` | — | username whose articles to enumerate |
| `TAG` | — | tag/category, case-insensitive |
| `LIST_NAME` | — | exact public stock list name (created if missing) |
| `REMOVE_LATER` | `1` | strip the private "あとで読む" Qiita auto-adds on first stock |
| `CREATE_IF_MISSING` | `1` | auto-create the public list when not found |

## What it does

1. Enumerates the user's articles with `TAG` via the public API (`/api/v2/users/<user>/items`) — no auth needed for this read.
2. Finds the public list URL from `https://qiita.com/<user>/stocks` by matching `LIST_NAME`; creates it (public) via the stock dialog if absent.
3. Reads the list's current article IDs (paginated) and diffs against the target set.
4. For each missing article: opens it, opens the stock dialog, ticks the `公開 <LIST_NAME>` checkbox, and (by default) unticks the auto-added "あとで読む".
5. Prints `added=N failed=M (target=… already=…)`.

It interacts via the proven **snapshot → grep ref → click** method (playwright-cli's in-page locators by aria-label are unreliable on Qiita's stock dialog — the dialog has no accessible name and the custom checkboxes report as not-visible, so name/role waits time out; matching `ref=e…` from the snapshot is what works).

## Periodic / differential updates

The script is idempotent, so recurring runs only add new articles:

- Ad-hoc: just re-run the command above.
- Recurring in this session: use the **loop** skill, e.g. `/loop` with this command.
- Scheduled remote runs: use the **schedule** skill. Note the prerequisite — a scheduled run still needs an attached logged-in Chrome on the machine that executes it, so headless/remote scheduling only works where that session exists.

## Caveats

- `LIST_NAME` containing spaces or apostrophes is fine — pass it quoted.
- If a target article is already stocked elsewhere, its other lists are left untouched; only the public list (added) and "あとで読む" (removed when `REMOVE_LATER=1`) change.
- The list-pagination read stops when a page yields no new IDs; the per-article checkbox-state check is the safety net against double-adds.
- Throttle/politeness: there is a short sleep between page loads; for very large tags this run can take a while.
