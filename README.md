# Launchpad

A Product Hunt–style site: founders launch products on a chosen day, the community votes and comments, and a live-ranked front page surfaces the best launches of the day — using a time-decay ranking algorithm rather than raw vote counts.

This is a learning project, built end-to-end in deliberate phases with every architectural decision discussed and recorded along the way. See [`01-client-brief.md`](01-client-brief.md) for the full requirements.

## Important links

- 📋 [Progress summary](#progress) — where this project currently stands (below)
- 📝 [Decisions log](docs/DECISIONS.md) — every technical decision made, alternatives considered, and why
- 💡 [Learnings log](docs/LEARNINGS.md) — concepts learned and real bugs diagnosed along the way, in plain language
- 💼 [Career takeaways](docs/CAREER_SKILLS.md) — the above, re-read through a job-market lens (sourced, not just asserted)
- 📊 Diagrams (live, interactive):
  - [Runtime Flow](https://claude.ai/artifact/837fdc37-8ab3-4c8c-abb5-0da94e676e24) — frontend ↔ backend, dev vs. production
  - [Data Layer Flow](https://claude.ai/artifact/6uRxCeLtChwiBa36jiHEjs) — JPA/Hibernate stack, Flyway/Docker startup sequence, Spring bean dependencies
  - (also archived as static HTML in [`docs/diagrams/`](docs/diagrams/) in case the live links ever go stale)

## Stack

- **Frontend:** React + TypeScript, [Vite](https://vite.dev/)
- **Backend:** Spring Boot (Java 21, Maven)
- **Database:** PostgreSQL 16 (Docker Compose for local dev)
- **Web server (production only):** nginx — not used in local dev, see [`docs/DECISIONS.md`](docs/DECISIONS.md)

## Project structure

```
Launchpad/
  01-client-brief.md        # client requirements (reference)
  docs/
    DECISIONS.md             # every technical decision made, and why
    LEARNINGS.md              # concepts learned along the way
    CAREER_SKILLS.md          # learnings re-read through a job-market lens
    diagrams/                 # exported system diagrams (see below)
  source/
    CLAUDE.md                 # working-agreement / instructions for this project
    frontend/                 # Vite + React + TS app
    backend/                  # Spring Boot app
    docker-compose.yml        # PostgreSQL for local dev
```

## Running locally

**Database** (from `source/`):
```bash
docker compose up -d
```

**Backend** (from `source/backend/`) — open in IntelliJ and run `BackendApplication`, or:
```bash
./mvnw spring-boot:run
```
Runs on `http://localhost:8080`.

**Frontend** (from `source/frontend/`):
```bash
npm install
npm run dev
```
Runs on `http://localhost:5173`.

## Diagrams

Self-contained HTML pages under [`docs/diagrams/`](docs/diagrams/) — download and open in a browser to view (also linked live above):
- [`runtime-flow.html`](docs/diagrams/runtime-flow.html) — how the frontend and backend talk to each other in development vs. production.
- [`data-layer-flow.html`](docs/diagrams/data-layer-flow.html) — the JPA/Hibernate/Spring Data JPA/Spring Boot stack, and what happens at backend startup (Flyway, Docker's port mapping).

## Progress

**Phase 0 — Groundwork: ✅ complete.** Frontend/backend/database scaffolding, verified end-to-end (React page fetching from a live Spring Boot endpoint, zero CORS errors).

**Phase 1 — Products (read-only): ✅ complete.**
- ✅ Database schema via Flyway (`products`, `topics`, `product_topics`, `product_screenshots`), seeded with realistic sample data.
- ✅ Spring Data JPA entities, repositories, service, and REST controller (`GET /api/products`, `GET /api/products/{id}`).
- ✅ Embargo rule enforced (unlaunched products return 404, including the "launches today" boundary case) and verified against live requests.
- ✅ Two real bugs found via an independent plan review and live endpoint testing, diagnosed and fixed — see [`docs/DECISIONS.md`](docs/DECISIONS.md) for the write-ups (a JPA cartesian-product/pagination trap, and a Spring Boot 4.1 Flyway auto-configuration change).
- ✅ Frontend product list page (`ProductList`/`ProductCard`), verified end-to-end against the live backend — deliberately unstyled for now (see "Project priority" in [`docs/DECISIONS.md`](docs/DECISIONS.md)), since the current learning focus is backend systems, not frontend/UI.

**Phases 2–14** (accounts/auth, submissions, voting, ranking, comments, notifications, search, anti-fraud, staff tools, deployment, etc.) — planned, not started. Full roadmap and rationale in [`docs/DECISIONS.md`](docs/DECISIONS.md).
