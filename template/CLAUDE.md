# CLAUDE.md

<!-- TODO: one paragraph on what this repository is and its main constraints. -->

## Layout

```
<!-- TODO: top-level folders and what lives in each -->
docs/        architecture, phases/ (the plan), decisions/ (ADRs), plan-reviews/
scripts/     check.sh (all checks), integrator.sh; optional worktree-setup.sh, verify-reset.sh
.claude/     settings.json (enables the multi-agent plugin), prompts/integrator.md
```

The workflow itself (skills, agents, guard hooks, notifications, `new-worktree.sh`,
`verify-merge.sh`) comes from the `multi-agent` plugin
(https://github.com/R0drig0V1/claude-code-multi-agent), enabled in `.claude/settings.json`.

## Commands (run from the repo root)

```bash
scripts/check.sh                   # lint + types + tests; must stay green (edit it per project)
scripts/integrator.sh              # launch the integrator session (main worktree only)
/multi-agent:worktree <type>/<name>   # development worktree for one branch (inside Claude Code)
# TODO: build, run, test commands of this project
```

## Rules

- **Language:** code, identifiers, comments, docs and commits in **English**.
  <!-- TODO: language to answer the user in, if not English. -->
- **Document everything.** Module docstring (or header comment) on every file; docstrings on
  public functions with behaviour and failure modes; comments explain *why*. Update the
  matching `docs/` page in the same change (use `/multi-agent:document`; the code→docs map
  is in it).
- **Decisions** that are hard to reverse or that future readers would question get an ADR in
  `docs/decisions/NNNN-title.md`.
- `scripts/check.sh` is the single definition of "green": `/multi-agent:commit`,
  `/multi-agent:pr` and the integrator's `verify-merge.sh` all run it.
<!-- TODO: project-specific rules (architecture boundaries, invariants, conventions) -->

## Plan and workflow

- The development plan lives in `docs/phases/` (roadmap: `docs/phases/README.md`). Check the
  current phase before starting work.
- Before starting a phase: `/multi-agent:improve-plan` (the `plan-adversary` agent reviews
  it). Reviews go to `docs/plan-reviews/`.
- Skills: `/multi-agent:commit` (Conventional Commits, no emojis, checks first), `:pr`,
  `:document`, `:improve-plan`, `:worktree`, `:integrate` (integrator only).
- Agents: `plan-adversary` (read-only critic of the plan), `code-reviewer` (read-only bug and
  security review; the integrator uses it on large diffs).

## Multi-agent workflow

Several Claude sessions work in parallel; `main` only moves through the integrator.

- **Main worktree (this checkout) = integrator only.** One session, launched with
  `scripts/integrator.sh` (sets `CLAUDE_ROLE=integrator`, names it `integrator` and appends the
  adversarial-auditor prompt `.claude/prompts/integrator.md`). It runs
  `/multi-agent:integrate`: verify each open PR merged onto `main`, push green ones, bounce
  the rest. It never develops. The plugin's hooks block any other session from changing it:
  Edit/Write in the main worktree, and in the shell git commits/checkouts, file writes,
  dependency installs, pushes to `main` and `gh pr merge`.
- **Everyone else works in a worktree of their own:** `/multi-agent:worktree <type>/<name>`
  creates `../<repo>-<name>` with its own branch (and runs `scripts/worktree-setup.sh` there,
  if the project has one) and switches the session into it. A session opened in the main
  worktree is told by a `SessionStart` hook to do this from the first request that needs
  changes. Subagents that edit code use `isolation: "worktree"`.
- **Finishing:** rebase on `origin/main`, `/multi-agent:pr`, which also sends `integrator` a
  "PR #N ready: ..." message. Open PRs are the queue; the message only wakes it up. The
  verdict comes back as a PR comment (and a reply message); fix bounces in your worktree and
  announce again.
- **`docs/phases/` belongs to the integrator.** List completed tasks under "Plan tasks
  completed" in the PR body instead of ticking them.
