# Step 5. 構造を拡張するミニ課題

1. `docs/GRAPH_GETTING_STARTED.md` の「構造を拡張するには」を読み、追加したいノード/リレーション（例: Tag）を決める。
2. 必要なデータを CSV として `data/` 配下に作成（例: `data/tags_mock.csv`）。
3. `scripts/poc_seed.cypher` の末尾に `LOAD CSV` ブロックを追加し、ノード作成・リレーション付与を記述。
4. Step 2 のシードコマンドを再実行し、`MATCH (t:Title)-[:HAS_TAG]->(tag)` などのクエリで反映を確認。
5. 変更内容は `git diff` で確認し、必要ならドキュメントに手順を追記。

小さな変更でも必ず Neo4j Browser で実データを見て検証しましょう。
