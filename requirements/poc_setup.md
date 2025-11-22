# Neo4j PoC セットアップ手順

この手順では Kaggle のアニメデータとモック出演者データを Neo4j に投入し、レコメンド検証用のグラフを作成します。

## 1. 事前準備
- Docker / Docker Compose v2 が動作していること。
- Kaggle からダウンロードした `archive.zip` を `data/` 直下に配置し、`unzip archive.zip -d data/kaggle` で `anime.csv` と `rating.csv` を展開しておく（または `example_data/kaggle-data/*.csv` をコピー）。`rating.csv` は巨大なため `head -n 50001 data/kaggle/rating.csv > data/kaggle/rating_sample.csv` でサンプルを作成済み。
- `.env` で `NEO4J_AUTH=neo4j/localtest` などデフォルト資格情報を確認。

## 2. Neo4j を起動
```bash
# リポジトリルートで実行
docker compose -f docker/compose.yml up -d
```
- ブラウザ: http://localhost:7474
- Bolt: `bolt://localhost:7687`

## 3. Seed スクリプトを流し込む
`scripts/poc_seed.cypher` は以下を自動化します。
1. ノード制約の作成
2. `data/kaggle/anime.csv` から Title / Genre を生成
3. `data/kaggle/rating_sample.csv` から User / INTERACTED_WITH を生成（必要に応じてサンプルサイズを変更）
4. `data/persons_mock.csv` と `data/title_person_features_mock.csv` から Person / FEATURES を生成
5. `data/user_likes_person_mock.csv` で LIKES_PERSON を生成
6. `data/title_similar_mock.csv` で SIMILAR_TO を生成

実行手順:
```bash
docker compose -f docker/compose.yml exec neo4j \
  cypher-shell -u neo4j -p localtest -f /workspace/scripts/poc_seed.cypher
```
完了すると Neo4j Browser の `:schema` でノード/リレーションが確認できます。

## 4. 動作確認用クエリ例
```cypher
// あるユーザーが好きな出演者を介して作品を探す
MATCH (u:User {user_id: '1'})-[:LIKES_PERSON]->(p)<-[:FEATURES]-(t:Title)
RETURN u.user_id AS user, p.name AS liked_person, t.title AS recommended
LIMIT 5;

// 類似作品パス
MATCH (t:Title {title_id: '5114'})-[r:SIMILAR_TO]->(other)
RETURN t.title AS source, other.title AS similar, r.score
ORDER BY r.score DESC;
```

## 5. データをリセットしたい場合
```bash
# データ削除
docker compose -f docker/compose.yml down -v
# 再起動後に再度シード
```

この PoC をベースに、出演者データやエピソード情報を追加すれば本番要件へ拡張できます。
