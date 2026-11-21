# claude-code-multi-agent

[![Status: archived](https://img.shields.io/badge/status-archived-lightgrey.svg)](#claude-code-multi-agent)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-d97757.svg)](https://code.claude.com/docs/en/plugins/overview)

> **Archived in November 2026.** This repository is read-only and no longer maintained: it
> gets no fixes, and issues and pull requests are closed.
>
> Its successor is [herdr-agent-pool](https://github.com/R0drig0V1/herdr-agent-pool). It keeps
> the same idea (an integrator verifies and merges pull requests, every other session works
> in its own git worktree) and adds a coordinator, a pool of parallel integrators and a
> machine-wide resource budget. It runs inside [herdr](https://herdr.dev).
>
> The plugin described below still installs and works as it was at the last commit. Use it
> if you need this workflow without herdr; start new projects with herdr-agent-pool.

A [Claude Code](https://code.claude.com) plugin for running **several Claude sessions in
parallel on one repository** without them stepping on each other or on `main`.

- **One integrator owns `main`.** It verifies each pull request merged onto `main`, merges the
  green ones and bounces the rest with evidence. It acts as an adversarial auditor, not a
  helper.
- **Every other session works in its own git worktree** and branch, and finishes with a pull
  request.
- **Hooks enforce it.** Edits, commits, dependency installs and pushes to `main` from a
  non-integrator session are blocked before they run.
- **Sound + terminal bell** tell you which tab finished or needs attention (macOS, Linux,
  Windows).

```mermaid
flowchart LR
    A["session A<br/>worktree feat/login"] -- "/multi-agent:pr" --> Q[(open PRs)]
    B["session B<br/>worktree fix/timeout"] -- "/multi-agent:pr" --> Q
    Q -- "/multi-agent:integrate" --> I{"integrator<br/>verify-merge.sh"}
    I -- "exit 0: merge + push" --> M[main]
    I -- "fail: bounce with evidence" --> A
```

## Install

The commands below still work: they install the last version, which no longer changes.

### Plugin + project files (recommended)

From inside the repository you want to set up:

```bash
curl -fsSL https://raw.githubusercontent.com/R0drig0V1/claude-code-multi-agent/main/install.sh | bash
```

The installer copies the project-owned files and never overwrites existing ones
(`--dry-run` previews, `--force` overwrites). It also enables the plugin in
`.claude/settings.json`, so teammates get it when they trust the folder. Commit the result
on `main`.

### Plugin only

```
/plugin install multi-agent --marketplace R0drig0V1/claude-code-multi-agent
```

or, on older Claude Code versions:

```
/plugin marketplace add R0drig0V1/claude-code-multi-agent
/plugin install multi-agent@claude-code-multi-agent
```

The guard hooks only act in repositories whose `.claude/settings.json` (or
`settings.local.json`) enables `multi-agent@claude-code-multi-agent`. A user-scope install
therefore leaves your other repositories alone and only adds the notifications there.

## Usage

| Who | How |
|-----|-----|
| Integrator | `scripts/integrator.sh` in the main checkout, then `/multi-agent:integrate` |
| Developer session | `/multi-agent:worktree feat/<name>`, work, `/multi-agent:commit`, `/multi-agent:pr` |
| Before a phase | `/multi-agent:improve-plan` (red-team review of `docs/phases/`) |
| Security audit | `/multi-agent:security-audit`, or ask "security audit this codebase"; a full audit writes its reports outside the repository, in `~/security-audit-skill/<repo>/run-<N>` |

A session opened in the main checkout is told by the `SessionStart` hook to create its own
worktree from the first request that needs changes.

## What's inside

| Component | Name | What it does |
|-----------|------|--------------|
| Skill | `worktree` | Creates `../<repo>-<name>` on a new branch from `origin/main` and switches the session into it |
| Skill | `commit` | Conventional Commits in English, runs `scripts/check.sh` first, never stages secrets |
| Skill | `pr` | Rebases, checks, opens the PR with a structured body, messages the integrator |
| Skill | `integrate` | Integrator loop: queue → merge `--no-commit` → `verify-merge.sh` → merge or bounce → update plan |
| Skill | `document` | Brings docstrings, `docs/`, ADRs and `CLAUDE.md` up to date |
| Skill | `improve-plan` | Up to 3 adversarial rounds against `docs/phases/` with `plan-adversary` |
| Skill | `security-audit` | Cloudflare's [security-audit skill](https://github.com/cloudflare/security-audit-skill), vendored unchanged (MIT, its own `LICENSE`): security guidance by default, a six-phase audit with independent verification when asked for one |
| Agent | `plan-adversary` | Read-only red-team reviewer of the plan |
| Agent | `code-reviewer` | Read-only bug and security reviewer |
| Hook | `guard-main-worktree.sh` | Blocks Edit/Write in the main worktree |
| Hook | `guard-main-bash.py` | Blocks shell writes, mutating git, dependency changes and formatters in the main worktree, plus `gh pr merge` and pushes to `main` |
| Hook | `session-start-worktree.sh` | Tells sessions in the main worktree to move to a worktree |
| Hook | `notify.sh` | Sound and terminal bell on Stop / Notification |
| Script | `new-worktree.sh`, `verify-merge.sh` | Worktree creation; verification gate whose exit code is the verdict |

Project-owned files from `template/`:

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Rules and workflow for the agents, with `TODO`s for your project |
| `scripts/check.sh` | **Your** lint/type/test commands: the single definition of "green" |
| `scripts/integrator.sh` | Launches the integrator (`CLAUDE_ROLE=integrator`, session name `integrator`, auditor prompt) |
| `.claude/prompts/integrator.md` | The integrator's adversarial-auditor stance |
| `.claude/settings.json` | Enables the marketplace and the plugin for the project |
| `docs/{phases,decisions,plan-reviews}/` | Plan, ADRs and plan reviews |

## Configuration

| What | How |
|------|-----|
| Checks | Edit `scripts/check.sh` (formatters in check mode: it runs in the main worktree) |
| Per-worktree setup | Optional `scripts/worktree-setup.sh <branch>`: install deps, create a private test DB… |
| Integrator state reset | Optional `scripts/verify-reset.sh`: recreate shared test state before each verification |
| Mute notifications | `CLAUDE_NOTIFY_SOUND=0` and/or `CLAUDE_NOTIFY_BELL=0` |

## Requirements

`git`, `bash`, `jq`, `python3` (3.9+) and the GitHub CLI `gh` (for PRs). On Windows, Claude
Code runs hooks in Git Bash. Sounds use `afplay` (macOS), `paplay`/`aplay`/`canberra-gtk-play`
(Linux) or `powershell.exe` (Windows, WSL).

## Limitations

- The guards are **guardrails, not a sandbox**. They parse commands with `shlex`, and a
  deliberately creative command can get past them. They fail open: if `python3` or `jq` is
  missing, or the hook errors, the command is allowed.
- The integrator is recognised only by `CLAUDE_ROLE=integrator`.
- `verify-merge.sh` is only as strong as your `scripts/check.sh`.

## Development

```bash
tests/test-hooks.sh                 # hook + installer smoke tests
claude plugin validate plugin && claude plugin validate .
```

`plugin/skills/security-audit/` is a verbatim copy of `skills/security-audit/` from
[cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill), plus its
`LICENSE`, at the commit recorded in `.github/security-audit-skill.ref`. Do not edit it here.
Until the repository was archived, `.github/workflows/update-security-audit.yml` ran
`.github/scripts/update-security-audit.sh` every Monday: it moved the copy to the newest
upstream commit that was at least 7 days old, like Dependabot's cooldown, and opened a pull
request with the upstream compare link. Workflows do not run in an archived repository, so
the copy now stays at the recorded commit and gets no upstream fixes. In a fork, review that
diff before merging, since the skill's text becomes instructions for every agent that loads
it. The script also works locally
(`COOLDOWN_DAYS=0 .github/scripts/update-security-audit.sh` takes the newest commit). CI runs
the skill's two validators' tests (`node plugin/skills/security-audit/validate-*.test.cjs`).

## License

[MIT](LICENSE)
