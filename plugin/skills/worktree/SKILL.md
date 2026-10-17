---
name: worktree
description: Create a development worktree for one branch and switch the session into it, as the multi-agent workflow requires before changing any file. Use when the SessionStart hook says the session is in the main worktree and the request needs changes, when a guard hook blocked an edit in the main worktree, or when the user asks for "un worktree", "una rama nueva para esto", "/worktree".
argument-hint: "<type>/<short-kebab-name>  e.g. feat/user-login"
---

# Worktree

Development never happens in the main worktree (it belongs to the integrator). Every task
gets its own branch and worktree.

## 1. Name the branch

Use `$ARGUMENTS` if given. Otherwise derive `<type>/<short-kebab-name>` from the user's
request: `type` is one of feat, fix, docs, chore, refactor, test; the name is 2-4 words,
e.g. `fix/session-timeout`.

## 2. Create it

Run from anywhere inside the repository:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/new-worktree.sh" <type>/<short-kebab-name>
```

It creates `../<repo>-<short-kebab-name>` on a new branch from `origin/main` (or local
`main`), copies the main checkout's `.env`, and runs the project's `scripts/worktree-setup.sh`
there if it exists. It prints `worktree ready: <path>`. If the branch or path already exists,
it fails: pick another name or ask the user whether to reuse the existing worktree.

## 3. Switch into it

Call `EnterWorktree` with `path=<that path>`. From then on edit, test and commit only there,
and finish with `/multi-agent:pr`.

## 4. Report

Tell the user the branch and the worktree path in one line.
