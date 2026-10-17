#!/usr/bin/env bash
# Verify the working tree of the main worktree (normally a PR merged with --no-commit) before
# the integrator commits the merge. Exit code 0 means every check passed; anything else means
# do not merge. Gate the commit on the exit code, never on grepped output:
#
#   if scripts/verify-merge.sh; then git commit ...; else git merge --abort; fi
#
# Usage:
#   scripts/verify-merge.sh               full verification
#   scripts/verify-merge.sh --reset-only  only reset shared verification state (after
#                                         `git merge --abort`)
#
# Steps, stopping at the first failure:
# 1. scripts/verify-reset.sh, if the project has one: recreate shared state (e.g. the
#    integrator's test database) from scratch, so state left by an earlier, aborted
#    verification cannot break (or fake) this one.
# 2. scripts/worktree-setup.sh, if present: install dependencies the PR may have added.
# 3. scripts/check.sh: lint, formatting, types and tests.
#
# Only for the integrator.
set -euo pipefail

repo_root=$(git rev-parse --path-format=absolute --git-common-dir | xargs dirname)
cd "$repo_root"
[[ "$(git rev-parse --absolute-git-dir)" == "$repo_root/.git" ]] \
    || { echo "run it in the main worktree ($repo_root)" >&2; exit 2; }

step() { echo; echo "==> $*"; }

reset_state() {
    if [[ -x scripts/verify-reset.sh ]]; then
        step "reset verification state"
        scripts/verify-reset.sh
    fi
}

if [[ "${1:-}" == "--reset-only" ]]; then
    reset_state
    exit 0
fi

failed_step="setup"
trap 'status=$?; if [[ $status -ne 0 ]]; then echo; echo "VERIFY FAILED at: $failed_step (exit $status)" >&2; fi' EXIT

failed_step="reset verification state"; reset_state
if [[ -x scripts/worktree-setup.sh ]]; then
    failed_step="worktree setup"; step "$failed_step"; scripts/worktree-setup.sh main
fi
failed_step="checks"; step "$failed_step"; scripts/check.sh

echo
echo "VERIFY OK"
