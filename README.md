# Launchpad

A Product Hunt–style site: founders launch products on a chosen day, the community votes and comments, and a live-ranked front page surfaces the best launches of the day — using a time-decay ranking algorithm rather than raw vote counts.

This is a learning project, built end-to-end in deliberate phases with every architectural decision discussed and recorded along the way. See [`01-client-brief.md`](01-client-brief.md) for the full requirements.

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

## Project status

Currently in **Phase 0 (Groundwork)** — complete. Basic frontend/backend/database scaffolding is in place and verified end-to-end. See [`docs/DECISIONS.md`](docs/DECISIONS.md) for the full phase roadmap and what's been decided so far.
