# Launchpad — Career & Job-Market Takeaways

This file re-reads `docs/LEARNINGS.md` through a different lens: not "what did I learn" but "what of this is actually worth mentioning in an interview or on a resume." Updated alongside `LEARNINGS.md`, phase by phase.

**How to read this file:** every claim is tagged so you know how solid the ground under it is:
- 🔎 **Sourced** — backed by an actual job-market search (link included), not just inferred.
- 💭 **My assessment** — my own reasoning, clearly not verified against real market data. Useful context, not proof.

Last research pass: 2026-09-16. Job markets move — worth re-checking every few months, not treating as permanently true.

---

## What the research actually says (baseline, before mapping to our progress)

🔎 Across current Spring Boot / full-stack job postings and 2026 backend-developer skills surveys:
- The consistently recurring core skill cluster is: **Java/Spring Boot, REST APIs, SQL, Git, Docker, and a cloud platform.**
- **SQL is the single fastest-growing requested skill** (+25.5% year-over-year) — ahead of most languages.
- **Docker/containerization** is explicitly called "critical," alongside Kubernetes and cloud-native architecture, though Kubernetes/cloud go beyond what a solo local-dev learning project covers.
- Security is framed as a *responsibility* backend developers own ("architects of systems that handle authentication, data processing, business logic"), not usually listed as its own line-item skill separate from "REST API" / "security" more broadly.
- **AI-assisted coding tools** (Claude Code is explicitly named) are increasingly worth mentioning — but research is consistent that *naming the tool* isn't valued; what's valued is showing a specific, measurable outcome and the ability to critically evaluate AI output rather than accept it uncritically.

Sources: [Java Full Stack Developer Skills: Complete 2026 List](https://consultadd.com/blog/java-full-stack-developer-skills-the-complete-list) · [9 Backend Developer Skills You Need to Master in 2026](https://interviewkickstart.com/skills/backend-developer) · [Backend Developer Skills That Pay More in 2026](https://jobcannon.io/skills-for/backend-developer) · [AI Skills on Your Resume in 2026](https://www.akkodis.com/en/blog/articles/ai-skills-resume-2026)

---

## Phase 0 — mapped against that baseline

### Confirmed relevant (🔎 sourced)
- **Docker fundamentals** — we've gone beyond "docker run": understand containers as namespaced/cgrouped processes (not VMs), named-volume data persistence separate from container lifecycle, and why Docker Desktop on Windows runs a WSL2 Linux VM underneath. Docker is explicitly named as a critical, recurring requirement — this is real, demonstrable depth on a confirmed in-demand skill.
- **Git** — repo initialized, meaningful first commit, pushed to GitHub. Confirmed baseline requirement, nothing more to say yet — this becomes more resume-relevant once there's real commit history showing incremental, well-described work (which our phase-by-phase approach is naturally building).
- **Spring Boot + Maven basics** — project scaffolded and running. Core requirement per research, but this is genuinely just the starting point — REST API design (the actually-valued part) hasn't happened yet; that's Phase 1.

### Real, but not yet a "resume line" — foundational understanding, not a named market skill
- **CORS, TLS/HTTPS, reverse-proxy (nginx) responsibilities** — correct, real understanding, but not something postings list as a standalone skill; it lives underneath "REST API design" / "security" more broadly. 💭 My honest read: this is worth being *able to explain well in an interview* if security or API design comes up, but not something to bullet-point on its own yet.
- **Maven toolchains / JDK LTS pinning** — 💭 correct and somewhat uncommon knowledge (most developers don't know this exists), but I have no research confirming employers specifically screen for it. Treat as a good interview anecdote ("I hit a real environment bug and fixed it properly"), not a named skill.

### Debugging methodology (💭 my assessment, not sourced)
- Isolating the JVM loopback-socket bug by testing a different launcher (IDE vs. shell) rather than endlessly guessing at code/flags — this is a real, demonstrable debugging story with a clear before/after. I can't point to a survey that says "employers value debugging methodology," but structured troubleshooting is a near-universal interview topic ("tell me about a hard bug you fixed") — this is genuine material for that question, told honestly rather than embellished.

### Working with AI-assisted development (🔎 sourced, with an important caveat)
- Research is explicit: naming "Claude Code" isn't the valuable part — *what you did with it and how you verified its output* is. This actually connects to something real that already happened in this project: at one point I (Claude) made unsourced claims about which skills were "job-market relevant," and you correctly challenged that and asked me to verify it before trusting it — which is precisely the "critically evaluate AI output rather than accept it" behavior the research says employers value. That's a genuinely usable, specific anecdote, not a vague "I used AI tools" line.
- TypeScript null-safety discipline (rejecting Vite's default `!` non-null assertion for an explicit check) is a small, real example of *not* just accepting AI-generated boilerplate — worth remembering as another concrete instance of the same pattern.

---

## Phase 1 (backend) — mapped against that baseline

This is the phase the "what's still missing" section below used to point at. It's done now — the gap it named is filled.

### Confirmed relevant (🔎 sourced)
- **SQL/database schema design** — designed and wrote real migration SQL by hand (Flyway, not a GUI tool or an ORM auto-generating it): a `products` table with an indexed date-range filter, a many-to-many join table (`product_topics`), a one-to-many child table (`product_screenshots`), foreign keys with explicit `ON DELETE` behavior. This is squarely the #1 fastest-growing requested skill from the baseline research, and it's real schema-design work, not just `SELECT` queries.
  > *"Designed and implemented a normalized PostgreSQL schema (many-to-many and one-to-many relationships, indexes, foreign-key constraints) via versioned Flyway migrations."*
- **REST API design** — `GET /api/products` and `GET /api/products/{id}`, with a deliberate DTO layer separating the API contract from the database schema, and business-rule enforcement (an embargo/launch-date filter) at the query level rather than bolted on after. Core requirement per the baseline research, and now actually demonstrated, not just "Spring Boot installed."
  > *"Designed and implemented REST endpoints with a dedicated DTO layer, decoupling the public API contract from the persistence model."*
- **JPA/Hibernate (ORM) proficiency, including a known real-world trap handled correctly** — deliberately worked through the N+1 query problem and a related cartesian-product duplication bug, using `@EntityGraph` fetch strategies matched to each endpoint's actual shape (a list vs. a single row) rather than one blanket fetch strategy everywhere. This is a genuinely common, genuinely tricky Spring/Hibernate interview topic, now backed by a real, specific example instead of textbook knowledge.
  > *"Diagnosed and resolved an eager-fetch cartesian-product bug in a Spring Data JPA repository, correcting the fetch strategy per endpoint to avoid both duplicate results and a related pagination failure mode."*

### Two specific, honest debugging stories (💭 genuinely strong interview material, not oversold)
- **The Spring Boot 4.1 Flyway module split** — a real, current (2026) breaking change in a just-released framework version, found by checking Spring Boot's own docs/changelog rather than guessing, after the standard `flyway-core` dependency pattern silently stopped working. This is a good story specifically *because* it wasn't a typo or a skill gap — it's "the framework changed under me, and I found out why instead of copy-pasting a random Stack Overflow fix."
- **The cartesian-product screenshot-duplication bug** — caught by actually testing the live endpoint's JSON output, not by code review, and root-caused precisely (a `Set` silently deduplicating vs. a `List` that doesn't, both fed by the same duplicated SQL rows). Shows real understanding of *why* the bug happened, not just that changing something made it go away.
- Both are concrete enough to survive a real follow-up question ("what exactly went wrong, how did you find it") — the thing that separates a real story from a rehearsed one.

## What's still missing before there's a strong "resume-ready" story

Being honest about what's still not there: the **frontend** half of Phase 1 hasn't been built yet (a product list page consuming this API), and Phases 2–14 — accounts/auth, real user-generated data, voting, the ranking algorithm, deployment — are all still ahead. Auth and deployment in particular map to more of the baseline research's named skills (security ownership, cloud/containerized deployment) that aren't demonstrated yet. This file should get another real update once the frontend is live, and again once auth exists.
