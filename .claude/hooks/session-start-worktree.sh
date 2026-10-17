#!/usr/bin/env bash
# SessionStart hook: send development sessions opened in the main worktree to a worktree.
#
# The main worktree (the original checkout, branch main) belongs to the integrator (see
# "Multi-agent workflow" in CLAUDE.md). A session started there without CLAUDE_ROLE=integrator
# gets instructions injected into its context: before changing anything, create a branch and
# worktree with scripts/new-worktree.sh and switch the session into it with EnterWorktree.
#
# Why instructions and not the worktree itself: at startup the task is not known yet, so the
# branch cannot be named. The agent names it from the user's first request. Sessions that
# only answer questions or read code never need a worktree, so none is created up front.
#
# Sessions already in a linked worktree, outside a git repository, or the integrator get
# nothing. The hook never fails the session: any error just skips the instructions.
set -uo pipefail

[[ "${CLAUDE_ROLE:-}" == "integrator" ]] && exit 0

cwd=$(jq -r '.cwd // empty' 2>/dev/null)
[[ -z "$cwd" || ! -d "$cwd" ]] && exit 0

git_dir=$(git -C "$cwd" rev-parse --absolute-git-dir 2>/dev/null) || exit 0
common_dir=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0
[[ "$git_dir" != "$common_dir" ]] && exit 0   # already in a linked worktree

repo_root=$(dirname "$common_dir")
repo_name=$(basename "$repo_root")

read -r -d '' context <<MSG
This session started in the MAIN worktree ($repo_root), which only the integrator may modify
(CLAUDE.md, "Multi-agent workflow"). Project instructions: work in a worktree of your own.

As soon as the user's request needs any change to files, commits or a branch, and before
making it:
1. Name the branch <type>/<short-kebab-name> after the request (type: feat, fix, docs, chore,
   refactor, test), e.g. feat/user-login.
2. Run: $repo_root/scripts/new-worktree.sh <type>/<short-kebab-name>
   It prints "worktree ready: <path>": it creates ../${repo_name}-<short-kebab-name> from
   origin/main with its own branch.
3. Call EnterWorktree with path=<that path> so the session works there. Then edit, test and
   commit only in that worktree, and finish with /pr (it announces the PR to the integrator).
4. Tell the user the branch and worktree you created, in one line.

Questions and reading code need no worktree. Never edit, commit, switch branches or push from
the main worktree: hooks block it.
MSG

jq -n --arg ctx "$context" \
    '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
