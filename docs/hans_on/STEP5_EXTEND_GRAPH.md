# Step 5. 構造を拡張するミニ課題

1. `docs/GRAPH_GETTING_STARTED.md` の「構造を拡張するには」を読み、追加したいノード/リレーション（例: Tag）を決める。
2. 必要なデータを CSV として `data/` 配下に作成（例: `data/tags_mock.csv`）。
3. `scripts/poc_seed.cypher` の末尾に `LOAD CSV` ブロックを追加し、ノード作成・リレーション付与を記述。
4. Step 2 のシードコマンドを再実行し、`MATCH (t:Title)-[:HAS_TAG]->(tag)` などのクエリで反映を確認。
5. 変更内容は `git diff` で確認し、必要ならドキュメントに手順を追記。

小さな変更でも必ず Neo4j Browser で実データを見て検証しましょう。

## 出演者データを実データに置き換えるには？
1. AniList や Jikan (MyAnimeList API) などから作品 ID（`anime_id` と一致）を使ってキャスト情報を取得。
2. `person_id,name,type` の CSV と `title_id,person_id,...` の CSV を生成し、`data/` 配下に保存。
3. `scripts/poc_seed.cypher` の既存 `FEATURES` 取込み部分を差し替え、`make seed` で再投入。

外部 API を呼べない環境では `data/title_person_features_mock.csv` のように手動で出演者を複数作品にまたがって登録します。それも難しい場合は、ユースケース 3 で紹介している `SIMILAR_TO` やジャンル類似クエリを代替案として利用してください。
