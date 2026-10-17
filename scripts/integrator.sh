#!/usr/bin/env bash
# Launch the integrator session: the only session that may change main and the main worktree
# (see "Multi-agent workflow" in CLAUDE.md).
#
# Usage: scripts/integrator.sh [extra claude arguments]
#
# - Runs in the main worktree whatever directory it is called from.
# - CLAUDE_ROLE=integrator exempts the session from the guard hooks.
# - --name integrador is the address development sessions send "PR #N listo" to.
# - Appends .claude/prompts/integrator.md (the adversarial-auditor stance) to Claude Code's
#   default system prompt. Appended rather than `--agent`, which would replace the default
#   prompt: the integrator keeps the standard tool and git-safety instructions, CLAUDE.md
#   and the project skills (/integrate is its procedure).
set -euo pipefail

repo_root=$(git -C "$(dirname "$0")" rev-parse --path-format=absolute --git-common-dir | xargs dirname)
cd "$repo_root"
CLAUDE_ROLE=integrator exec claude --name integrador \
    --append-system-prompt-file "$repo_root/.claude/prompts/integrator.md" "$@"
