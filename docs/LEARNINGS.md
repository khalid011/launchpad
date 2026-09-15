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
