DOCKER_COMPOSE ?= docker compose -f docker/compose.yml
NEO4J_USER ?= neo4j
NEO4J_PASS ?= localtest

.PHONY: help up down logs seed cypher shell status kaggle-data restart

help:
	@echo "Available targets:"
	@echo "  make up        # Start Neo4j stack"
	@echo "  make down      # Stop stack and remove volumes"
	@echo "  make logs      # Tail Neo4j logs"
	@echo "  make seed      # Run scripts/poc_seed.cypher via cypher-shell"
	@echo "  make cypher CMD='MATCH (n) RETURN count(n);' # Run arbitrary Cypher"
	@echo "  make shell     # Open interactive cypher-shell"
	@echo "  make status    # Show docker compose services"

up:
	$(DOCKER_COMPOSE) up -d

down:
	$(DOCKER_COMPOSE) down -v

restart:
	$(DOCKER_COMPOSE) up -d --force-recreate neo4j

logs:
	$(DOCKER_COMPOSE) logs -f neo4j

status:
	$(DOCKER_COMPOSE) ps

seed:
	$(DOCKER_COMPOSE) exec neo4j \
		cypher-shell -u $(NEO4J_USER) -p $(NEO4J_PASS) -f /workspace/scripts/poc_seed.cypher

cypher:
	$(DOCKER_COMPOSE) exec -T neo4j \
		cypher-shell -u $(NEO4J_USER) -p $(NEO4J_PASS) -P "$$CMD"

shell:
	$(DOCKER_COMPOSE) exec neo4j cypher-shell -u $(NEO4J_USER) -p $(NEO4J_PASS)

kaggle-data:
	@echo "Unzipping data/kaggle/archive.zip into data/kaggle/"
	@[ -f data/kaggle/archive.zip ] || (echo "archive.zip not found under data/kaggle" && exit 1)
	@tmpdir=$$(mktemp -d); \
	  unzip -q data/kaggle/archive.zip -d $$tmpdir; \
	  mv $$tmpdir/* data/kaggle/; \
	  rm -rf $$tmpdir
