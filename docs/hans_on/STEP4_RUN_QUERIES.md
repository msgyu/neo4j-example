# Step 4. サンプルクエリを実行する

端末から `cypher-shell` を使えば、複数のクエリをスクリプトのように実行できます。以下は代表例です。

```bash
# ユーザー1が好きな出演者を経由しておすすめを取得
cat <<'CYPHER' | docker compose -f docker/compose.yml exec -T neo4j \
  cypher-shell -u neo4j -p localtest
MATCH (u:User {user_id: '1'})-[:LIKES_PERSON]->(p)<-[:FEATURES]-(t:Title)
RETURN p.name AS favorite, collect(t.title)[0..5] AS recommended;
CYPHER
```

```bash
# 作品「Fullmetal Alchemist: Brotherhood」（ID:5114）の類似作品
cat <<'CYPHER' | docker compose -f docker/compose.yml exec -T neo4j \
  cypher-shell -u neo4j -p localtest
MATCH (src:Title {title_id: '5114'})-[r:SIMILAR_TO]->(dst)
RETURN src.title AS source, dst.title AS similar, r.score
ORDER BY r.score DESC;
CYPHER
```

必要に応じて Neo4j Browser のグラフビューでもクエリを実行し、パス構造を確認してください。

```bash
# 出演者の重みを使って似た作品を探す（"Kimi no Na wa." から）
cat <<'CYPHER' | docker compose -f docker/compose.yml exec -T neo4j \
  cypher-shell -u neo4j -p localtest
MATCH (:Title {title_id: '32281'})-[f:FEATURES]->(p:Person)
WITH p, f.weight AS baseWeight
MATCH (p)<-[f2:FEATURES]-(other:Title)
WHERE other.title_id <> '32281'
WITH other, sum(baseWeight * coalesce(f2.weight, 1.0)) AS score
RETURN other.title AS candidate, score
ORDER BY score DESC LIMIT 10;
CYPHER
```
```
