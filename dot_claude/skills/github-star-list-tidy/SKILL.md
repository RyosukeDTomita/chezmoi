---
name: github-star-list-tidy
description: GitHubのstarのうち、どのstar listにも入っていない「未分類star」を洗い出し、確認のうえでstar解除するか任意のlistへ振り分ける。star listsはREST APIに存在しないため、GraphQLの `viewer.lists` / `updateUserListsForItem` を使う。集合演算だけで判定するので冪等で、定期実行してstar一覧を整理された状態に保てる。
when_to_use: ユーザーが「どのstar listにも入っていないstarを外したい」「star listsを整理したい」「未分類のstarを一覧にしたい」「starの棚卸し」などGitHubのstar/star listsの整理を求めたとき。
argument-hint: [--dry-run]
allowed-tools: Bash
---

# 未分類のstarを棚卸しする

GitHubの **star lists** はREST APIに存在せず、GraphQLの `viewer.lists` からしか読めない。
star一覧 (REST) との差集合をとって「どのlistにも入っていないstar」を出し、ユーザーの確認後に解除/振り分けする。

## 前提: gh CLIのスコープ

| 操作 | 必要スコープ |
| --- | --- |
| star一覧の取得 / star解除 (`DELETE /user/starred/{owner}/{repo}`) | `repo` |
| star listsの読み取り (`viewer.lists`) | `repo` |
| star listsへの追加 (`updateUserListsForItem`) | **`user`** |

list への追加をする場合だけ `user` スコープが要る。足りなければブラウザ認証が要るので、ユーザー自身に実行してもらう:

```
! gh auth refresh -h github.com -s user
```

## 手順

作業ファイルはスクラッチパッドに置く。

### 1. star listsの中身を取得

`items` は1リスト最大100件までまとめて取れる。`hasNextPage` が `true` のリストがあればそこだけ追加取得する。

```bash
gh api graphql -f query='{ viewer { lists(first:30) { nodes { id name
  items(first:100) { totalCount pageInfo{hasNextPage}
    nodes { ... on Repository { nameWithOwner } } } } } } }' > lists.json

jq -r '[.data.viewer.lists.nodes[].items.nodes[].nameWithOwner] | unique | .[]' lists.json \
  | sort -u > in_lists.txt
jq -r '.data.viewer.lists.nodes[] | "\(.name)\t\(.items.totalCount)\t\(.items.pageInfo.hasNextPage)"' lists.json
```

### 2. star一覧を取得して差集合をとる

```bash
gh api user/starred --paginate -q '.[].full_name' | sort -u > starred.txt
comm -13 in_lists.txt starred.txt > to_unstar.txt   # 未分類 = star済み かつ どのlistにも無い
comm -23 in_lists.txt starred.txt                   # 参考: listにあるがstarしていない
```

### 3. ユーザーに確認する

**star解除は実行前に必ず確認する** (取り消しが効かない破壊的操作)。`AskUserQuestion` で件数と一覧を示す。

自分のrepo (`<自分のlogin>/*`) は別枠として集計して見せる — 自作repoへのstarはlist未分類になりがちなので、
「全部解除」「自分のrepoだけ `myself` のようなlistへ振り分け」のどちらかをユーザーに選ばせる。
どちらでもよいので勝手に決めない (listへの振り分けは `user` スコープが要る分、手間が増える)。

`--dry-run` が渡されたときは一覧の提示だけで止める。

### 4a. star解除

```bash
while read -r r; do
  gh api -X DELETE "user/starred/$r" --silent && echo "OK $r" || echo "FAIL $r"
done < to_unstar.txt
```

### 4b. listへ追加

`listIds` は **置換** なので、そのrepoが所属するlist全体を渡す (未分類repoなら追加先だけでよい)。
GraphQL変数の型は `[ID!]!` — `[ID]!` と書くと `Nullability mismatch` で落ちる。

```bash
LIST_ID=$(gh api graphql -f query='{ viewer { lists(first:30){ nodes{ id name } } } }' \
  -q '.data.viewer.lists.nodes[] | select(.name=="myself") | .id')

while read -r r; do
  id=$(gh api graphql -f query='query($o:String!,$n:String!){repository(owner:$o,name:$n){id}}' \
    -F o="${r%%/*}" -F n="${r##*/}" -q '.data.repository.id')
  gh api graphql -f query='mutation($i:ID!,$l:[ID!]!){
    updateUserListsForItem(input:{itemId:$i,listIds:$l}){item{... on Repository{nameWithOwner}}}}' \
    -F i="$id" -F l="$LIST_ID"
done < mine.txt
```

### 5. 検証

star一覧を取り直し、`comm -13 in_lists.txt` の結果が空 (または意図した残りだけ) になっていることを確認して報告する。

## 注意

- listに入っているrepoは重複を除いて数えるため、list項目の総和 > ユニーク数になる。
- 削除/リネームされたrepoは `starred.txt` と `in_lists.txt` で表記がずれることがある。差分に見覚えのない項目が出たらユーザーに確認する。
