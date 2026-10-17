---
name: pr
description: Open a pull request for the current work on GitHub with a clear summary and test plan, and announce it to the integrator. Use when the user asks for a PR, "haz un PR", "abre un pull request", or to publish a finished branch.
---

# Pull request

## 1. Branch

- Never open a PR from `main`, and never from the main worktree: development happens in a
  worktree of its own (`/multi-agent:worktree <type>/<short-kebab-description>`, e.g.
  `feat/user-login`, `fix/session-timeout`). See "Multi-agent workflow" in CLAUDE.md.
- Make sure everything intended is committed (use the `commit` skill if not).
- Rebase onto the latest `main` so the integrator merges what you tested:
  `git fetch origin && git rebase origin/main`. If a new migration of yours no longer chains
  onto main's latest one, renumber it and re-chain it now.

## 2. Check

```bash
scripts/check.sh
git log --oneline origin/main..HEAD
git diff --stat origin/main...HEAD
```

Read the full diff against `main` to write the description; do not rely on commit subjects only.

## 3. Push and create

```bash
git push -u origin HEAD
```

If the GitHub CLI is available (`command -v gh`), create the PR with it:

```bash
gh pr create --base main --title "<conventional title>" --body-file - <<'BODY'
...
BODY
```

If `gh` is not installed, tell the user (`brew install gh && gh auth login`) and print the
compare URL instead, built from the `origin` remote
(`https://github.com/<owner>/<repo>/compare/main...<branch>?expand=1`), together with the
title and body ready to paste.

## 4. Body template (English)

```markdown
## Summary
<1-3 sentences: what and why>

## Changes
- <area>: <change>

## Migrations / data
<"None" or: what it does, whether it is reversible, and how it was tried>

## Test plan
- [ ] `scripts/check.sh`
- [ ] <manual check: command run and what it showed>

## Docs
<which docs/ pages were updated>

## Plan tasks completed
<phase file and task lines the integrator should tick, e.g. `docs/phases/1-auth.md`:
"Add login endpoint". Do not tick them yourself: the integrator owns docs/phases/.>
```

End the body with the PR attribution line this environment specifies, if any.

## 5. Announce it to the integrator

The integrator session is named `integrator`. If `ListAgents` shows it, send it one message
(it wakes up and runs `/integrate`):

```
SendMessage(to="integrator", message="PR #<N> ready: <branch> - <title>\n<migrations: none | ...>\n<anything risky the reviewer should look at>")
```

If it is not listed, do nothing more: open PRs are its queue, and it picks yours up when it
starts. Its verdict arrives as a PR comment and, if you messaged it, as a reply message. On a
bounce, fix the branch in your worktree, push, and announce again.

## 6. Report

Give the user the PR URL (or the compare URL), the title, and whether the integrator was
notified.
