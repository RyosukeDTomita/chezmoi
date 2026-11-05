# 0001. Zedの拡張機能はUIからインストールする

- Status: Accepted
- Date: 2026-11-05

## Context

macOSのZedに `haskell` と `solarized` の拡張機能を入れる際、`settings.json` の `auto_install_extensions` で宣言的に管理しようとした。

```json
"auto_install_extensions": {
  "html": true,
  "haskell": true,
  "solarized": true
}
```

設定を書いても拡張機能はインストールされず、`theme not found: Solarized Dark` のエラーが続いた。

- Zedの起動中に設定を書き換えても、インストールは始まらなかった(約15秒待って確認)。
- ウィンドウを閉じて開き直しても、インストールされなかった。macOSのZedはウィンドウを閉じてもプロセスが終了しない。
- `Zed > Quit Zed` で完全に終了してからの再起動は試していない。そのため、再起動すれば効くかどうかは未確認。

一方、Extension Gallery(`cmd-shift-x`)からは即座にインストールできた。

## Decision

Zedの拡張機能はExtension GalleryからUIで手動インストールし、`auto_install_extensions` はchezmoi管理の設定に含めない。

## Consequences

- 新しいマシンでは `chezmoi apply` の後に、次の拡張機能を手動でインストールする必要がある。
  - `haskell`
  - `solarized`
- `solarized` を入れるまでは、macOSのダークテーマ(`Solarized Dark`)が見つからず `theme not found` になる。
- インストール済みの拡張機能は `~/Library/Application Support/Zed/extensions/installed/` で確認できる。
- 完全な再起動で `auto_install_extensions` が効くと確認できた場合は、このADRを見直す。
