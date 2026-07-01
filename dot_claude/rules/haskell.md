## Haskell

- ワークフロー終了時に `ghc` / `runghc` が生成した中間ファイル (`*.hi`, `*.o`, 実行ファイル) を削除してから報告すること。`runghc` は通常残さないが、`ghc` を使った場合 (例: `-Wall` チェック) は必ず掃除する。
- ポイントフリースタイルはなるべく使わない。
- qualified importを使用する際にはimportしたのがなにかわかりやすくする。 e.g. NG例: `import Data.Set qualified as S` 良い例: `import Data.Set qualified as Set`
- 関数の型定義は必ず書く。
- `Data.Array` よりも `Data.Vector` を優先する。ただし2次元配列（タプル添字のグリッド等）は、添字をタプルで自然に書ける `Data.Array` の使用を検討する。
- パフォーマンス上問題がない場合、モナド/do 記法よりも純粋関数を優先する。
- `{-# OPTIONS_GHC -Wunused-imports #-}`を基本的につける。
- 視認性の問題から、`()`よりも`$`を好む
