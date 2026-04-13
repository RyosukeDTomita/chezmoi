---
name: haskell-interact-io
description: Write Haskell competitive-programming solutions with input handled by `interact` or `BS.interact`. Use when a user requests this I/O style explicitly, when solving AtCoder-like stdin/stdout problems in Haskell, or when refactoring existing code to one-pass string/bytestring transformation style.
---

# Haskell Interact Io

## Workflow

1. Determine parser mode.
- Use `interact` with `String` for simple token counts and short input.
- Use `Data.ByteString.Char8` + `BS.interact` for large input or performance-sensitive tasks.

2. Build solution as pure transform.
- Implement `solve :: InputType -> OutputType` as a pure function.
- Parse all stdin in one shot, transform once, format once.

3. Emit output through interact API.
- `main = interact (render . solve . parse)` for `String`.
- `main = BS.interact (render . solve . parse)` for `ByteString`.

## Templates

### String (`interact`)

```haskell
main :: IO ()
main = interact (unlines . solve . map read . words)

solve :: [Int] -> [String]
solve xs = [show (sum xs)]
```

### ByteString (`BS.interact`)

```haskell
import qualified Data.ByteString.Char8 as BS
import Data.Maybe (fromJust)

main :: IO ()
main = BS.interact (render . solve . parse)

parse :: BS.ByteString -> [Int]
parse = map (fst . fromJust . BS.readInt) . BS.words

solve :: [Int] -> Int
solve = sum

render :: Int -> BS.ByteString
render x = BS.pack (show x ++ "\n")
```

If using `fromJust`, ensure inputs are guaranteed valid by problem constraints.

## ByteString Parsing Rules

- Prefer `BS.words` + `BS.readInt` for integer token streams.
- Keep parsing total whenever possible.
- For matrix/tuple inputs, parse flat tokens first, then reshape in `solve`.

## Output Rules

- Return a trailing newline for single-line outputs.
- Use `unlines` for multi-line outputs.
- Keep formatting logic isolated in `render` for non-trivial outputs.

## Refactor Checklist

- Convert imperative `getLine` chains to one-shot parse.
- Keep algorithm logic independent from I/O layer.
- Preserve exact output format before and after refactor.
