---
name: attach-local-chrome
description: Attach playwright-cli to the user's everyday local Chrome over CDP so browser automation runs inside their already-logged-in session (cookies, extensions, and signed-in services like Qiita/Google/GitHub all preserved). Use this whenever a task needs the user's authenticated browser state instead of a fresh, logged-out automation browser.
when_to_use: When a task requires the user's real login session in the browser (e.g. "use my logged-in Chrome", "stock my Qiita articles", "post/like/bookmark while signed in", "operate the site I'm already logged into"). Prefer this over a clean playwright-cli/chrome-devtools session, which starts logged out.
allowed-tools: Bash Read
---

# Attach playwright-cli to the everyday local Chrome

Drive the user's normal, already-logged-in Chrome with `@playwright/cli` over CDP. The login session, cookies, and extensions are preserved — no separate login needed. Based on the `attach --cdp=chrome` channel feature (Chrome 144+, playwright-cli v0.1.8+).

## Why this skill exists

A fresh `playwright-cli open` or `chrome-devtools-mcp` session uses an isolated profile that is **logged out** of everything. Attaching to the running Chrome reuses the user's real session.

## Resolve the CLI command first

`playwright-cli` is usually not installed globally. Pick the invocation that works and use it consistently:

```bash
# Prefer a local/global binary if present
npx --no-install playwright-cli --version 2>/dev/null \
  || npx -y @playwright/cli@latest --version
```

In the steps below, `playwright-cli` means "whichever of `playwright-cli` / `npx playwright-cli` / `npx -y @playwright/cli@latest` resolved above." Reuse the same form for every command.

## Two one-time, user-only actions

These cannot be automated (the browser isn't attached yet, and `chrome://` toggles plus the approval prompt require the human). Ask the user to do them:

1. **Enable remote debugging in their Chrome.** Open `chrome://inspect/#remote-debugging` and turn on **"Allow remote debugging for this browser instance."** (Per-instance; may need redoing after a full Chrome restart.)
2. **Approve the connection.** On the first `attach`, Chrome shows a connection-approval prompt — the user must accept it. While attached, Chrome displays "Chrome is being controlled by automated test software."

Tell the user these are required, then wait for confirmation before attaching.

## Attach

```bash
playwright-cli attach --cdp=chrome      # auto-resolves the WS endpoint via the DevToolsActivePort file
# msedge: playwright-cli attach --cdp=msedge
# explicit endpoint: playwright-cli attach --cdp=http://localhost:9222
```

Verify and orient by listing the user's existing tabs:

```bash
playwright-cli tab-list
```

## Operate without disrupting the user

The attached browser is the user's live window with their real tabs. Be considerate:

- **Open a fresh tab for your work** instead of hijacking a tab they're using:
  ```bash
  playwright-cli tab-new https://qiita.com/
  playwright-cli tab-list          # note the new tab's index
  playwright-cli tab-select <idx>  # focus it before acting
  ```
- Drive with snapshot refs:
  ```bash
  playwright-cli snapshot
  playwright-cli click e15
  playwright-cli fill e5 "text" --submit
  ```
- Close only the tabs you opened (`playwright-cli tab-close <idx>`), never the user's.

## Detach — never `close` the user's browser

When done, **detach** to leave the user's Chrome running with all tabs intact:

```bash
playwright-cli detach
```

Do **not** run `playwright-cli close` / `close-all` / `kill-all` on an attached everyday browser — those terminate the user's real Chrome and lose their tabs. `close` is only for browsers this CLI launched itself via `open`.

## Caveats

- Security: only enable remote debugging on a trusted local machine — the debug endpoint can expose session credentials.
- If `attach` fails with no endpoint, the remote-debugging toggle (step 1) is likely off, or Chrome was restarted since it was enabled.
- If multiple Chrome channels/instances run, pass an explicit `--cdp=http://localhost:<port>`.

## Full reference

The complete playwright-cli command reference (all subcommands, snapshots, storage, network, tracing) ships with the package:

```bash
find ~/.npm/_npx -name SKILL.md -path '*cli-client*' 2>/dev/null | head -1
```

Read that file when you need a command not covered here.
