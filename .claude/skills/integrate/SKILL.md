---
name: integrate
description: Integrator loop for the multi-agent workflow - take the open pull requests, verify each one against main in the main worktree, merge the green ones, bounce the rest to their authors and keep the plan up to date. Use only in the integrator session (main worktree, CLAUDE_ROLE=integrator), when a development agent announces a PR ("PR #N listo"), or when the user says "integra", "mergea los PRs", "/integrate".
---

# Integrate

You are the **integrator**: the only session allowed in the main worktree (the original
checkout, branch `main`). You do not develop features. You turn finished branches into
`main`, one PR at a time, and keep `main` green. The workflow is described in CLAUDE.md
("Multi-agent workflow").

## 0. Preconditions (stop and tell the user if any fails)

```bash
[[ "$CLAUDE_ROLE" == integrator ]]                     # launched with scripts/integrator.sh
[[ "$(git rev-parse --absolute-git-dir)" == "$(git rev-parse --path-format=absolute --git-common-dir)" ]]   # main worktree
git switch main && git status --short                  # must be empty
gh auth status
git fetch origin --prune && git merge --ff-only origin/main
```

A dirty main worktree means someone broke the rule: do not stash or discard it. Report the
files to the user and stop.

## 1. Queue

GitHub's open PRs are the queue; messages from agents only wake you up. Rebuild it every time:

```bash
gh pr list --base main --state open --json number,title,headRefName,isDraft,createdAt \
  --jq 'sort_by(.createdAt) | .[] | select(.isDraft | not) | "\(.number) \(.headRefName) \(.title)"'
```

Process them **oldest first, one at a time**: each merge changes `main` for the next one.

## 2. Verify one PR

```bash
N=<number>; B=<headRefName>
gh pr view $N --json body,files,commits
git diff --stat origin/main...origin/$B
git diff origin/main...origin/$B          # read all of it
```

Review the diff against the rules in CLAUDE.md: docs updated in the same change, module
docstrings, English code and docs, the project-specific rules. For a large or risky diff, ask
the `code-reviewer` agent for a second opinion.

**Migrations** (if the project has them). Each new migration must chain onto main's latest
one (or the previous new migration of the same PR). Otherwise two branches both wrote the
same number: bounce it, the author renumbers and re-chains onto main's head. Never merge a PR
that creates a second migration head.

**Merge locally and verify the merged result** with `scripts/verify-merge.sh`, never with
hand-typed checks:

```bash
git merge --no-ff --no-commit origin/$B
scripts/verify-merge.sh; echo "verify exit=$?"
```

The script runs `scripts/check.sh` (the project's lint, type and test commands) on the merged
tree and prints `VERIFY OK`, or `VERIFY FAILED at: <step>`.

**The exit code is the verdict.**
- Merge only on exit 0.
- Never decide by grepping output for "passed": a pipeline ending in `grep` succeeds even when
  the tests fail.

Conflicts: resolve them yourself only when they are mechanical (two ticks in the same
`docs/phases/` file, two rows in the same docs table). Anything touching code is a bounce.
If the verification fails, it is also a bounce. A bounce always ends with:

```bash
git merge --abort && scripts/verify-merge.sh --reset-only
```

Put the failing step and its output in the PR comment.

## 3. Merge

Only after `scripts/verify-merge.sh` exited 0 on this exact working tree. If anything changed
since then, such as a resolved conflict, verify again.

```bash
git commit -F - <<'MSG'
Merge pull request #<N> from <B>

<PR title>
MSG
git push origin main
```

Pushing a commit that contains the PR head marks the PR as merged on GitHub. Then delete the
remote branch (`git push origin --delete $B`). Do **not** remove the author's worktree: its
session may still be open; the author or the user removes it.

## 4. Plan

You own `docs/phases/`: development agents list the tasks they completed in the PR body, and
you tick them, update the status line and the roadmap table in `docs/phases/README.md`, then
commit `docs(plan): ...` (use the `commit` skill) and push.

## 5. Report back

To the author, both durable and immediate:

- Merged: `gh pr comment $N --body "Merged into main as <sha>."`
- Bounced: `gh pr comment $N --body "<what failed, the exact command and its output, what to change>"`
  and leave the PR open.

If the PR was announced by a session message, also answer with `SendMessage`, copying its
`from` as `to`: one first line with the verdict ("PR #12 mergeado" / "PR #12 rechazado:
migración duplicada"), then the details. Other open development sessions (`ListAgents`)
should be told that `main` moved when the merge touches files they are likely to share
(migrations, shared models, `CLAUDE.md`, `docs/phases/`), so they rebase before their own PR.

Then go back to step 1 until the queue is empty. When it is empty, stay idle: the next
announcement wakes you. As a fallback for lost messages the user can run
`/loop 30m /integrate`.

## Never

- Develop features or fix an author's code in the main worktree: bounce it.
- Force-push `main`, rewrite its history, or merge with red checks.
- Stash, reset or discard uncommitted changes you did not make.
