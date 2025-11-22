# Graph Recommendation PoC ガイド

このドキュメントは、Neo4j と Kaggle アニメデータを使ってレコメンド用グラフを構築・拡張する手順を初心者向けにまとめたものです。Docker での起動から、構造を追加する方法、最適化のヒントまで順番に解説します。

## 1. 目的と全体像
- Kaggle `anime.csv` と（メモリ節約のために切り出した）`rating_sample.csv` を取り込み、`User`・`Title`・`Genre`・`Person` などのノードと `INTERACTED_WITH`・`HAS_GENRE`・`FEATURES` などのリレーションを構築。
- モック出演者データを追加し、出演者ベース/ジャンルベース/類似度ベースのレコメンドを検証。
- 追加データ（例: エピソード詳細、タグ）を段階的に加え、最適化も自分で行えるようにする。

## 2. セットアップ手順
1. 依存ツール: Docker / Docker Compose、`cypher-shell`（Neo4j コンテナに同梱）。
2. データ配置: `example_data/kaggle-data` から `data/kaggle` にコピー済み。`rating_sample.csv` は `head -n 50001 rating.csv > rating_sample.csv` で生成し、PoC ではこちらを読み込みます。モックデータは `data/*.csv` に用意済み。
3. Neo4j 起動:
   ```bash
   docker compose -f docker/compose.yml up -d
   ```
4. データ投入（制約・ノード・リレーション）:
   ```bash
   docker compose -f docker/compose.yml exec neo4j \
     cypher-shell -u neo4j -p localtest -f /workspace/scripts/poc_seed.cypher
   ```
5. ブラウザ: `http://localhost:7474` にアクセスし、`:schema` や `MATCH (n) RETURN n LIMIT 50` でグラフを確認。

> トラブル時は `docker compose -f docker/compose.yml logs -f neo4j` でログを確認し、`docker compose down -v` でデータをリセットして再実行。

## 3. グラフ構造の読み方
- **User**: `user_id` をキーに `age_group`/`gender` を保持。`INTERACTED_WITH` で `Title` に結び付き、`rating`・`status`・`weight` で視聴行動を表現。
- **Title**: `title_id`（Kaggle の `anime_id`）、`episode_count`、`member_count`、`average_rating` など。`HAS_GENRE` でジャンル、`FEATURES` で出演者、`SIMILAR_TO` で類似作品に連結。
- **Person**: モック出演者。`type` に `voice_actor` などを保存。`LIKES_PERSON` でユーザー好みを表現。
- **Genre**: 文字列名でユニーク管理。`HAS_GENRE.kind` で `main/sub` を区別。
- **Tag/Episode**: 現時点は空だが、CSV を追加して `HAS_TAG` や `HAS_EPISODE` を作れば拡張できる。

## 4. 構造を拡張するには
### 4.1 新しいノードの追加
1. 入力データ（CSV/JSON）を `data/` へ配置。
2. `scripts/poc_seed.cypher` の末尾に `LOAD CSV` ブロックを追加。例: `Tag` を読み込む場合。
   ```cypher
   LOAD CSV WITH HEADERS FROM 'file:///workspace/data/tags.csv' AS row
   MERGE (tag:Tag {name: row.name})
   SET tag.kind = row.kind;
   ```
3. `HAS_TAG` 作成: `MATCH (t:Title {title_id: row.title_id}), (tag:Tag {name: row.name}) MERGE (t)-[:HAS_TAG {weight: ..}]->(tag)`。
4. スクリプトを再実行（既存ノードは `MERGE` で上書きされる）。

### 4.2 既存リレーションに重みを追加
- 例: `INTERACTED_WITH.weight` を評価値に比例させる。
  ```cypher
  SET rel.weight = CASE row.rating WHEN '-1' THEN 0.2 ELSE toFloat(row.rating)/10 END;
  ```
- ルールを変えたい場合は `poc_seed.cypher` の該当箇所を編集して再投入。

### 4.3 エピソード情報の統合
- 別 API/CSV から `episode_id, title_id, episode_number, season_number, title_local` を取得し、`data/episodes.csv` を作成。
- `HAS_EPISODE` で `Title` と結び付ける。
- 視聴履歴を `Episode` 単位で保存する場合は `INTERACTED_WITH` の `to` ノードを `Episode` に変更し、集計クエリで `Episode→Title` を辿る。

## 5. グラフを最適化するコツ
1. **制約（Constraint）/インデックス**
   - 既に `User.user_id`, `Title.title_id`, `Genre.name`, `Person.person_id` にユニーク制約を付与済み。
   - `Tag.name` や `Episode.episode_id` を追加したら同様に `CREATE CONSTRAINT` を追加。
2. **リレーションの冗長化**
   - よく使う類似度やユーザー好みを前計算して `SIMILAR_TO`, `LIKES_PERSON` に保存するとクエリが軽くなる。
3. **サブグラフの分割**
   - テスト中は `MATCH (n) DETACH DELETE n` で一度全削除し、小さい範囲で検証するのも有効。
4. **Cypher チューニング**
   - `PROFILE` や `EXPLAIN` を Neo4j Browser で実行し、ボトルネック（NodeByLabelScan など）があればインデックス追加を検討。
5. **データクレンジング**
   - Kaggle の `genre` には HTML エスケープ（`&#039;`）が含まれることがあるため、`replace(row.genre,'&#039;','')` などで整形すると分析精度が上がる。

## 6. サンプルクエリ集
```cypher
// ユーザーが視聴済み作品とジャンル
MATCH (u:User {user_id: '1'})-[r:INTERACTED_WITH]->(t:Title)-[:HAS_GENRE]->(g:Genre)
RETURN t.title, g.name, r.rating LIMIT 10;

// 好きな出演者を経由して作品を推薦
MATCH (u:User {user_id: '1'})-[:LIKES_PERSON]->(p)<-[:FEATURES]-(t:Title)
RETURN p.name AS favorite, collect(t.title)[0..5] AS recommended;

// 類似作品を探索
MATCH (src:Title {title_id: '5114'})-[r:SIMILAR_TO]->(dst)
RETURN src.title AS source, dst.title AS similar, r.score
ORDER BY r.score DESC LIMIT 5;
```

## 7. 変更履歴
- 2024-06: PoC 初版（Kaggle + モック出演者 + 類似作品）を作成。
- 今後: Episode/Tag/実出演者データの統合、`seed` スクリプト自動化を予定。

## 8. トラブルシューティング
| 症状 | 原因 | 対処 |
| --- | --- | --- |
| `Cannot load from URL 'file:///...'` と表示され CSV を読み込めない | `server.directories.import` と `dbms.security.allow_csv_import_from_file_urls` がデフォルトのまま、または `/var/lib/neo4j/import` に CSV が届いていない | `docker/neo4j.env` で `NEO4J_dbms_directories_import=/var/lib/neo4j/import` と `NEO4J_dbms_security_allow__csv__import__from__file__urls=true` を設定し、`docker/compose.yml` で `../data:/var/lib/neo4j/import` をバインドする。変更後は `docker compose -f docker/compose.yml down -v` → `up -d` で再起動。 |
| コンテナ起動時に `chown: Read-only file system` | `import` ディレクトリを `:ro` でマウントしているため初期化処理で失敗 | `../data:/var/lib/neo4j/import` のマウントを read-write（デフォルト）にする。 |
| `dbms.memory.transaction.total.max threshold reached` でシードが停止 | `rating.csv` が大きく、メモリが不足 | `head -n 50001 data/kaggle/rating.csv > data/kaggle/rating_sample.csv` でサンプルを作成し、`scripts/poc_seed.cypher` を `rating_sample.csv` を読むよう編集。必要に応じてサンプル件数を調整。 |
| `USING PERIODIC COMMIT` がサポートされない | Neo4j 5.x から非推奨 | スクリプトから `USING PERIODIC COMMIT` を削除し、`LOAD CSV` 単体（または `CALL {...} IN TRANSACTIONS`）を使う。 |

---
質問や改善案があれば `requirements/poc_setup.md` と合わせて更新してください。
