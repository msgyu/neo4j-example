# Step 6. 後片付け

ハンズオンが終わったらコンテナとボリュームを削除し、ローカル環境をクリーンアップします。

```bash
docker compose -f docker/compose.yml down -v
```

- `-v` を付けると `neo4j_data`/`neo4j_logs` ボリュームも削除され、次回実行時は空の状態から再構築されます。
- もう一度ハンズオンを実行したい場合は Step 1 からやり直してください。
