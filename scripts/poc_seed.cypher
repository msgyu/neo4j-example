// Constraints
CREATE CONSTRAINT IF NOT EXISTS FOR (u:User) REQUIRE u.user_id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (t:Title) REQUIRE t.title_id IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (g:Genre) REQUIRE g.name IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (p:Person) REQUIRE p.person_id IS UNIQUE;

// --- Load Titles + Genres from Kaggle ---
LOAD CSV WITH HEADERS FROM 'file:///kaggle/anime.csv' AS row
WITH row
WHERE row.anime_id IS NOT NULL AND row.anime_id <> ''
WITH row,
     CASE row.episodes WHEN 'Unknown' THEN NULL ELSE toInteger(row.episodes) END AS episodeCount,
     CASE row.rating WHEN 'Unknown' THEN NULL ELSE toFloat(row.rating) END AS avgRating,
     CASE row.members WHEN '' THEN NULL ELSE toInteger(row.members) END AS members
CALL {
  WITH row, episodeCount, avgRating, members
  MERGE (t:Title {title_id: row.anime_id})
  SET t.title = row.name,
      t.type = coalesce(row.type, 'unknown'),
      t.release_year = NULL,
      t.episode_count = episodeCount,
      t.member_count = members,
      t.average_rating = avgRating,
      t.rating_source = 'kaggle_anime',
      t.popularity = members
  RETURN t
}

WITH row, t

WITH row, t, [genre IN split(coalesce(row.genre,''), ',') WHERE trim(genre) <> '' AND trim(genre) <> 'Unknown'] AS genres
UNWIND range(0, size(genres)-1) AS idx
WITH t, trim(genres[idx]) AS genreName, idx
CALL {
  WITH genreName
  MERGE (g:Genre {name: genreName})
  RETURN g
}
MERGE (t)-[rel:HAS_GENRE]->(g)
SET rel.kind = CASE idx WHEN 0 THEN 'main' ELSE 'sub' END,
    rel.weight = CASE idx WHEN 0 THEN 1.0 ELSE 0.5 END,
    rel.source = 'kaggle_anime';

// --- Load Users + Interactions ---
LOAD CSV WITH HEADERS FROM 'file:///kaggle/rating.csv' AS row
WITH row WHERE row.user_id <> '' AND row.anime_id <> ''
CALL {
  WITH row
  MERGE (u:User {user_id: row.user_id})
  WITH row, u
  MATCH (t:Title {title_id: row.anime_id})
  MERGE (u)-[rel:INTERACTED_WITH]->(t)
  SET rel.kind = CASE row.rating WHEN '-1' THEN 'plan' ELSE 'rated' END,
      rel.rating = CASE row.rating WHEN '-1' THEN NULL ELSE toFloat(row.rating) END,
      rel.status = CASE row.rating WHEN '-1' THEN 'planned' ELSE 'completed' END,
      rel.weight = CASE row.rating WHEN '-1' THEN 0.2 ELSE toFloat(row.rating)/10 END,
      rel.source = 'kaggle_anime_ratings'
} IN TRANSACTIONS OF 5000 ROWS;

// --- Load mock Person nodes ---
LOAD CSV WITH HEADERS FROM 'file:///persons_mock.csv' AS row
WITH row WHERE row.person_id <> ''
MERGE (p:Person {person_id: row.person_id})
SET p.name = row.name,
    p.type = row.type;

// --- Link Titles to Persons (mock cast) ---
LOAD CSV WITH HEADERS FROM 'file:///title_person_features_mock.csv' AS row
WITH row WHERE row.title_id <> '' AND row.person_id <> ''
MATCH (t:Title {title_id: row.title_id})
MATCH (p:Person {person_id: row.person_id})
MERGE (t)-[rel:FEATURES]->(p)
SET rel.credit_role = row.credit_role,
    rel.position = row.position,
    rel.billing_order = CASE row.billing_order WHEN '' THEN NULL ELSE toInteger(row.billing_order) END,
    rel.weight = CASE row.weight WHEN '' THEN NULL ELSE toFloat(row.weight) END;

// --- User likes Person (mock)
LOAD CSV WITH HEADERS FROM 'file:///user_likes_person_mock.csv' AS row
WITH row WHERE row.user_id <> '' AND row.person_id <> ''
MATCH (u:User {user_id: row.user_id})
MATCH (p:Person {person_id: row.person_id})
MERGE (u)-[rel:LIKES_PERSON]->(p)
SET rel.created_at = datetime(row.created_at);

// --- Similar titles mock ---
LOAD CSV WITH HEADERS FROM 'file:///title_similar_mock.csv' AS row
WITH row WHERE row.source_title_id <> '' AND row.target_title_id <> ''
MATCH (src:Title {title_id: row.source_title_id})
MATCH (dst:Title {title_id: row.target_title_id})
MERGE (src)-[rel:SIMILAR_TO]->(dst)
SET rel.score = toFloat(row.score),
    rel.by = row.by,
    rel.updated_at = datetime(row.updated_at);
