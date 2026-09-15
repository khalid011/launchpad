# Launchpad — Decisions Log

Every notable decision made on this project, the alternatives considered, and why we picked what we picked. Updated as decisions happen, not retroactively.

---

## Phase 0 (Planning)

### Repo structure: Monorepo
- **Chosen:** Single repo with `/frontend` and `/backend` folders.
- **Alternative considered:** Separate repos for frontend and backend.
- **Why:** Simpler to manage for a solo project, single source of truth, easier to review full-stack features that touch both sides together. Separate repos make more sense when deploy lifecycles are independent or separate teams own each side — neither applies here.

### Auth strategy: JWT (access + refresh tokens)
- **Chosen:** JWT-based stateless auth.
- **Alternative considered:** Session-based auth (server-stored session + cookie).
- **Why:** The client brief explicitly wants a clean API that a native mobile app can reuse next year without rework. JWT works identically for web and mobile (grab a token, attach it to requests) — sessions rely on browser cookies, which mobile apps don't use the same way, and would likely mean building two separate auth mechanisms later.
- **Trade-off accepted:** JWT logout/revocation is harder than sessions (the server doesn't "own" the token, so invalidating it early needs extra machinery — short-lived access tokens + a refresh flow, possibly a revocation list). Given the brief calls password/security failures "company-ending if leaked," this will be designed carefully in Phase 2, not rushed.

### Local dev environment: Docker Compose for Postgres only
- **Chosen:** PostgreSQL runs in Docker Compose. Spring Boot and React run natively (not containerized) during early phases.
- **Alternative considered:** Install Postgres natively on Windows; or containerize everything (frontend + backend + db) from day one.
- **Why:** Postgres is infrastructure we don't edit — Docker makes it disposable/resettable (`docker compose down -v` → fresh db) and matches how real teams run it (never installed bare-metal on a dev laptop). Spring Boot and React are what we're actively editing all day and both have hot-reload dev servers; containerizing them too would slow the feedback loop (file-watching across the Docker filesystem boundary is often flaky, especially on Windows) for a consistency benefit we don't need yet as a solo developer. We reintroduce containerizing the apps in Phase 14 (deployment), where "same everywhere" starts to actually matter.

### nginx: deferred to the deployment phase
- **Chosen:** No nginx in local dev. Spring Boot's embedded Tomcat serves the backend directly; React's dev server (Vite) serves the frontend directly. Introduced only in Phase 14.
- **Alternative considered:** Set up nginx locally now for "production realism."
- **Why:** nginx's job (routing, TLS termination, serving static files efficiently, load balancing) only matters once there's real public traffic to route/secure. In local dev there's no HTTPS need, no multiple backend instances, and the browser talks straight to `localhost:8080` — no reverse proxy required. Adding it now means configuring a tool to solve problems that don't exist yet, working against the "one concept at a time" learning approach. It'll be introduced in Phase 14 once there's a concrete routing/TLS problem to solve, so its purpose is felt, not abstract.
- **Note:** Spring Boot ships with an embedded web server (Tomcat) — nginx was never *required* for client-server communication to work; it's an optional layer in front of a real web server, not "the" web server.

### Client ↔ backend communication in local dev (no nginx)
- **Chosen (tentative — to be finalized when Phase 0 is implemented):** React dev server and Spring Boot run on different ports; frontend calls the backend via HTTP directly.
- **Open sub-decision:** CORS config on the backend vs. Vite's built-in dev proxy (forwarding `/api/*` calls to the backend, sidestepping CORS in dev, and previewing the path-routing nginx will do in production). To be decided explicitly during Phase 0 implementation.

### Topics model — NOT YET DECIDED
- **Options on the table:** (a) fixed, admin-curated list of topics, vs (b) free-form founder-entered tags.
- **Status:** Open. Must be resolved before Phase 1 schema work (`products` table depends on it) and affects per-topic leaderboards (Phase 7).

---

## Phase 0 (Scaffolding)

### Frontend tooling: Vite
- **Chosen:** Vite + React + TypeScript.
- **Alternatives considered:** Create React App (CRA) — officially deprecated, not viable for a new project. Next.js — a full framework with its own backend/routing/SSR conventions.
- **Why:** Vite is a fast, unopinionated build tool/dev server — it only bundles and serves the React app, with no opinions about backend structure. That fits our setup, where Spring Boot is the sole backend; Next.js would overlap with or duplicate decisions Spring Boot already owns.

### Frontend package manager: npm
- **Chosen:** npm.
- **Alternative considered:** pnpm (faster, more disk-efficient, but one extra tool to install).
- **Why:** Ships with Node, zero extra install, universally documented — the simplest default, consistent with focusing on project-specific work over tooling exploration. Easy to switch to pnpm later if desired.

### Backend build tool: Maven
- **Chosen:** Maven.
- **Alternative considered:** Gradle (faster builds, more flexible, Groovy/Kotlin-based config).
- **Why:** Maven's XML `pom.xml` is more explicit/verbose, which is easier to read and reason about for learning purposes, and it's what most Spring Boot tutorials and Spring Initializr default to.

### Database: Docker Compose (not the existing local Postgres install)
- **Chosen:** PostgreSQL 16 via Docker Compose, isolated from the user's existing local Postgres install.
- **Alternative considered:** Reuse the already-installed local Postgres.
- **Why:** Fully disposable/resettable dev database (`docker compose down -v` → clean slate), fully isolated from any other local Postgres use. The usual downside (extra infra to manage) doesn't apply here since the user already has Docker Desktop and hands-on container/Cloud Run experience — so the choice carries its benefits with no real added friction.

### Monorepo layout — revised: app code lives under source/
- **Chosen:** A `source/` subfolder holds everything that's part of the actual running app (`frontend/`, `backend/`, `docker-compose.yml`, and `CLAUDE.md`), separate from top-level reference/planning material (`01-client-brief.md`, `docs/`).
- **Why:** Keeps the app's own source tree self-contained and separate from project-level reference docs — the user's preference, set when creating the `source/` folder directly.
```
Launchpad/
  01-client-brief.md
  docs/                 (DECISIONS.md, LEARNINGS.md)
  launch_pad_requirement_analysis.excalidraw
  source/
    CLAUDE.md
    frontend/            (Vite + React + TS app)
    backend/             (Spring Boot + Maven app)
    docker-compose.yml   (Postgres)
```

### Postgres container config (docker-compose.yml)
- **Chosen:** `postgres:16` image, db/user `launchpad`, dev-only password `launchpad_dev`, port `5432` mapped to host, named volume `launchpad_postgres_data` for persistence across restarts.
- **Why these specifics:** plain, memorable dev-only credentials (no secrecy needed locally, never exposed to the internet); a named volume so `docker compose down` (without `-v`) keeps data, while `-v` gives the full reset described in the earlier Docker-vs-local decision.

### Client ↔ backend comms in dev: CORS config (not Vite proxy)
- **Chosen:** CORS config in Spring Boot, allow-listing `http://localhost:5173`.
- **Alternative considered:** Vite's built-in dev proxy (forward `/api/*` to the backend, sidestepping CORS in dev).
- **Why:** CORS is real, production-relevant configuration — any API serving a different-origin frontend needs it, including the brief's future mobile client hitting this same API. The Vite proxy is dev-only convenience that doesn't carry into production, so it would just be solving the same problem twice later.

### Backend Java version: 21 (LTS)
- **Chosen:** Java 21.
- **Alternative considered:** Java 17 (previous LTS).
- **Why:** Current LTS, Spring Initializr's default for new projects, and there's no existing codebase tying this project to an older version — no reason to start behind.

### Backend package name: com.launchpad
- **Chosen:** `com.launchpad` as the Maven group ID / base Java package.
- **Why:** No company domain to reverse; a short, project-specific name is the common convention for a personal/learning project.

### Backend Phase 0 dependencies: Spring Web + DevTools only
- **Chosen:** Spring Web, Spring Boot DevTools.
- **Why:** Phase 0 has no database work — only a Hello World REST endpoint. Spring Data JPA and the Postgres driver are deliberately deferred to Phase 1 so we're not installing things before there's a reason to use them. DevTools gives auto-restart on save, consistent with the "fast dev loop" decision made for local dev.

### Frontend scaffold: Vite react-ts template
- **Chosen:** Vite's official `react-ts` template, project named `frontend`.
- **Why:** Direct match for the already-decided stack (React + TypeScript via Vite) — no reason to hand-roll config Vite already provides.

### Spring Boot version: 4.1.1
- **Chosen:** Spring Boot 4.1.1 (Spring Initializr's current default at scaffold time).
- **Note:** Spring Boot has moved to the 4.x line since this project's planning began — the ecosystem moves fast; always check Spring Initializr's current default rather than assuming a fixed version.

### Backend startup issue: resolved — was a shell-launcher problem, not the project
- **Symptom:** Running the backend via `mvnw spring-boot:run` in this session's shell consistently failed with `Unable to establish loopback connection` while Tomcat tried to open its internal socket pipe, regardless of JDK version (tried Java 23 and 21) or selector settings.
- **Root cause found:** Specific to how that particular shell/process launcher on this machine starts Java processes — not the code, not Spring Boot, not the JDK version. Confirmed by running the identical project via IntelliJ, which started cleanly in ~3 seconds with no error.
- **Resolution:** Run/debug the backend via IntelliJ (or a normal terminal) rather than through that specific automated shell context.
- **JDK 21 installed and pinned regardless:** Even though JDK version wasn't the actual cause, JDK 21 (Eclipse Temurin, an LTS release) was installed via `winget` and the project is pinned to it via Maven toolchains (`~/.m2/toolchains.xml` + `maven-toolchains-plugin` in `pom.xml`), so the build always uses JDK 21 regardless of whatever JDK is set as the Windows system default (23, a non-LTS release) — worth keeping since a real project shouldn't run on a short-lived non-LTS JDK.
- **Verified:** `GET /api/hello` → `Hello from Launchpad backend!`, confirming the Phase 0 backend milestone.

### IntelliJ's green Run button ignored the Maven toolchain — fixed via Project SDK
- **Symptom:** Even after pinning JDK 21 via Maven toolchains, running `BackendApplication` via IntelliJ's Run button still started on Java 23.
- **Why:** Maven toolchains only apply when Maven itself drives the build/run (`mvnw spring-boot:run`, or IntelliJ's Maven panel). Clicking Run directly on the class bypasses Maven and uses IntelliJ's own **Project/Module SDK** setting instead, which had defaulted to JDK 23 (whatever was on `PATH`).
- **Chosen fix:** Set IntelliJ's Project SDK explicitly to the Temurin JDK 21 install (File → Project Structure → Project/Module SDK). Chosen over always running via Maven's `spring-boot:run` goal for day-to-day convenience (one-time IDE setting vs. giving up the one-click Run button).
- **Trade-off accepted:** this IDE setting is local to this machine/IDE install, not stored in the repo — if the project is opened on another machine/IDE, the Project SDK needs to be set there too. The Maven toolchain (`pom.xml` + `toolchains.xml`) remains the portable, repo-tracked source of truth for any Maven-driven build regardless of IDE settings.
- **Verified:** confirmed working on JDK 21 via IntelliJ's Run button after the fix.

---

## Phase 0 — Complete

- ✅ `source/frontend/` scaffolded (Vite `react-ts` template, npm), `App.tsx` fetches `http://localhost:8080/api/hello` and renders the response.
- ✅ `source/backend/` scaffolded (Spring Boot 4.1.1, Maven, Java 21 via toolchain, `com.launchpad`), with `HelloController` (`GET /api/hello`) and `CorsConfig` (allow-lists `http://localhost:5173` for `/api/**`).
- ✅ Postgres 16 running via Docker Compose (unused so far — Phase 1 territory).
- ✅ Full round trip verified in browser: page loads at `localhost:5173`, displays "Backend says: Hello from Launchpad backend!", zero console errors.
- **Backend run/debug going forward:** via IntelliJ (Project SDK pinned to JDK 21), not through this session's automated shell — see the two entries above for why.

### `main.tsx`: replaced the `!` non-null assertion with an explicit check
- **Chosen:** Explicit null check on `document.getElementById('root')` that throws a clear error if missing, instead of Vite's default `!` (non-null assertion).
- **Alternative considered:** Keep Vite's default `!` — technically safe in this specific setup since `index.html` always has `<div id="root">`.
- **Why:** Same category of risk as Kotlin's `!!` / Swift's forced unwrap — the `!` is a promise to the compiler that crashes at runtime if ever wrong, rather than being caught earlier. It's boilerplate-template convenience, not a best-practice example. Given the project's explicit goal of being "a real application, not a toy," the explicit-check version fails with a clear message instead of a cryptic null-reference crash if the root element ever goes missing.

### Dev-server check/start tooling: a Claude Code skill, not a subagent
- **Chosen:** A small skill (`.claude/skills/check-dev-env/`) that checks backend (:8080) and frontend (:5173) status, starts the frontend if it's down, and reports — invoked on request, not automatically.
- **Alternative considered:** A dedicated subagent for the same job.
- **Why not a subagent:** subagents start cold with no memory of this conversation, so every run would need the backend's known shell-launcher bug re-explained from scratch — pure overhead. The task itself is small and deterministic (2-3 tool calls, no exploration or judgment calls needed), which is exactly where a subagent's isolation/parallelism benefits don't apply. The backend half can't be automated at all anyway (must be started manually in IntelliJ), so there's little real "work" to delegate.
- **Why a skill fits:** a skill is just a saved set of instructions invoked directly, with none of a subagent's cold-start/context overhead — a better match for a small, repeatable, mostly-deterministic check.
- **Scope kept intentionally narrow:** no Docker/Postgres check included — not needed until Phase 1 starts using the database.
