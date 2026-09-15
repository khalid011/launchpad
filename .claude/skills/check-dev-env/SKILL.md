---
name: check-dev-env
description: Check whether Launchpad's local dev servers (Spring Boot backend on :8080, Vite frontend on :5173) are running, and start the frontend if it's down. Use when the user asks to check, verify, or start the local dev environment/servers.
---

Check Launchpad's local dev environment. Two components only — do not check or start Docker/Postgres unless the user is specifically working with the database (it's not needed until Phase 1).

## 1. Backend (Spring Boot, should be on :8080)

Check: `curl -s -m 3 -o /dev/null -w "%{http_code}" http://localhost:8080/api/hello`. `200` = up.

**Never attempt to start the backend yourself** (`mvnw spring-boot:run` or similar) — this shell has a known, already-diagnosed JVM/Windows loopback-socket bug that prevents the backend from starting here (`Unable to establish loopback connection`), unrelated to the code. See `docs/DECISIONS.md` ("Backend startup issue: resolved — was a shell-launcher problem, not the project") for the full writeup. The working fix is running `BackendApplication` from IntelliJ (Project SDK pinned to JDK 21).

If it's down, just report that and tell the user to start it in IntelliJ.

## 2. Frontend (Vite, should be on :5173)

Check: `curl -s -m 3 -o /dev/null -w "%{http_code}" http://localhost:5173/`. `200` = up.

If it's down, start it: `cd "C:\Users\Khalid_HP\Desktop\Work\Project\Web\Launchpad\source\frontend" && npm run dev`, run in the background (long-running dev server), then re-check the port after a few seconds to confirm it came up. This one is safe to start directly — Node/Vite has never hit the loopback issue.

## Report

One short line per component: already up / started successfully / needs manual action (backend only, in IntelliJ).
