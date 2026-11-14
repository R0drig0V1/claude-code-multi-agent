# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Weekly `update-security-audit.yml` workflow and `.github/scripts/update-security-audit.sh`:
  move the vendored security-audit skill to the newest upstream commit at least 7 days old and
  open a pull request for review, Dependabot style. The pinned commit is in
  `.github/security-audit-skill.ref`. CI accepts `workflow_dispatch` so the update job can
  start it on its branch (pull requests opened with `GITHUB_TOKEN` trigger no workflows).
- Skill `security-audit`: Cloudflare's security-audit skill
  ([cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill),
  MIT) vendored unchanged from commit `c1c8a8c`, with its `LICENSE`. Security guidance by
  default; a full audit (reconnaissance, coverage-led hunting, adversarial validation,
  `findings.json`, independent verification, reports) when asked for one. CI runs its
  validators' tests.

### Security
- `ci.yml`: `actions/checkout` pinned by commit SHA (v7.0.1), `persist-credentials: false`,
  least-privilege `permissions: contents: read` and a concurrency group (zizmor
  `unpinned-uses`, `artipacked` and `excessive-permissions`).
- `.github/dependabot.yml`: monthly, grouped updates of the pinned actions with a 7-day
  cooldown.

## [0.1.0] - 2026-10-17

### Added
- `multi-agent` Claude Code plugin, published through the `claude-code-multi-agent`
  marketplace in this repository.
- Skills: `worktree`, `commit`, `pr`, `integrate`, `document`, `improve-plan`.
- Agents: `plan-adversary`, `code-reviewer`.
- Guard hooks that keep the main worktree and `main` integrator-only, active only in
  projects that enable the plugin.
- Cross-platform `notify.sh` (sound + terminal bell) for Stop and Notification events.
- `new-worktree.sh` and `verify-merge.sh` workflow scripts.
- `install.sh`, which copies the project-owned template files without overwriting and
  enables the plugin in `.claude/settings.json`.
- Hook and installer smoke tests, and CI.

[0.1.0]: https://github.com/R0drig0V1/claude-code-multi-agent/releases/tag/v0.1.0
