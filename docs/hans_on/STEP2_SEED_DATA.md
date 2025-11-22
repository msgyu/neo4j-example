# Step 2. データを投入する

`scripts/poc_seed.cypher` にはノード制約作成・CSV 取込み・モック出演者登録がまとまっています。Docker コンテナ内で `cypher-shell` を実行して流し込みます。

```bash
docker compose -f docker/compose.yml exec neo4j \
  cypher-shell -u neo4j -p localtest -f /workspace/scripts/poc_seed.cypher
```

- 成功するとコンソール出力はなく、Neo4j Browser で `MATCH (n) RETURN count(n)` などを実行するとデータが反映されています。
- `Cannot load from URL` 等のエラーが出た場合は `docs/GRAPH_GETTING_STARTED.md` のトラブルシューティングを参照し、`docker/neo4j.env` やマウント設定を確認してください。
