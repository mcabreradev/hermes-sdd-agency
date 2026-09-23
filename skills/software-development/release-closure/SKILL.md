---
name: release-closure
description: "Use when merging an approved SDD release and cleaning up."
version: 0.1.0
metadata:
  hermes:
    tags: [merge, pr, release, changelog, cleanup, contract, cross-repo]
    related_skills: [git-worktree-isolation, openspec-sdd, hermes-sdd-orchestration]
---

# Release closure — merge, document, clean up

The tail of the SDD loop that the agency skills stop just short of: once the human approves
the OPEN PR(s) and explicitly says to merge, someone must merge them, keep cross-repo
generated contracts in sync, write the changelog, and clean every worktree. This skill is
that closing sequence.

## Standing user preferences (always)

- **PRs are OPEN, never draft.** This user's standing rule: a finished change is opened as an
  ordinary OPEN PR awaiting review, not a draft. If a flow auto-created a draft (e.g. the SDD
  terminal state), run `gh pr ready <n>` to publish it and verify `isDraft:false` before
  handing it over. Do not create PRs with `--draft` for this user.

- **Merge only on explicit approval.** A merge is a state change the user owns. "Encárgate del
  PR / mergea" is approval; a bare request to "work on the PR" is not — for a PR that did not
  pass the reviewer/QA loop, ask or run the loop first rather than merging on CI green alone.

- **All documentation, changelog, status/INDEX docs and ADR text are in English.** Code,
specs, commits and docs in English; conversation with the user stays in Spanish. There is no
"Spanish changelog" exception for a project whose docs are English.
- **A changelog entry is a SHORT, attractive, direct summary — not an exhaustive replay.** A
  few bullets of what changed and why, grouped by effect (Added / Changed / Fixed), with the
  concrete names/endpoints. Do NOT dump every file, task id, or internal detail. The changelog
  is for a human scanning what shipped, not a log of the work. A verbose entry is wrong, not
  the changelog itself.

## Procedure

1. **Confirm the PR is mergeable before merging.** `gh pr checks <n>` must be all pass AND
   `gh pr view <n> --json mergeStateStatus` must be `CLEAN` (not `UNSTABLE`). A `CLEAN` while
   checks still run can flip to `UNSTABLE`; wait for the rollup to settle.

2. **Merge with squash.** `gh pr merge <n> --squash --delete-branch`. Then ALWAYS verify the
   merge actually landed — it can succeed even when the branch-delete step errors (see Pitfall
   "gh pr merge from a worktree").

3. **Fast-forward local `main`.** `git fetch origin main -q && git merge --ff-only origin/main`.
   The new commit must be an ancestor of HEAD; never proceed on the memory of a merge that
   GitHub reports — confirm in the tree.

4. **Update the changelog (and status/INDEX docs) for the shipped work.** English, concise,
   top entry, group by effect. Commit and push on `main`. `docs/STATUS.md`-style capability
   lines that already describe the behavior need no change when the merge is consistent with
   them.

5. **Sync the cross-repo generated contract (if any) and regenerate downstream.** When the
   frontend derives types from the backend's `openapi.json`, regenerate against the MERGED
   backend, not the draft branch: ff backend `main`, confirm the new endpoints are present,
   point the frontend's `../tga-backend` path at the backend checkout, run the frontend's
   `generate:types`, and check the diff. See `references/cross-repo-generated-contract.md`.

6. **Clean up after the merge.** In order: delete the remote branch (it may have survived),
   remove the worktree, delete the local branch (only if merged), prune, then remove the empty
   sibling `-worktrees/<repo>/` directory (it can hold stray symlinks). Verify `git worktree
   list` shows only `main` and both repos are clean.

## Pitfalls

- **`gh pr merge` from inside a worktree cwd** can error on the branch-delete step ("main is
  already used by worktree"/"failed to run git") while the merge itself succeeds. Always
  verify `state: MERGED` separately, then delete the remote branch + worktree + local branch
  by hand. Do not re-run the merge or assume it failed.
- **`gh pr edit --body` with a nested-quote heredoc breaks** ("unexpected EOF"). Write the body
  to a temp file and use `--body-file <path>` — the heredoc-with-quotes form is fragile with
  backticks and apostrophes.
- **A frontend worktree branched from old main keeps stale generated types** after the backend
  merges elsewhere. ff the backend, then regenerate (or point the frontend's `../tga-backend`
  at the backend checkout) before building against the new contract.
- **A leftover sibling `-worktrees/` dir survives `git worktree remove`.** Remove the empty dir
  too, or a `../<backend>`-style symlink keeps pointing at a repo whose worktree is gone.
- **Gate honesty does not stop at the merge.** Re-run the repo's own gate and quote the exit
  code; a "passed" claim without the command output is a self-report. When the repo-wide test
  flake is environmental (pino thread-stream), prove it once on the base commit and run the
  touched suites in isolation — then say plainly which is the real result.

## Pitfalls: stacked PRs and the publish channel

- **A PR whose base branch is another PR dies when that base merges.** When PR B is based on
  PR A and A is squash-merged, GitHub deletes A's branch; B's mergeable status flips to
  CONFLICTING/UNKNOWN even when its content has zero conflicts against `main`. Before
  blaming conflict markers, check `gh pr view <n> --json baseRefName` — if the base is a
  branch that was just deleted, rebase B onto `main` and force-push instead of trusting the
  GitHub CONFLICTING badge. Re-confirm by real merge-tree
  (`git merge-tree $(git rev-parse main) $(git rev-parse HEAD)` — 0 conflict markers is a
  clean merge regardless of what GitHub's badge says).
- **`gh pr merge --squash` on such a PR can silently CLOSE it without merging** (state
  CLOSED, mergedAt null, "not mergeable: merge commit cannot be cleanly created"). Once it
  is closed, GitHub won't let you change the base branch of a closed PR — create a fresh PR
  from the same head branch against `main` and close the dead one. Verify the diff of the
  re-created PR is exactly the intended change (`git diff origin/main..<branch> --stat`)
  before merging.
- **Open a stacked PR's base as its PARENT branch, not `main`.** When work is cut into
  branches `f0`→`f1`→`f2` in a chain (each from the previous on shared history), a PR against
  `main` shows every ancestor's diff, not just this branch's — the reviewer re-reads F0 to
  review F3. Target the direct parent (`gh pr create --base f0 --head f1`; `f0` still targets
  `main`) so the diff is only that branch's commits, and merge in chain order. A PR already
  created against `main` for the chain can be re-based with `gh pr edit --base <parent>`.
  Confirm lineage first with `git merge-base --is-ancestor agent/fN agent/fN+1`.
- **A PR body/title written for the phase you started can go stale as the branch grows.**
  When later phases land on the same head branch, refresh title and body to cover the full
  scope before it is reviewed — `gh pr edit --title ... --body-file <path>`. The body is what
  the reviewer reads; a body that only documents F3 on a PR that now carries F3–F6 is a
  misleading review handoff.
- **Only archive/sync an OpenSpec change once every task is closed.** The archive merges
  delta specs into `main` and must be the last spec-consistency act; if release-blocking
  tasks (frontend type regen, cross-repo contract) are still open, keep the change
  in-progress and push the working branch as an OPEN PR instead of archiving partial work.
- **An npm-publish workflow triggered on PR-merged publishes for every merge, and its own
  version-bump step re-bumps.** Docs/refactor merges trigger a publish attempt of an already-
  released version and fail — expected, not a code defect. To ship deliberately, bump in a
  dedicated PR and merge it. Full playbook in `references/npm-publish-ci.md` (npm 2FA/EOTP,
  E404 token scope, verification over the raw registry, pnpm frozen-lockfile override
  mismatch).

## Verification (all four)

- `gh pr view <n> --json state,mergedAt` shows MERGED for every shipped PR.
- `git rev-parse main origin/main` are identical in each repo.
- `git status --porcelain` clean in every repo.
- `git worktree list` shows only the main checkout everywhere (no stray worktrees).

References: `references/cross-repo-generated-contract.md`, `references/npm-publish-ci.md`.
