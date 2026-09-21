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

### Git repo: initialized, public, with a commit-and-push skill
- **First commit made** covering all of Phase 0 (frontend, backend, docs, `.gitignore`, README, `check-dev-env` skill) — `.gitignore` set up first to exclude `node_modules/`, `target/`, `.idea/`, etc.
- **Repo visibility: public**, created immediately rather than the originally discussed "private until polished" plan — a deliberate change of mind, confirmed explicitly before creating it, not an accident. `docs/DECISIONS.md` and `docs/LEARNINGS.md` stayed in git either way (visibility is a GitHub setting, not something `.gitignore` should be used to fake).
- **Added `.claude/skills/commit-and-push/`**: a skill that runs the full stage → check-for-secrets → commit (with the `Co-Authored-By` trailer) → push flow on request, following the same safety rules as manual commits (specific-file staging preferred over blanket `add -A`, never `--amend` after a hook failure, never force-push).

---

## Phase 1 (Products, read-only) — plan finalized

Full reasoning for each of these lives in `docs/LEARNINGS.md` ("Phase 1 (Planning)") and the approved plan file; this is the decisions summary.

- **Topics model:** fixed, admin-curated list (not free-form tags) — informed by Product Hunt's own history (added a fixed "Categories" taxonomy specifically because free-form tags broke structured discovery/leaderboards). Up to 3 topics per product, cap deliberately left unenforced until Phase 3 (no write path exists yet to violate it).
- **Schema management:** Flyway (versioned plain-SQL migrations) — rejected Hibernate `ddl-auto` (documented production hazard: silent column drops, schema drift, no rollback, no audit trail) and Liquibase (its multi-database/complex-environment advantages don't apply to a Postgres-only, single-environment project).
- **Backend package structure:** feature-based (`com.launchpad.product`, `com.launchpad.topic`) over layered (`controller/`, `service/`, etc.) — scales better across the remaining 13+ phases, each adding a new feature concern.
- **Data access:** Spring Data JPA over plain JDBC — the real-world Spring Boot default; deliberately using this phase to hit and properly fix the N+1 query problem rather than learn it abstractly.
- **Screenshots:** normalized `product_screenshots` child table over an array/JSONB column — explicit ordering, consistent with the `product_topics` join-table pattern, room for future per-screenshot metadata.
- **API responses:** dedicated DTOs (`ProductSummaryDto`, `ProductDetailDto`) over raw entities — stable contract, avoids Jackson serializing a lazy-loaded association mid-request.
- **Frontend:** `API_BASE_URL` constant introduced (first phase with >1 endpoint); `App.tsx` split into `api/products.ts` + `ProductList`/`ProductCard` components, mirroring the backend's feature-based split.

### Plan review by an independent subagent — 5 fixes adopted before implementation
An independent subagent (deliberately given no attachment to the plan's existing choices) was asked to critique the finalized Phase 1 plan. It caught a genuine bug, not just style nitpicks:
1. **Fetch-strategy bug, fixed:** the original plan eagerly fetched both `topics` (`@ManyToMany`) and `screenshots` (`@OneToMany`) in one query. This causes a cartesian-product row explosion, and — critically — Hibernate cannot do SQL-level pagination when a collection fetch-join is present, which would silently break the moment the product list needs paging (a near-certain next step). **Fix:** the list endpoint eager-fetches only `topics`; the single-product detail endpoint (no list to paginate) fetches both.
2. **Missing index on `launch_date`**, added — the embargo query filters/sorts on it on every single request.
3. **Missing `ON DELETE CASCADE`** on all three foreign keys, added — Phase 1 never deletes anything, but Phase 3/12 (moderation, takedowns) will, and the default FK behavior would otherwise throw an ugly error the first time.
4. **Missing `updated_at` column**, added — was an oversight (unlike the other deliberately-deferred columns, each of which has a written reason), not a deliberate deferral.
5. **Verification checklist expanded**: added a today-launches boundary check, screenshot-ordering check, genuinely-nonexistent-id 404 check, and a Flyway idempotency check (restart against an already-migrated DB).
- **Why a subagent for this specifically (not the earlier check-dev-env case):** reviewing a finished plan for gaps benefits from a fresh, unbiased read — the opposite of the check-dev-env task, which was small/deterministic/context-dependent. This is the "second opinion" pattern a subagent is actually suited for.

### DTOs implemented as Java `record`s, not plain classes
- **Chosen:** `TopicDto`, `ProductScreenshotDto`, `ProductSummaryDto`, `ProductDetailDto` are all `record`s, in contrast to the entities (`Topic`, `Product`, `ProductScreenshot`), which are regular classes with private fields, hand-written constructors, and getters.
- **Alternative considered:** plain classes for the DTOs too, matching the entities' style for consistency.
- **Why records specifically for DTOs:** a `record` is Java's built-in shorthand for "an immutable bundle of data, nothing more" — one line generates the fields, constructor, getters, `equals`/`hashCode`/`toString` automatically. That's exactly what a DTO is: built once per request, read once during JSON serialization, then discarded. Entities can't use records because JPA needs machinery records don't support (the `@Entity` annotation, a no-arg constructor JPA uses internally, mutable state Hibernate manages across a database session) — so the two object categories deliberately use different Java features, matched to what each one actually needs to do.

### Real bug: `flyway-core` alone doesn't trigger Flyway on Spring Boot 4.1
- **Symptom:** Backend failed at startup with `Schema validation: missing table [product_screenshots]` (Hibernate's `ddl-auto=validate`) — but the database was confirmed completely empty both before and after the run, with no `flyway_schema_history` table at all, meaning Flyway never even attempted to connect, let alone migrate. Persisted across a full IntelliJ Maven reload + IDE restart, ruling out a stale-classpath explanation.
- **Root cause, confirmed via Spring Boot's own docs/changelog (not guessed):** Spring Boot 4.1 split its autoconfiguration into separate per-feature modules. Flyway's Spring Boot integration — the code that actually triggers migrations on startup — moved out of the main autoconfigure jar into its own module, `spring-boot-flyway`. Depending on `org.flywaydb:flyway-core` alone (the pattern that worked on all prior Spring Boot versions) pulls in only the Flyway *library*, not the Spring Boot *glue* — so migrations silently never ran, with no error from Flyway itself since it was never invoked at all.
- **Fix:** replaced the `org.flywaydb:flyway-core` dependency with `org.springframework.boot:spring-boot-starter-flyway` (which correctly pulls in `spring-boot-flyway` + `flyway-core` transitively), kept `flyway-database-postgresql` as-is. Verified via `mvn dependency:tree` that `spring-boot-flyway` is now present.
- **Why this was hard to diagnose:** a completely silent failure — no exception naming Flyway, no partial migration state, nothing in the logs pointing at the real cause. The only real signal was the *absence* of `flyway_schema_history`, meaning Flyway was never invoked at all, which is what redirected the investigation away from "the SQL/DB is broken" and toward "the Spring Boot wiring itself isn't happening."

### Real bug: detail endpoint duplicated screenshots (cartesian product, caught by manual testing)
- **Symptom:** `GET /api/products/{id}` returned every screenshot duplicated exactly (topic count) times — e.g. Focusly (2 topics, 3 screenshots) returned 6 screenshot entries, each real one appearing twice.
- **Root cause:** the plan's original reasoning — "eager-fetching both `topics` and `screenshots` together is safe on the detail endpoint since it's only one row, not a paginated list" — was only half right. It correctly ruled out the *pagination* failure mode the subagent review caught (which is real, but specific to lists). It missed a *second*, independent consequence of joining two collections in one query: every (topic, screenshot) combination becomes its own SQL row regardless of pagination — a true cartesian product, row-count multiplication, not just a performance concern. `topics` (a `Set<Topic>`) silently absorbed the duplicates on insert; `screenshots` (a `List<ProductScreenshot>`) does not dedupe, so the duplicates survived straight into the JSON response.
- **Fix:** the detail endpoint's `@EntityGraph` now eager-fetches only `topics`; `screenshots` lazy-loads instead. Justified because the entire reason eager-fetching existed in the first place — avoiding N+1 queries *across a list of many products* — doesn't apply to a single-item lookup: one extra lazy-load query for one product's screenshots is negligible, not the N+1-across-a-list problem being guarded against.
- **How it was caught:** manual `curl` testing against the running endpoint, not code review — a reminder that "eager-fetch fewer collections" fixes pagination but doesn't automatically fix duplication, and real request/response testing catches things static analysis of the query annotations alone would not.

### Phase 1 frontend: built and verified
- `src/api/config.ts` (`API_BASE_URL` constant), `src/api/products.ts` (`fetchProducts`/`fetchProduct`, with TypeScript interfaces mirroring the backend DTOs — `ProductDetail extends ProductSummary`, matching how the backend's detail response is a superset of the summary response), `src/components/ProductCard.tsx` (presentational, no fetching of its own), `src/components/ProductList.tsx` (owns fetch/loading/error state), `App.tsx` shrunk to render `<ProductList />`.
- **Verified live:** `.claude/launch.json` added (npm dev server preview config) and the app was run end-to-end against the live backend — 9 launched products rendered with names/taglines/topics, zero console errors. Confirms the walking-skeleton extends through the full stack, not just the backend.
- **One-line fix:** topic names in `ProductCard` were rendering with no separator (`MarketingDesign Tools`); changed to `.join(', ')` on the topic-name array instead of individual `<span>`s. Kept intentionally minimal — see the priority decision below.

### Project priority: backend-first, frontend deliberately minimal
- **Chosen:** the frontend stays functional-but-unstyled for as long as backend phases are still ahead. No design-system tooling, no CSS framework, no visual polish pass, until the user explicitly shifts into learning frontend/UI seriously.
- **Why:** the user's actual goal for this project is learning backend systems deeply (internal mechanics, how communication happens, etc.) — frontend fluency is a later, deliberately sequenced goal on the path to full-stack, not a current one. Time spent on frontend polish right now (styling, design-system skills, UI libraries) would trade against the phases that actually serve the stated goal (Auth, Voting, Ranking, Notifications, Anti-Fraud, etc.).
- **Concretely:** a third-party "ui-ux-pro-max" Claude Code skill was evaluated and declined for now on this basis (see `docs/LEARNINGS.md`) — not because it's a bad tool, but because it solves a problem (frontend design decisions) the user isn't trying to solve yet. Revisit once frontend becomes the active learning focus, later in the roadmap.
