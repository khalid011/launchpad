---
name: commit-and-push
description: Stage, commit, and push the current changes in the Launchpad repo to GitHub, with a well-written commit message. Use when the user asks to commit, commit and push, or save/sync their changes to GitHub.
---

Run the full commit-and-push flow for the Launchpad repo (`C:\Users\Khalid_HP\Desktop\Work\Project\Web\Launchpad`). Being invoked is the user's explicit request for this — no need to ask "should I commit?" separately, but do follow every safety step below.

## 1. Survey what's changed

Run in parallel: `git status`, `git diff` (unstaged) and `git diff --staged` (already staged, if any), and `git log --oneline -10` to match this repo's message style.

## 2. Check for anything that shouldn't be committed

Before staging, look over the changed/untracked files for:
- Anything that looks like a secret, credential, or API key — even in an innocuously-named file. If found, stop and flag it to the user instead of committing it.
- Large or generated files that should have been gitignored (`node_modules/`, `target/`, `.idea/`, build output) — if `.gitignore` already covers them this won't come up, but double-check `git status` doesn't show them anyway.

## 3. Stage specific files, not a blanket add

Prefer `git add <specific files>` over `git add -A`/`git add .` when the changeset is easy to enumerate, to avoid accidentally staging something unintended. A blanket `git add -A` is fine once you've already reviewed `git status` and confirmed everything listed is meant to be committed.

## 4. Write the commit message

- Summarize the *why*, not just the *what* — 1-2 sentences, matching the tone of this repo's existing commit(s) (see `git log`).
- Use a heredoc for the message so formatting is preserved:
  ```
  git commit -m "$(cat <<'EOF'
  <summary line>

  <optional body>

  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  EOF
  )"
  ```
- Always include the `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>` trailer.

## 5. Commit, then push

- Run the commit, then `git status` to confirm it succeeded.
- If a pre-commit hook fails: fix the actual issue, re-stage, and make a **new** commit — never `--amend` after a hook failure (the commit didn't happen, so amend would touch the previous real commit instead) and never `--no-verify` to skip it.
- Push with a plain `git push` (the upstream is already set to `origin/master`). Never force-push (`--force`/`-f`) — if a push is rejected because the remote has moved on, stop and tell the user rather than forcing.

## 6. Report

Tell the user the commit hash/summary and confirm the push succeeded (or explain clearly what went wrong if it didn't).
