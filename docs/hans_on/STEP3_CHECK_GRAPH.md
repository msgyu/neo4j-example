# Step 3. グラフを可視化して確認する

Neo4j Browser (http://localhost:7474) にアクセスし、以下を順番に実行してデータが投入されたか確認します。

1. `:schema` … 作成済みのインデックス/制約を確認。
2. `MATCH (n) RETURN n LIMIT 25;` … 全体をざっと見る。
3. `MATCH (t:Title) RETURN count(t);` でタイトル件数、`MATCH ()-[r:INTERACTED_WITH]->() RETURN count(r);` で視聴リレーション件数をチェック。

グラフ表示で乱雑に見える場合はフィルター（例: `MATCH (u:User {user_id:'1'})-->...`）を活用してください。

## ユースケース別サンプルクエリ

### ユースケース1: カタログ全体の把握とジャンル傾向
作品全体のジャンル分布や代表作を把握し、カテゴリ別レコメンドのベースラインを作成します。

```cypher
// ジャンルごとの作品数を把握
MATCH (:Title)-[:HAS_GENRE]->(g:Genre)
RETURN g.name AS genre, count(*) AS title_count
ORDER BY title_count DESC LIMIT 10;
```

```cypher
// 特定ジャンル（例: "Drama"）に属する作品一覧
MATCH (t:Title)-[:HAS_GENRE]->(g:Genre {name: 'Drama'})
RETURN t.title AS title, t.type AS type, t.average_rating AS rating
ORDER BY rating DESC LIMIT 20;
```

### ユースケース2: ユーザー嗜好に合わせたジャンル推薦
ユーザーの視聴傾向から好きなジャンルを抽出し、未視聴作品を提案します。

```cypher
// ユーザー1が視聴済みの作品と重み確認
MATCH (u:User {user_id: '1'})-[r:INTERACTED_WITH]->(t:Title)
RETURN u.user_id AS user, t.title AS title, r.kind, r.rating, r.weight
ORDER BY r.weight DESC LIMIT 10;
```

クエリを実行したら `Graph` ビューでパスを確認し、必要に応じて `Table` ビューで `properties` をチェックすると理解が深まります。

```cypher
// ユーザー1がよく視聴するジャンルからおすすめ候補を抽出
MATCH (u:User {user_id: '1'})-[r:INTERACTED_WITH]->(t:Title)
MATCH (t)-[:HAS_GENRE {kind: 'main'}]->(g:Genre)
WITH u, g.name AS favoriteGenre, avg(r.weight) AS genreScore
ORDER BY genreScore DESC LIMIT 1
WITH favoriteGenre
MATCH (t:Title)-[:HAS_GENRE {kind: 'main'}]->(g:Genre {name: favoriteGenre})
WHERE NOT EXISTS { MATCH (:User {user_id: '1'})-[:INTERACTED_WITH]->(t) }
RETURN favoriteGenre AS genre, t.title AS candidate, t.average_rating
ORDER BY t.average_rating DESC LIMIT 10;
```

```cypher
// 特定ジャンルの作品を絞り込み（例: "Action"）
MATCH (t:Title)-[:HAS_GENRE {kind: 'main'}]->(g:Genre {name: 'Action'})
RETURN t.title AS title, t.average_rating AS rating
ORDER BY rating DESC LIMIT 10;
```

### ユースケース3: 作品詳細から関連データを掘り下げる
作品単体の出演者やジャンル、類似作品を調べ、関連コンテンツへの動線を作ります。

```cypher
// 作品「Kimi no Na wa.」の出演者・ジャンル
MATCH (t:Title {title_id: '32281'})-[rel]->(node)
WHERE type(rel) IN ['FEATURES','HAS_GENRE']
RETURN type(rel) AS relation, node.name AS name_or_genre, rel.weight
ORDER BY relation;
```

```cypher
// 出演者の重みを使って似た作品を探す（"Kimi no Na wa." 基準）
MATCH (:Title {title_id: '32281'})-[f:FEATURES]->(p:Person)
WITH p, f.weight AS baseWeight
MATCH (p)<-[f2:FEATURES]-(other:Title)
WHERE other.title_id <> '32281'
WITH other, sum(baseWeight * coalesce(f2.weight, 1.0)) AS score
RETURN other.title AS candidate, score
ORDER BY score DESC LIMIT 10;
```

```cypher
// 類似作品のミニパス（例: 5114）
MATCH (src:Title {title_id: '5114'})-[r:SIMILAR_TO]->(dst)
RETURN src.title AS source, dst.title AS similar, r.score
ORDER BY r.score DESC;
```

### ユースケース4: 視聴直後の関連コンテンツ推薦
ユーザーが特定作品（例: "Sword Art Online"）を視聴した直後に、関連する作品を提示し継続視聴を促します。

```cypher
// ユーザー1の最新視聴として「Sword Art Online(=title_id: 11757)」を記録（例）
MERGE (u:User {user_id: '1'})
WITH u
MATCH (t:Title {title_id: '11757'})
MERGE (u)-[r:INTERACTED_WITH {kind: 'completed'}]->(t)
SET r.weight = 0.9,
    r.rating = 4.5,
    r.status = 'completed',
    r.source = 'manual_event';
```

```cypher
// title_id を調べたいときのサンプル（部分一致検索）
MATCH (t:Title)
WHERE toLower(t.title) CONTAINS 'sword art online'
RETURN t.title, t.title_id;
```

```cypher
// 視聴作品と同じ出演者・ジャンルから関連コンテンツを抽出
MATCH (u:User {user_id: '1'})-[:INTERACTED_WITH]->(src:Title {title_id: '11757'})
OPTIONAL MATCH (src)-[:HAS_GENRE]->(g:Genre)
OPTIONAL MATCH (src)-[:FEATURES]->(p:Person)
WITH DISTINCT g, p, src
MATCH (other:Title)
WHERE other <> src AND NOT EXISTS { MATCH (u)-[:INTERACTED_WITH]->(other) }
OPTIONAL MATCH (other)-[:HAS_GENRE]->(g2:Genre)
OPTIONAL MATCH (other)-[:FEATURES]->(p2:Person)
WITH other,
  count(DISTINCT CASE WHEN g2 = g THEN 1 END) AS sharedGenres,
  count(DISTINCT CASE WHEN p2 = p THEN 1 END) AS sharedPersons
WITH other, (sharedGenres * 1.0 + sharedPersons * 1.5) AS score
WHERE score > 0
RETURN other.title AS recommended, score
ORDER BY score DESC LIMIT 10;
```
