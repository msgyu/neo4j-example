# Step 0. 事前準備

1. Docker Desktop（Compose v2 対応）を macOS / Linux にインストールし、起動しておく。
2. このリポジトリを clone し、`neo4j-example` ディレクトリへ移動。
   ```bash
   git clone https://github.com/msgyu/neo4j-example.git
   cd neo4j-example
   ```
3. Kaggle から提供された CSV を `example_data/kaggle-data` から `data/kaggle` へコピー（リポジトリには同梱済み）。
4. `rating.csv` はサイズが大きいため PoC 用にサンプルを作成：
   ```bash
   head -n 50001 data/kaggle/rating.csv > data/kaggle/rating_sample.csv
   ```
5. `.env` や `docker/neo4j.env` を確認し、`NEO4J_AUTH=neo4j/localtest` などデフォルト資格情報を把握。
