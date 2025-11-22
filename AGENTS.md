# Repository Guidelines

## Project Structure & Module Organization
This repository is intentionally minimal so agents can add only the layers they need. Keep application logic in `src/` with clear slices such as `src/db`, `src/services`, and `src/routes`. Place reusable Cypher under `queries/` (one query per file), dataset CSVs in `data/`, and environment templates inside `config/`. Tests live in `tests/`, mirroring the structure of `src/`, while Docker assets and helper scripts stay inside `docker/` and `scripts/` so infrastructure changes remain isolated.

## Build, Test, and Development Commands
Run `npm install` once to pull dependencies. `npm run dev` starts the local server with hot reload and expects `NEO4J_URI`, `NEO4J_USERNAME`, and `NEO4J_PASSWORD` in `.env`. `npm run build` compiles TypeScript to `dist/` and should fail on type errors. Start the database locally through `docker compose up neo4j` (compose file stored in `docker/`). Use `npm run seed` to replay the example dataset through `cypher-shell`, `npm test` for Jest suites, and `npm run lint` to enforce ESLint + Prettier rules before opening a pull request.

## Coding Style & Naming Conventions
Target Node.js 20 with TypeScript. Use 2-space indentation, single quotes, and trailing commas. Keep files focused on a single export, name them in kebab-case (`graph-service.ts`), and prefer PascalCase for classes, camelCase for functions, and UPPER_SNAKE_CASE for env-driven constants. Cypher files should start with verbs (`create-user.cql`). Run `npm run lint -- --fix` before committing to align imports and formatting automatically.

## Testing Guidelines
Author Jest specs alongside their targets using the `.spec.ts` suffix (`src/services/user.ts` → `tests/services/user.spec.ts`). Spin up a disposable Neo4j container for integration tests or mock it with the official test harness. Keep coverage above 85% and add regression tests whenever a Cypher query changes shape or side effects.

## Commit & Pull Request Guidelines
Follow Conventional Commits (`feat: add shortest-path endpoint`) so changelog tooling stays simple. Each PR must describe the problem, summarize the solution, and list local verification steps (commands + sample queries). Reference related GitHub issues and include screenshots or sample responses for any API or data contract changes. Do not merge without green CI and one reviewer approval.

## Security & Configuration Tips
Never commit secrets—update `.env.example` instead. Use scoped Neo4j accounts and rotate credentials documented in `config/neo4j.json`. When sharing logs or Cypher output, redact user-identifying properties. Reset the dataset with `npm run seed -- --reset` before recording demos to avoid leaking stale or private data.
