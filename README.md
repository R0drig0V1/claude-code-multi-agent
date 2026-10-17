# repo_init

Starting template for new repositories with a Claude Code setup: skills (`/commit`, `/pr`,
`/document`, `/improve-plan`, `/integrate`), the `plan-adversary` agent, guard hooks for a
multi-agent workflow (one integrator session owns `main`; everyone else works in a worktree),
and sound + terminal-bell notifications when a session stops or needs attention.

## Adapting it to a project

1. Fill in the `TODO`s of `CLAUDE.md` (purpose, layout, commands, rules) and the code→docs
   map in `.claude/skills/document/SKILL.md`.
2. Put the project's lint/type/test commands in `scripts/check.sh`.
3. Optionally add `scripts/worktree-setup.sh` (per-worktree setup: dependencies, a private
   test database) and `scripts/verify-reset.sh` (reset the integrator's shared test state).

## Workflow

- Integrator: `scripts/integrator.sh` in the main checkout, then `/integrate`.
- Development: `scripts/new-worktree.sh <type>/<name>`, work there, finish with `/pr`.

See "Multi-agent workflow" in `CLAUDE.md`.
