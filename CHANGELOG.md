# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

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
