# Launchpad — Learnings Log

Concepts and patterns learned along the way, explained in plain language. Grows phase by phase.

---

## Phase 0 (Planning)

### Session-based auth vs. JWT auth
- **Sessions** are like a coat-check ticket: the server stores a session record and gives your browser a simple ID (a cookie). Every request, the browser sends the ID, server looks it up to know who you are. The server holds the source of truth; logging out = delete the record.
- **JWT (JSON Web Token)** is like a stamped, tamper-proof passport: the server signs a token containing your identity and hands it to you — it stores nothing itself. Every request, you present the token; the server just checks the signature and expiry, no lookup needed.
- **Why it matters for "web now, mobile later":** cookies (which sessions rely on) are handled automatically by browsers but aren't the natural fit for native mobile apps, which usually want to grab and attach a token manually — exactly what JWT is for. Building both means using the same mechanism for web and mobile instead of two different systems.
- **The catch with JWT:** since the server doesn't track live tokens, "logging out early" isn't as simple as deleting a record — you need extra design (short-lived access tokens + a refresh token flow, possibly a revocation list) to handle it properly.

### Why containerize the database but not the app you're actively coding
- Docker containers are great for things you want to be disposable, resettable, and consistent — a perfect fit for a database you don't hand-edit.
- For code you're actively saving and re-running all day (with hot-reload dev servers), adding a container layer mostly adds friction (slower/flakier file-watching) without a matching benefit yet, since there's only one developer and one machine involved.
- The "make everything match production" benefit of full containerization becomes valuable specifically once you're deploying — that's why it shows up in the roadmap at the deployment phase, not before.

### What nginx actually is (and isn't)
- Common misconception: "no nginx = no web server." Not true — Spring Boot ships with its own embedded web server (Tomcat), so the backend can accept and respond to HTTP requests all on its own.
- nginx is an optional extra layer some setups put *in front of* a real web server, used for things that only matter with real public traffic: routing requests to the right backend, handling HTTPS/TLS certificates, serving static files efficiently, and balancing load across multiple server instances.
- In local development none of those problems exist (you're the only visitor, on localhost, no certificate needed) — so nginx has nothing to do yet.

### How the frontend and backend actually talk without nginx
- Two independent servers run side by side during dev: React's dev server (e.g. on port 5173) and Spring Boot's embedded Tomcat (e.g. on port 8080). The browser loads the page from one and makes HTTP calls directly to the other.
- **CORS (Cross-Origin Resource Sharing):** browsers block a page from freely calling a different origin (different port counts as different origin) unless the server explicitly allows it. This isn't something nginx would remove the need for either way — some form of cross-origin handling (or same-origin proxying) is needed regardless.
- **Vite's dev proxy** is an alternative to configuring CORS: Vite can be told "forward any `/api/*` call to the backend," so the frontend code calls a same-origin path and Vite quietly relays it. This is dev-only convenience, but it's also a nice small preview of exactly the kind of path-based routing nginx will do for real once deployed.

### "No nginx in dev" isn't a Spring Boot–specific thing — it generalizes to other backends
- The same reasoning applies no matter which backend framework you'd pick, because almost all of them ship their own dev-ready web server:
  - **Node.js/Express:** Node's `http` module is a built-in server; Express just wraps it. `node server.js` is already a working web server.
  - **Next.js:** even more self-contained — `next dev` serves frontend pages and API routes from one process, so there isn't even a separate frontend/backend server pair to bridge.
  - **FastAPI (Python):** needs an ASGI server to run, almost always **Uvicorn** (`uvicorn main:app --reload`) — that's the dev web server, no nginx involved.
  - **Laravel (PHP):** the one real exception in *spirit* — classic PHP historically couldn't run standalone and needed Apache/nginx just to execute a file, since PHP was designed to be embedded inside a web server. But Laravel ships `php artisan serve`, a built-in lightweight dev server made specifically so local dev doesn't need Apache/nginx either. The need for a real front-end web server there is mostly a legacy-PHP/production concern, not a local-dev one.
- **The general rule:** whether you need nginx in dev isn't about the backend language — it's about whether you have a production-only problem to solve yet (routing across multiple services, TLS/HTTPS, optimized static file serving, load balancing). Locally, on any stack, none of those problems exist. nginx earns its place at deployment time, regardless of backend choice.

### TLS/HTTPS — what it is, and why local dev doesn't need it
- **HTTP** sends requests/responses in plain text — anyone positioned between your browser and the server can read every byte, like a postcard anyone handling the mail can read.
- **"Anyone in between" is bigger than just "same WiFi":** a request typically crosses a chain of 10-20 routers you have no relationship with — your router → your ISP → one or more transit/backbone networks → the destination's ISP → the server. With plain HTTP, *every hop* can read the plaintext, not just the first one. That includes: other devices on an unisolated shared network (classic risk on open public WiFi), your own ISP (structurally on the path of every request you make, by definition), any transit network in between, the destination's network, and anyone who's compromised a router anywhere along that path.
- **Nuance on "same ISP":** another random customer of your same ISP generally *can't* trivially sniff your traffic just by being a fellow customer — modern ISPs isolate customers' traffic at the switching layer (unlike old shared-hub/open-WiFi networks, where client isolation is often missing and sniffing really is trivial). The real exposure from an ISP is the **ISP itself**, which sits on the path of everything you send and can see it all unless it's encrypted.
- **Net takeaway:** TLS matters the moment traffic leaves your machine specifically because you can't know or trust every hop it'll cross — encryption protects you against all of them at once, rather than needing to individually trust every router on the path.
- **TLS (Transport Layer Security)** encrypts that conversation into a locked box only your browser and the real server can open. **HTTPS** is just "HTTP running over TLS."
- TLS also proves *identity* via a **certificate** issued by a trusted authority — proof that the server you're talking to is really who it claims to be (the padlock icon in the browser).
- **Why it's unneeded in local dev:** TLS protects traffic crossing a public, untrusted network. A request to `localhost:8080` never leaves your own machine — no network hop, no one able to eavesdrop, and no need to prove identity to yourself since you started the server. Encrypting a conversation that never leaves your PC protects against nothing.
- **Where it becomes required:** the moment the app is reachable over the real internet (Phase 14, deployment) — especially given the brief treats leaked passwords/pre-launch data as "company-ending." nginx typically holds the certificate and handles encryption/decryption at the door (**TLS termination**), so the backend behind it doesn't have to deal with TLS itself.

---

## Phase 0 (Scaffolding)

### "Opinionated" vs "unopinionated" tools
- An **opinionated** tool makes structural decisions *for* you and expects you to follow its conventions (e.g. Next.js decides how routing and API structure work).
- An **unopinionated** tool does one narrow job well and stays out of the rest of your decisions (e.g. Vite just bundles/serves your app — it doesn't care how you structure it, fetch data, or manage state).
- Why it mattered for our choice: since Spring Boot already owns all backend decisions, an unopinionated frontend tool (Vite) avoids two tools both trying to dictate backend-shaped things.

### Node.js vs npm vs Maven vs JVM — matching up the layers
- **Node.js** is a JavaScript *runtime* — the program that executes JS code outside a browser. Its Java-world equivalent is the **JVM**, which executes compiled Java code. (`Node` ↔ `JVM`)
- **npm** is the *package manager* bundled with Node — it downloads/manages dependencies and runs project scripts. Its Java-world equivalent is **Maven** (or Gradle), which does the same job for Java dependencies. (`npm` ↔ `Maven`)
- So: Node/JVM *run* the code; npm/Maven *fetch dependencies and orchestrate scripts/builds* before/around that.
- **The `npm run dev` chain, concretely:** `npm run dev` doesn't build anything itself — it looks up a script named `"dev"` in `package.json` (e.g. `"dev": "vite"`) and runs that command. `vite` is only runnable because npm downloaded it into `node_modules` as a dependency. So the real chain is: npm (fetches Vite, knows the shortcut name) → triggers → Vite (the tool that actually starts the dev server, bundles, and hot-reloads). npm is the remote control; Vite is the TV.

### Why a package manager is needed at all
- Almost no real project is written entirely from scratch — you rely on other people's published code (**libraries/packages**) for things like talking to a database, hashing passwords, parsing dates, rendering UI components, etc. Writing all of that yourself would be slow and error-prone (someone already solved "hash a password safely" correctly — better to reuse it than reinvent it).
- A package manager solves three problems that get painful fast without one:
  1. **Fetching code** — downloading the right library from a public registry (npm registry for JS, Maven Central for Java) instead of manually hunting down files.
  2. **Version tracking** — remembering *exactly* which version of each library your project uses, written down in a file (`package.json` for npm, `pom.xml` for Maven) so the project is reproducible — anyone else (or you, on a new machine) can install the identical set of dependencies.
  3. **Dependency resolution** — libraries themselves depend on other libraries ("dependencies of dependencies"), and versions need to stay compatible with each other. A package manager works out the whole tree automatically instead of you tracking it by hand.
- Without one, you'd be manually downloading files, guessing which versions work together, and having no reliable way to recreate the same setup elsewhere — a package manager turns "gather and manage all the code your project depends on" into one command (`npm install`, `mvn install`, etc.).

### Where Postgres actually runs, once containerized
- Running `docker compose up` doesn't install Postgres on Windows — Docker downloads the `postgres:16` image and starts an isolated Linux environment (**the container**) from it, and the real Postgres server *process* runs entirely inside that container. It never touches the host machine directly.
- **Port mapping (`"5432:5432"` in docker-compose.yml)** is what makes the container reachable at all — Docker forwards anything hitting `localhost:5432` on your PC into port `5432` inside the container, where Postgres is actually listening. Without this line, Postgres would be running but completely unreachable from outside the container.
- **The named volume (`launchpad_postgres_data`)** is where the actual database *data files* live — stored by Docker separately from the container itself. This is the key to why containers are treated as disposable: if the `launchpad-postgres` container is removed and recreated (`docker compose down` then `up` again), the container starts fresh, but the data survives because it lives in the separate volume, not inside the container.
- **Two different levels of "reset," concretely:**
  - `docker compose down` (no flag) → removes the container, **keeps** the volume/data. Next `up` reconnects to the same data.
  - `docker compose down -v` → also removes the volume → true clean-slate reset, all data gone.
- **Net picture:** the Postgres *server process* runs inside the container; the actual *data* lives in the volume next to it, not inside the container itself — that separation is exactly what makes "wipe and restart clean" safe and easy.

### What a container actually is, precisely
- A container is **not** a separate virtual computer booting its own OS. It's a normal process running under the existing machine's kernel — same category of thing as any other running program — but wrapped in isolation so it *behaves* as if it's alone on its own machine.
- Two Linux kernel features make this possible:
  - **Namespaces** — give the process its own private view of things normally global: its own filesystem (so Postgres sees itself owning the whole disk at `/`, even though the real disk has none of that outside the container), its own process list (can't see/touch other processes), its own network interface, its own hostname, etc.
  - **Cgroups** — let the OS cap and account for how much CPU/memory/etc. that process is allowed to use.
- So "the container" = the Postgres process, running under Linux, wearing a namespace/cgroup "sandbox" that makes it think it's alone on its own machine. This is fundamentally lighter than a VM, which boots a whole separate guest OS on virtualized hardware — why containers start in seconds and VMs take much longer.
- **The Windows wrinkle:** Linux containers need a Linux kernel to run under (namespaces/cgroups are Linux kernel features — Windows doesn't have them natively). So on Windows, Docker Desktop runs a real lightweight Linux VM in the background (via **WSL2** — Windows Subsystem for Linux) just to host that Linux kernel, and containers run as processes *inside* that Linux VM, not directly on Windows itself.
- **Full chain on this machine:** Docker Desktop → one Linux VM (via WSL2) → inside that VM, the Postgres container runs as an isolated Linux process. On native Linux, the VM step wouldn't exist at all — the container would just be a process directly on the host OS.

### LTS vs. non-LTS Java releases — and why it mattered here
- Java ships a new feature release roughly every 6 months, but only some of them are **LTS (Long-Term Support)** — 21 was the latest LTS when this project started; the versions in between (22, 23, 24) get support for only about 6 months before being effectively obsolete.
- A real project generally wants to build on an LTS release — a non-LTS JDK (like 23, which turned out to be the only one installed on this machine) stops receiving updates quickly, which isn't a sound foundation for something meant to be a real, maintained application.
- **Maven toolchains** are the standard way to pin a project to a specific JDK regardless of whatever JDK a machine has set as its system default: a `~/.m2/toolchains.xml` file (machine-specific, not part of the repo) registers the available JDKs, and a `maven-toolchains-plugin` block in `pom.xml` (this part *is* committed, so it travels with the project) declares which one the build requires. Maven then finds and uses that exact JDK for compiling and running, ignoring `JAVA_HOME`/whatever `java` happens to be on `PATH`.

### A debugging lesson: the same code can fail in one launcher and succeed in another
- The backend hit a persistent `Unable to establish loopback connection` error when started via this session's automated shell — tried across two JDK versions and multiple JVM flags, all with the identical failure.
- Running the exact same project through IntelliJ started it cleanly in seconds — proving the problem was never the code, Spring Boot, or the JDK version, but something specific to how that one shell/process-launching context started Java processes on this machine.
- **Takeaway:** when a program fails to start in one environment but the error is deep in "internal plumbing" (not application logic), it's worth testing whether the failure follows the *code* or the *launcher* — swapping how you run something (a different terminal, an IDE, a different shell) is a legitimate and often fast way to isolate environment-specific bugs from real ones.

---

## Phase 0 (Frontend)

### `.tsx` and the `!` (non-null assertion) in `main.tsx`
- **`.tsx`** = TypeScript + JSX — the "x" means the file supports the `<App />` HTML-like syntax inside `.ts` code, same relationship as `.jsx` has to plain `.js`.
- **The problem `!` was papering over:** `document.getElementById('root')` has type `HTMLElement | null` in TypeScript, because the compiler can't know just from reading the code whether an element with that id actually exists on the page. `createRoot()` requires a real, non-null element, so there's a type mismatch to resolve one way or another.
- **`!` is TypeScript's non-null assertion operator** — it means "trust me, this will not be null here," and TypeScript stops complaining. It is a promise made to the compiler, not a runtime check; if the promise is ever wrong, it crashes at runtime instead of being caught at compile time.
- **This is the same category of risk as Kotlin's `!!` or Swift's forced unwrap (`!`)** — TypeScript isn't a special case here, it's the identical trade-off: skip the null check, and pay for it with a runtime crash if the assumption ever breaks.
- **Why it shows up in Vite's starter template anyway:** template/boilerplate code optimizes for "shortest path to a running demo," not for the discipline expected in a real, maintained codebase — comparable to an Xcode template force-unwrapping an `IBOutlet`. It being in the template isn't an endorsement of the pattern for real code.
- **Chosen instead, for this project:** an explicit null check that throws a clear error if the root element is ever missing, rather than asserting it away:
  ```tsx
  const rootElement = document.getElementById('root')
  if (!rootElement) {
    throw new Error('Root element not found')
  }
  createRoot(rootElement).render(...)
  ```
- **Worth knowing:** real TypeScript projects often enable an ESLint rule, `@typescript-eslint/no-non-null-assertion`, that flags any `!` usage project-wide — a candidate to turn on once ESLint is set up for this project.

### Why the frontend needs a dev server at all (it's not for reaching the backend)
- **Misconception to avoid:** the Vite dev server (port 5173) does **not** relay or proxy the call to the backend (port 8080). The browser makes both connections itself, independently — `fetch('http://localhost:8080/api/hello')` is a plain HTTP request straight from the browser, same as typing that URL into the address bar. Nothing is passed between the two server processes; the browser is the only thing talking to both.
- **The two processes are separate for a different reason:** there genuinely are two servers running (Vite, Spring Boot), on two different ports — which is exactly why CORS was needed (two different origins the browser is contacting).
- **What the dev server is actually for:** browsers only understand plain JavaScript/HTML/CSS — they cannot read `.tsx` files (TypeScript syntax, JSX like `<App />`) directly. The dev server's real job is translating that source code into plain JavaScript **on the fly**, live, every time a file changes, and serving the result to the browser over HTTP — plus Hot Module Reload, pushing just the changed piece into the running page instead of a full reload.
- **ELI5 version:** Two separate servers are like two helpers — one hands you the puppet/stage (Vite), another hands you a little note when asked (Spring Boot). You (the browser) run back and forth to each yourself; the helpers never talk to each other. Separately: writing the app in TypeScript/JSX is like writing a script in secret code — the audience (browser) only understands plain English (plain JS). While still writing/rehearsing, a translator (the dev server) stands next to you re-translating instantly every time you change a line. Once the show is finished, you translate the whole thing once, write it on paper, and hand it to a simpler helper (nginx) who just hands out the finished paper — no live translator needed anymore.
- **In production:** `npm run build` does the TypeScript/JSX translation once, ahead of time, producing plain `.html`/`.js`/`.css` files. Those get served by something else entirely (nginx, per the Phase 14 plan) — there's no dev server at all in production, since the translation work is already done. The dev server is a development-time-only convenience.

### Who delivers the finished frontend files, and who runs them
- **Build produces the paper, deploy delivers it:** `npm run build` only writes the translated files to disk (into `dist/`) — it doesn't put them anywhere nginx can see them. nginx has no idea about React, TypeScript, or the build process; it just hands out whatever files exist in a folder it's configured to look at. A separate **deployment** step has to actually move (or point nginx at) that `dist/` folder — e.g. a manual copy, baking the files into a Docker image alongside nginx, or an automated CI/CD pipeline that does this on every push. "Build" and "deploy" are two distinct steps, not one.
- **"Build once" means once per release, not once ever:** every time the source code changes and a new version should ship, `npm run build` runs again, producing a fresh `dist/`, which then gets deployed again, replacing the old files. It's "not needed live, on every request" (unlike the dev server), not a single one-time event for the project's whole life.
- **The build output is HTML + CSS + *and* JavaScript** — not just markup and styles. React component logic (handling clicks, fetching data, updating the page) still has to run as JavaScript in the browser; Vite's translation converts the TypeScript/JSX source into plain JavaScript that does the same thing, it doesn't remove the logic.
- **Serving the frontend vs. running it are different roles, held by different things:**
  - **nginx serves** the frontend — delivers the HTML/CSS/JS files to the browser as plain data (bytes over HTTP). It never executes any of it.
  - **The browser runs** the frontend — parses the HTML, executes the JavaScript, and becomes the active thing making further requests (for more assets, or via nginx's reverse proxy, for API data from Spring Boot).
- **Client/server is about roles in a request, not about "which code":** the **browser is the client** (in both directions — asking nginx for files, and asking Spring Boot for data through nginx's reverse proxy); the frontend *code* is what runs inside that client, not the client itself. Precise phrasing: "the browser is the client and runs the frontend code" rather than "the frontend is the client."

### "Connection refused" vs. a CORS/fetch error — two different failures, two different causes
- **"localhost refused to connect"** happens *before* your app code even runs — it means nothing is listening on that port at all (the dev server process isn't running, full stop). The browser can't even get the frontend's HTML/JS to load, so nothing inside it — including any `fetch()` call to the backend — ever gets a chance to execute.
- **A CORS error or a failed `fetch()`** is a completely different situation: the server *is* running and *did* answer, but something about the request itself was rejected (wrong origin, server error, etc.).
- **Why this distinction matters for debugging:** these two symptoms point to opposite fixes. "Refused to connect" → go start the server that's supposed to be listening there. A CORS/fetch error → the server's already up; look at the request/response and the server's config instead. Conflating the two wastes time chasing the wrong fix.
- **Concrete case that triggered this:** the Vite dev server process gets killed whenever a session ends (background processes don't survive on their own) — so "refused to connect" on `localhost:5173` after reopening the project almost always just means "the dev server needs to be started again," not a real bug.

---

## Working with Claude Code (tooling, not the app itself)

### When a subagent is worth it — and when it isn't
- A **subagent** is a separate Claude invocation with its own context window, spun up for a specific task and then discarded — it starts **cold**, with zero memory of the ongoing conversation.
- **Subagents earn their keep when:** a task is open-ended (needs exploration/searching before an answer is clear), genuinely parallelizable (several independent lookups that don't depend on each other), or would flood the main conversation with noise better kept separate (e.g. reading through many files just to answer one question).
- **Subagents are the wrong tool when:** the task is small and deterministic (a couple of known tool calls with a predictable outcome), or it depends on context already established in the conversation (like a previously-diagnosed bug) that would have to be re-explained from scratch every time — pure overhead with no benefit.
- **Concrete example from this project:** checking/starting the local dev servers was proposed as a subagent, but rejected for it — it's 2-3 deterministic tool calls, and the backend half depends on already-known context (a shell-specific bug documented in `docs/DECISIONS.md`) that a cold subagent would need re-fed every single time. A **skill** (a saved, directly-invoked set of instructions, no cold-start/context overhead) fit better for this repeatable-but-simple check.

---

## Phase 1 (Planning)

### What a database migration actually is
- A **migration** is a small, numbered, saved instruction file describing one change to the database's structure (e.g. "create the `products` table," "add a `founder_id` column") — like a filing-cabinet setup sheet, not a one-off command typed and forgotten.
- Running "the migrations" means: go through the numbered files in order and apply whichever haven't been applied yet, recording what's been done.
- **Why bother** instead of just editing the database by hand: (1) **reproducibility** — anyone, on any machine, can rebuild the identical database from nothing by replaying the files; (2) **history** — a readable record of exactly what changed and when, the database equivalent of `docs/DECISIONS.md`.

### Schema management: Flyway vs. Liquibase vs. Hibernate `ddl-auto` — sourced trade-offs
- **Hibernate `ddl-auto` (letting the ORM auto-generate schema from Java classes) is a confirmed, documented production hazard, not just a style preference.** Real, sourced risks: `update` mode can silently drop columns when an entity's mapping changes, can't replay changes deterministically (local/staging/prod can quietly drift apart from each other), and has no rollback path or audit trail. `create` mode wipes all data on every restart. Multiple independent sources agree: fine for quick local experiments only, never for anything that matters.
- **Flyway**: plain SQL migration files, numbered (`V1__create_products.sql`), tracked automatically. Simpler, no abstraction layer between what you write and what runs, reported to have better performance than ORM-driven schema management.
- **Liquibase**: same core idea, but supports SQL *or* a database-agnostic format (XML/YAML/JSON), plus extra features like labeling/skipping changes per environment. Its real advantages (multi-database support, complex environment branching) target problems this project doesn't have (Postgres-only, one environment for now).
- **Chosen: Flyway** — for the reasons above, plus it directly matches the plain-SQL learning approach already being used throughout this project.
- **Sources:** [Liquibase vs. Flyway](https://www.liquibase.com/liquibase-vs-flyway) · [Flyway vs Hibernate — StackShare](https://stackshare.io/stackups/flyway-vs-hibernate) · [Production profile uses Hibernate ddl-auto: update instead of a migration tool (GitHub issue)](https://github.com/jeffgicharu/wallet-api/issues/3) · [Why Hibernate ddl-auto: validate Is Dangerous in Production](https://blog.devgenius.io/why-ddl-auto-validate-is-dangerous-in-production-9b124be3b839)

### Why decide the migration tool now, not later — there's no true "neutral default"
- Spring Boot's actual default behavior against a real database (not an in-memory test DB) is `ddl-auto=none` — Hibernate creates nothing automatically. So "not deciding" doesn't mean deferring painlessly; it means the very first query fails because no table exists at all. Something has to create the first table, no matter what.
- The real question isn't "decide now vs. later," it's: **when that first table gets created, is the SQL saved to a version-tracked file, or typed once and lost?** Writing the `CREATE TABLE` SQL is required work either way — Flyway just means saving it, which is not extra work, it's the *same* work.
- The genuine cost of deferring: if a table is created informally now (e.g. via `ddl-auto`) and Flyway is "added later," Flyway needs a **baseline migration** — a special first migration describing a schema that already silently exists. That's real extra work that doesn't exist at all if Flyway is used from table #1.
- **Contrast with a genuinely-deferred decision** (the "up to 3 topics" cap enforcement, correctly pushed to Phase 3): that one requires building new logic to enforce a rule nothing can currently violate — real premature machinery. The migration-tool choice requires zero new logic, just where the same, already-necessary SQL gets saved.

### Screenshots: normalized child table vs. array/JSONB column
- A product's "screenshots" (plural) are just images showing what the product looks like — same concept as app-store preview images — one product can have several, per the client brief's product-posting form.
- **Normalized table** (`product_screenshots`: id, product_id, url, display_order) — chosen. Explicit, queryable ordering; consistent with how `product_topics` already models a one/many relationship; trivial to attach per-screenshot metadata (alt text, dimensions) later without changing a column's *type*.
- **Array/JSONB column alternative**: fewer tables, but ordering is implicit (whatever order the array holds), and holds no room for future per-item metadata without migrating to a table anyway — the "simpler" option quietly defers the same modeling work rather than avoiding it.

### Data access: Spring Data JPA vs. plain JDBC — recap
- **JPA** (chosen): describe a table's shape as a Java class (`@Entity`), get a repository interface that generates SQL from method names (`findByLaunchDateLessThanEqual(...)`) — far less code than writing every query by hand. The real-world default for Spring Boot specifically.
- **Plain JDBC**: every query is a literal SQL string, every row manually mapped field-by-field into a Java object by hand — full visibility, much more typing for the same result.
- **The known trap JPA introduces, on purpose, as a learning opportunity**: the **N+1 query problem** — fetching a list of N products can accidentally trigger N *extra* queries (one per product) just to fetch each one's topics, instead of one combined query. Phase 1 is where this gets hit and fixed properly (a fetch join / `@EntityGraph`), rather than read about abstractly.

### API responses: dedicated DTOs vs. raw JPA entities
- **Raw entities returned directly from the controller**: zero extra code — Spring/Jackson will happily turn a `@Entity` object straight into JSON. But this quietly couples two things that should stay independent: the shape of your *database table* and the shape of your *public API*. Rename or restructure a column, and the API response changes with it, even though no one asked for that.
- **The sharper, JPA-specific risk**: an entity often has *lazy-loaded* associations (e.g. a product's topics, only fetched from the database when actually accessed). If Jackson tries to serialize that association outside of an active database session, it can throw a confusing runtime error — or worse, silently trigger extra unwanted queries just because a field existed on the object, not because the response actually needed it.
- **Dedicated response DTOs** (e.g. `ProductSummaryDto`, `ProductDetailDto` — small classes/records holding just the fields an API response should have): a bit of extra mapping code, but the API contract becomes explicit and stable, chosen on purpose rather than "whatever the database happens to look like today." Sidesteps the lazy-loading serialization trap entirely, since only fields you deliberately copied into the DTO exist to be serialized.
- **Why this matters more here than it might seem:** it's an easy thing to skip on a "quick" read-only endpoint, but establishing the DTO habit now pays off directly once Phase 2 adds a `User`/founder relationship to products — that's exactly the point where accidentally serializing a raw entity could leak something sensitive (like a password hash) that was never meant to leave the backend.
- **Chosen: DTOs**, for both reasons above.

### "Walking skeleton" (a.k.a. tracer bullet, steel thread) — why Phase 1 is scoped the way it is
- A real, named, decades-old software engineering practice — coined by **Alistair Cockburn** in *Crystal Clear: A Human-Powered Methodology for Small Teams* (late 1990s), popularized across Agile. His definition: *"a tiny implementation of the system that performs a small end-to-end function... it need not use the final architecture, but it should link together the main architectural components."*
- Two independently-named equivalents exist from different well-known sources — **"Tracer Bullet"** (*The Pragmatic Programmer*) and **"Steel Thread"** — same core idea arrived at separately, decent evidence it's a genuine convergent pattern, not one opinion.
- Unlike a throwaway prototype/spike, a walking skeleton is meant to be kept, built with real production coding habits — exactly why Phase 0 wasn't disposable demo code.
- **The idea applied to this project:** Phase 0 proved frontend↔backend could talk. Phase 1 extends that same thin thread through the database, all the way to a browser. Once that full skeleton is provably solid, every later phase adds flesh to an already-working frame, instead of hoping several new integration points all work at once simultaneously.
- **Paths considered and rejected for Phase 1, with the reasoning:**
  - *Auth first* — rejected: the product list is public, read-only data needing zero protection; building security machinery before there's anything worth protecting is complexity with no job to do yet.
  - *Design the full schema now (users, votes, comments, notifications...)* — rejected: schema decisions get better the closer you are to actually using them; speculative full-schema design is the same premature-machinery trap being avoided elsewhere (e.g. the topics-cap deferral).
  - *Build the ranking algorithm first (the most novel part)* — rejected: it has a real dependency chain underneath it (ranking needs votes, votes need members, members need auth) — building it "first" would mean faking every layer beneath it, producing demo-ware rather than real progress.
  - *Build the submission form (write path) before the read path* — rejected: reads are strictly simpler/lower-risk than writes (no validation, no partial-failure handling, no concurrency conflicts to manage), and a product-discovery app's actual user-facing value is browsing — a visible product list is a real, demoable spine; a form that creates data nobody can see yet is not.
- **Sources:** [Start Your Project With a Walking Skeleton](https://www.henricodolfing.ch/en/start-your-project-with-a-walking-skeleton/) · [Walking Skeleton in Software Architecture](https://medium.com/@jorisvdaalsvoort/walking-skeletons-in-software-architecture-894168276e3f)

### Database "concurrency" — two genuinely different meanings, easy to conflate
- **Correctness/locking concurrency** (can simultaneous readers corrupt data or block each other?): for Postgres specifically, confirmed by Postgres's own docs — it uses **MVCC** (Multi-Version Concurrency Control), where readers never block writers and writers never block readers; each query just sees a consistent snapshot of the data. Thousands of simultaneous reads are genuinely fine here, correctness-wise.
- **Capacity/throughput concurrency** (can the system handle *huge numbers* of simultaneous requests?): a completely different axis — and here, "reads have no concurrency issues" does **not** imply "scale isn't a concern." A single Postgres instance running a live query per request would not survive something like a million near-simultaneous requests, regardless of MVCC.
- **The real-world layered fix, in the order it actually gets applied** (sourced from current system-design material, not just inferred): (1) **caching** first — highest benefit for the least complexity, since data that doesn't change every millisecond doesn't need a fresh database hit every request; (2) **read replicas** — multiple read-only database copies sharing `GET` traffic once caching alone isn't enough; (3) **CDN** for static assets (images/screenshots), served from servers physically closer to each visitor; (4) connection pooling/sharding — later still, sharding specifically called out as a last resort once data size/traffic genuinely justify the added complexity.
- **Status for this project: conceptual only, not implemented.** Building caching/replicas now, for a solo learning project with zero real users, would be exactly the premature-machinery trap avoided elsewhere in this plan — but worth knowing as "how this would need to evolve at real scale," a common systems-design interview topic.
- **Sources:** [PostgreSQL MVCC docs](https://www.postgresql.org/docs/current/mvcc-intro.html) · [Strategies to Scale Database Reads](https://akshatjme.medium.com/strategies-to-scale-database-reads-5671a7ac80e1) · [System Design Explained: APIs, Databases, Caching, CDNs](https://hayksimonyan.substack.com/p/system-design-explained-apis-databases)

---

## Phase 1 (Implementation)

### What `@Entity` actually is, annotation by annotation
- An `@Entity` class is the Java-side mirror of a database table — one class, one field per column — that Spring Data JPA uses to generate SQL automatically instead of writing `SELECT`/`INSERT` by hand.
- **`@Entity`** — marks the class as mapped to a table.
- **`@Id`** — marks which field is the primary key.
- **`@GeneratedValue(strategy = GenerationType.IDENTITY)`** — tells JPA "the database generates this value itself" (auto-increment), matching a `GENERATED ALWAYS AS IDENTITY` column in the SQL. If the Java side and the SQL side disagreed here, `ddl-auto=validate` would catch it at startup.
- **An empty `protected` no-arg constructor** — JPA needs a way to construct bare objects internally (via reflection) before populating fields; `protected` (not `public`) signals "for the framework's use, not for application code to call directly."
- **A real constructor + getters, no setters** — a deliberate immutable-by-default choice: once an entity is built, nothing can quietly mutate its fields from elsewhere in the code later. Many JPA tutorials default to setters everywhere, which is easy but invites bugs from state changing somewhere unexpected.

### Hibernate's default table-naming — a real bug caught before it happened
- **The mistake:** assumed Hibernate would automatically pluralize a class name for its table lookup (`Topic` → `topics`). This was wrong, and got caught before it caused a startup failure.
- **What Hibernate/Spring Boot's default naming strategy (`SpringPhysicalNamingStrategy`) actually does:** converts Java's `camelCase`/`PascalCase` into SQL's `snake_case`, and nothing else — no pluralizing. `Topic` → `topic` (singular), `ProductScreenshot` → `product_screenshot` (singular), by default.
- **Why it would have broken:** our actual table (from `V1__create_products.sql`) is named `topics` (plural). Without correcting the assumption, `Topic` would have looked for a table called `topic`, which doesn't exist — `ddl-auto=validate` would fail loudly at startup with a table-not-found error.
- **The fix:** `@Table(name = "topics")` on the entity — explicitly stating the real table name instead of relying on an implicit naming convention lining up by coincidence. Generally better practice regardless: Java class names are conventionally singular, SQL table names are very commonly plural — the two conventions don't automatically agree, so it's worth being explicit rather than assuming.

### JPA vs. Hibernate vs. Spring Data JPA vs. Spring Boot — four different things, often blurred into one
- **JPA (Jakarta Persistence API)** — a *specification only*: a set of rules/interfaces (`@Entity`, `@Id`, etc.) with no behavior of its own — a contract that any compliant ORM must follow.
- **Hibernate** — the actual *implementation* of that contract: the real library that reads `@Entity` classes and genuinely generates/runs SQL. This is the piece doing real work — not part of Spring itself, usable even without Spring at all.
- **Spring Data JPA** — a convenience layer built *on top of* JPA/Hibernate, providing things like `JpaRepository` interfaces where a method name (`findByLaunchDateLessThanEqual(...)`) becomes a real query automatically, without hand-writing it.
- **Spring Boot** — the outer framework that auto-configures all three together: adding `spring-boot-starter-data-jpa` makes Spring Boot pick Hibernate as the default JPA implementation and wire everything up with sensible defaults, so none of the above needs manual configuration.
- **Net picture:** Hibernate is not "Spring Boot's database manager" — Postgres manages the actual database, Flyway manages the schema, and Hibernate is an independent translation layer between Java objects and SQL that Spring Boot happens to auto-configure by default.

### `psql` vs. the JDBC driver — same protocol, two different messengers
- Both ultimately speak the same thing: Postgres's own network wire protocol. The difference is *who's* speaking it.
- **`psql`** — Postgres's own official command-line client (built in C, using a library called `libpq`) — talks to Postgres directly, no Java involved at all.
- **The JDBC driver (`org.postgresql:postgresql` in `pom.xml`)** — Java's implementation of that same wire protocol, wrapped inside Java's standard JDBC interface — what our actual Spring Boot app (and Flyway, internally) uses to talk to Postgres.
- **Used deliberately in this project** to verify hand-written migration SQL directly (fast, immediate error feedback) without needing to start the whole Java app just to catch a typo — see the manual-migration-verification entry below.

### Manually verifying migration SQL before letting Flyway apply it for real
- Since the backend can't be started in this session's shell (the known JVM loopback-socket issue — see the Phase 0 entry), hand-written migration SQL was verified a different way: piped directly into `psql` running inside the Postgres container (`docker exec -i launchpad-postgres psql ...`), bypassing JDBC/Flyway/Spring Boot entirely, to get immediate real feedback on whether the SQL itself was valid.
- **The catch with doing this:** running the files this way leaves real tables/data in the database, but with **no Flyway tracking record** that "V1/V2/V3 have been applied." Starting the real app afterward would make Flyway try to reapply `V1` from scratch and fail with "table already exists."
- **The fix:** after manually verifying the SQL was correct, fully reset the database — `docker compose down -v` (removes the container **and** its data volume, the "full reset" from the earlier Docker learnings) then `docker compose up -d` — leaving a genuinely empty database for Flyway to apply the same, now-verified files for real, for the first time, when the app actually starts.
- **`pg_isready`** — a small Postgres utility whose only job is answering "is the server accepting connections yet," used here to confirm the freshly-recreated container had actually finished starting before trying to use it.

### Writing the entities: `@ManyToOne`, object references instead of raw IDs, and immutability
- **`@ManyToOne` + `@JoinColumn(name = "product_id")`** (on `ProductScreenshot`) — declares "many screenshots can point to one product," and explicitly names the real foreign-key column instead of letting JPA guess it (same category of risk as the earlier table-pluralization bug — better to be explicit than rely on an implicit naming guess agreeing with reality).
- **Why the field is `private Product product;`, not `private Long productId;`** — the actual point of an ORM. A bare ID is like a library card with just a shelf number scribbled on it — you'd have to walk over and fetch the book yourself. A `Product product` field is the catalog handing you the real book directly: `screenshot.getProduct()` returns a full, usable `Product` object, with JPA quietly doing the join behind the scenes.
- **Immutable-by-default entities** (constructor + getters, no setters) — a deliberate choice across all four entities so far, avoiding the common JPA-tutorial pattern of a setter for every field, which invites bugs from state changing somewhere unexpected, far from where you'd look for it.
- **`displayOrder` (camelCase) → `display_order` (snake_case) works automatically, no annotation needed** — confirming the earlier naming-strategy lesson precisely: Hibernate's default naming *does* correctly convert case, it just never pluralizes. Case conversion was never the risky part.

### `@EntityGraph` — the actual fix for the cartesian-product bug, now real code
- **What it does, plainly:** tells JPA "when this query runs, also fetch these related collections in the same trip to the database" — instead of fetching the main row alone and making a separate extra trip later, the moment your code actually reads `.getTopics()` or `.getScreenshots()` (that "separate extra trip" is the N+1 problem).
- **Syntax note:** `attributePaths` always expects an array of strings, but Java lets you skip the `{}` braces when there's only one value — `attributePaths = "topics"` is shorthand for `attributePaths = {"topics"}`. Multiple values need the braces: `attributePaths = {"topics", "screenshots"}`.
- **The list-vs-detail split from the plan review, now actually written:** the list query's `@EntityGraph` names only `"topics"` (never `"screenshots"`) to avoid the cartesian-product/pagination trap; the detail query's names both, since a single row has no list to blow up or paginate.

### Derived query method names — Spring Data JPA's "magic," decoded
- `findByLaunchDateLessThanEqualOrderByLaunchDateDescIdDesc` is not magic, just a formula read left to right: `findBy` ("give me matching rows") + `LaunchDateLessThanEqual` (`WHERE launch_date <= ?`) + `OrderByLaunchDateDescIdDesc` (`ORDER BY launch_date DESC, id DESC`). Spring Data JPA parses the method name at startup and generates the real SQL from it — no SQL written by hand for this method.
- `findByIdAndLaunchDateLessThanEqual` follows the same formula (`WHERE id = ? AND launch_date <= ?`) — and is how a single product's "does this id exist" check and its embargo check collapse into one query, returning an empty result for either case (an unlaunched id and a genuinely nonexistent id look identical to the caller, matching the plan's "same 404 either way" decision).
- **Deliberate omission:** neither method calls `LocalDate.now()` itself — `today` is passed in as a parameter by whatever calls the repository. A repository's job is "fetch data given these inputs," not "know what today's date is" — that's business logic, which belongs one layer up, in the service.

### DTOs and Java `record` — a deliberately different shape than the entities
- **DTO = Data Transfer Object** — an object whose only job is carrying data from one place to another (here, backend → API caller), with no behavior of its own.
- **`record` vs. a regular class**: `public record TopicDto(Long id, String name, String slug) {}` is one line that generates an entire class behind the scenes — private final fields, a constructor, getters (`id()`, `name()`, `slug()`, no `get` prefix), plus working `equals()`/`hashCode()`/`toString()` — all automatically. It's Java's built-in way of saying "this is just a plain bundle of data."
- **Why records for DTOs but plain classes for entities:** entities need JPA's specific machinery (the `@Entity` annotation, the no-arg constructor JPA requires internally, mutable state Hibernate manages across a database session) — records don't support that well. DTOs have none of those requirements; they're built fresh, read once, and discarded — exactly the shape records are designed for. Different tool for a genuinely different job, not an inconsistency.
- **What "thrown away" actually means:** Java's **garbage collector** — a background JVM process that reclaims memory for objects nothing references anymore, entirely automatic, never explicitly triggered by application code. Concrete lifecycle of one `ProductSummaryDto`: service creates it → Spring/Jackson serializes it to JSON → response is sent → nothing in the program holds a reference to it anymore → at some later point the garbage collector reclaims its memory. Every Java object works this way; DTOs are just unusually short-lived by design — built for exactly one request/response cycle and then permanently done, unlike something like a long-lived config object kept alive for the app's whole run.

### Debugging a completely silent Flyway failure — a real methodology worth remembering
- **The trap:** the error message (`Schema validation: missing table [product_screenshots]`) pointed at Hibernate/JPA, making it easy to go down the wrong path (assuming a bad entity mapping, a bad migration file, or a stale build — all reasonable first guesses, all wrong here).
- **The signal that redirected the investigation:** checking the database directly for `flyway_schema_history` — the table Flyway creates for itself *before* running any actual migration. Its total absence (not "partially populated," not "has an error row," just *not there at all*) meant Flyway had never even attempted to connect, which is a fundamentally different problem than "a migration failed."
- **The general lesson:** when a startup error blames one component (here, Hibernate), it's worth checking whether an *earlier* component in the startup sequence (here, Flyway) actually ran at all, rather than assuming the component named in the error message is where the real problem lives. Fig. 2 of the Data Layer Flow diagram shows exactly why this mattered — Hibernate's validate step (②) only ever runs *after* Flyway's migrate step (①); a failure surfacing at step ② doesn't rule out the real problem being that step ① silently never happened.
- **The actual root cause, once found:** confirmed via Spring Boot's own docs rather than guesswork — Spring Boot 4.1 modularized its autoconfiguration, and Flyway's Spring-Boot-integration code moved into its own module (`spring-boot-flyway`), no longer bundled with the core `flyway-core` library the way it was on every previous Spring Boot version. This is a real, current (2026) breaking change specific to being on a very new Spring Boot release — worth remembering that "the classic way this always worked" can quietly stop working across a major version bump, silently rather than with a clear deprecation error.

### What a Spring "bean" is, and why `flywayInitializer` gets "created" at all
- **A bean** is Spring's name for any object *it* constructs and manages, instead of application code writing `new SomeClass()` directly. Marking `ProductService` as `@Service` was exactly this — telling Spring "manage an instance of this for me." Controllers, services, repositories, and a lot of Spring Boot's own internal machinery are all beans, built and wired together at startup into the **application context**.
- **`flywayInitializer` is a bean whose *construction itself* is the real work** — unlike a typical bean (build it, then later call methods on it), this one's entire job happens the moment it's built: connect to the database and run pending migrations. So "Error creating bean 'flywayInitializer'" is Spring's way of saying "I tried to run your migrations just now, and that failed" — not a report about some unrelated object.
- **Why Spring attempts to build it at that specific moment:** this is the actual mechanism behind Fig. 2's numbered ordering (① Flyway migrates, then ② Hibernate validates) — not a coincidence of timing, but an enforced dependency. Spring Boot's Flyway auto-configuration wires the `entityManagerFactory` bean (what Hibernate needs) to explicitly *depend on* `flywayInitializer` being built first. So when Spring goes to construct `entityManagerFactory`, it's forced to build `flywayInitializer` as a prerequisite — and that's precisely where the real database-connection attempt happens, and where our actual failures (missing Flyway wiring, then later "connection refused" once Docker wasn't running) both surfaced.
- **The takeaway:** Spring's bean-dependency graph is the concrete mechanism underneath "Flyway always runs before Hibernate checks the schema" — worth remembering next time a `BeanCreationException` names a bean that seems unrelated to the actual failure; the bean's *name* often tells you which stage of startup broke, even when the underlying cause (here, first a missing dependency, then later Docker not running) is external to Spring entirely.

### "No pagination problem" doesn't mean "no cartesian-product problem" — two separate consequences of the same cause
- Eagerly joining two collections in one query (`@EntityGraph(attributePaths = {"topics", "screenshots"})`) has **two independent bad consequences**, not one: (1) SQL-level pagination breaks (the issue the plan review caught, specific to *lists* of rows), and (2) every combination of the two collections becomes its own row — a true cartesian product (2 topics × 3 screenshots = 6 rows) — which happens **regardless of whether there's a list to paginate at all**. A single-row detail endpoint is immune to problem (1) but not problem (2).
- **Why the duplication was visible on `screenshots` but invisible on `topics`**, given both came from the same duplicated SQL rows: `topics` is a `Set<Topic>` — sets silently discard an item that's already present (and within one Hibernate session, the *same* database row always resolves to the *same* Java object instance, so a duplicate insert is trivially recognized and dropped). `screenshots` is a `List<ProductScreenshot>` — lists never deduplicate on insert, so every duplicate row survived straight through into the JSON response.
- **The fix, and why it's justified, not just a workaround:** stop eager-fetching `screenshots` on the detail endpoint; let it lazy-load. The entire reason eager-fetching exists is avoiding N+1 queries *across a list of many rows* — for a single-product lookup, "N+1" is really just "+1," one harmless extra query. The performance problem eager-fetching solves was never present here in the first place, so removing it costs nothing.
- **The general lesson:** "fetch fewer collections eagerly" and "fetch collections in a way that doesn't duplicate rows" are two different fixes for two different symptoms of the same root cause (joining multiple collections in one query) — fixing one doesn't automatically fix the other, and this one was only caught by actually testing the live endpoint's real JSON output, not by reasoning about the query annotations alone.
