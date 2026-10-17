# CLAUDE.md

<!-- TODO: one paragraph on what this repository is and its main constraints. -->

## Layout

```
<!-- TODO: top-level folders and what lives in each -->
docs/        architecture, phases/ (the plan), decisions/ (ADRs), plan-reviews/
scripts/     check.sh (all checks), new-worktree.sh, integrator.sh, verify-merge.sh
.claude/     skills, agents, hooks (worktree guards, sound + bell alerts), integrator prompt
```

## Commands (run from the repo root)

```bash
scripts/check.sh                   # lint + types + tests; must stay green (edit it per project)
scripts/new-worktree.sh <type>/<name>   # development worktree for one branch
scripts/verify-merge.sh            # integrator only: verify a --no-commit merge; exit code = verdict
# TODO: build, run, test commands of this project
```

## Rules

- **Language:** code, identifiers, comments, docs and commits in **English**. Answer the user
  in **Spanish**.
- **Document everything.** Module docstring (or header comment) on every file; docstrings on
  public functions with behaviour and failure modes; comments explain *why*. Update the
  matching `docs/` page in the same change (use the `document` skill; the code→docs map is in
  it).
- **Decisions** that are hard to reverse or that future readers would question get an ADR in
  `docs/decisions/NNNN-title.md`.
- `scripts/check.sh` is the single definition of "green": `/commit`, `/pr` and
  `scripts/verify-merge.sh` all run it.
<!-- TODO: project-specific rules (architecture boundaries, invariants, conventions) -->

## Plan and workflow

- The development plan lives in `docs/phases/` (roadmap: `docs/phases/README.md`). Check the
  current phase before starting work.
- Before starting a phase: `/improve-plan` (the `plan-adversary` agent reviews it). Reviews go
  to `docs/plan-reviews/`.
- Skills: `/commit` (Conventional Commits, no emojis, checks first), `/pr`, `/document`,
  `/improve-plan`, `/integrate` (integrator only).
- Agents: `plan-adversary` (read-only critic of the plan), `code-reviewer` (code review).

## Multi-agent workflow

Several Claude sessions work in parallel; `main` only moves through the integrator.

- **Main worktree (this checkout) = integrator only.** One session, launched with
  `scripts/integrator.sh` (sets `CLAUDE_ROLE=integrator`, names it `integrador` and appends the
  adversarial-auditor prompt `.claude/prompts/integrator.md`). It runs `/integrate`: verify
  each open PR merged onto `main`, push green ones, bounce the rest. It never develops.
  Hooks block any other session from changing it: `guard-main-worktree.sh` (Edit/Write) and
  `guard-main-bash.py` (shell: git commits/checkouts, file writes, pushes to `main`,
  `gh pr merge`).
- **Everyone else works in a worktree of their own:** `scripts/new-worktree.sh <type>/<name>`
  creates `../<repo>-<name>` with its own branch (and runs `scripts/worktree-setup.sh` there,
  if the project has one). A session opened in the main worktree is told by a `SessionStart`
  hook to do this itself, from the first request that needs changes, and to switch into it
  with `EnterWorktree`. Subagents that edit code use `isolation: "worktree"`.
- **Finishing:** rebase on `origin/main`, `/pr`, then `SendMessage` to `integrador`
  ("PR #N listo: ..."). Open PRs are the queue; the message only wakes it up. The verdict comes
  back as a PR comment (and a reply message); fix bounces in your worktree and announce again.
- **`docs/phases/` belongs to the integrator.** List completed tasks under "Plan tasks
  completed" in the PR body instead of ticking them.
