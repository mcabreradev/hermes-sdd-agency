# Workflow: pr-review

Adversarial, domain-experienced review of a **published PR** (open on the
remote, CI green) — the post-open quality gate that runs *after* `review-change`
already passed the pre-merge diff. It picks a reviewer persona by the PR's
dominio (backend / frontend / fullstack), loops until the code is aligned, and
leaves the PR in a mergeable, reviewed state.

- **Agents:** `pr-reviewer` (domain personas: `backend-developer`,
  `fullstack-developer`, `typescript-pro`, `code-reviewer`, `code-simplifier`,
  `security-auditor` as the dominion requires) and `builder` for the fixes.
- **Rules:** `rules/quality.md`, `rules/coding.md`, `rules/testing.md`,
  `rules/orchestration.md`
- **Output:** PR review comments (inline on GitHub) + verdict. It drives the PR
  to `approved` by the loop below; it does not merge.
- **Trigger:** a PR is open, CI is green (all status checks pass), and the work
  is on a branch of the project's repo. Runs after `autonomous-change` / any
  `/*` loop that opened a PR, and on any pre-existing open PR when requested.

## 0. Preflight (Hermes) — blocking

```bash
cd <project-root>
pwd -P
gh pr view <n> --json state,isDraft,mergeable,statusCheckRollup # PR is OPEN, not draft, checks green
git status --porcelain
git remote -v                                   # confirm the remote repo exists
gh pr view <n> --json filesChanged              # files touched → pick the domain personas
```

- Block unless: the PR exists and is `OPEN`; `statusCheckRollup` passes (no
  failing checks); the head branch is not yet merged. A draft PR is pushed
  (`gh pr ready <n>`) first or reviewed as-is per the human's instruction.
- **Domain selection (Hermes):** from `filesChanged` and the change's shape —
  schema/API/service/ORM → `backend-developer` + `code-reviewer`; web/UI/theme/
  components/`tga-frontend` → relevant frontend persona (or `fullstack-developer`
  if the stack spans both); infra/CI/deploy → `code-reviewer` + `security-auditor`.
  When in doubt pick the persona that owns the diff's majority, note the choice
  in the report.

## 1. Review of the published PR (`pr-reviewer` agent)

Brief: repo-root, PR number, the domain personas to load, the diff base
(`origin/main...<head>`), and the criterion: findings are **inline GitHub review
comments** on the PR, each with `severity`, `path:line`, impact and proposed
fix. The agent reviews spec compliance, correctness and edge cases, form, tests,
and data/secret security on the actual published diff — not on a description.

The reviewer **does not** fix code and **does not** merge; it posts findings and
returns a structured verdict.

## 2. Validation of findings (Hermes)

- Every finding is verified in the real code (`gh pr diff <n>` / the worktree)
  before it is acted on; a finding without `path:line` or evidence is discarded
  and re-requested.
- Classification follows `rules/quality.md`: `BLOCKER`/`MAJOR` block;
  `MINOR`/`NIT` are Hermes' call (fix now or declared debt).

## 3. Alignment loop (builder ↔ pr-reviewer)

The loop is the point of this workflow: the PR is driven to alignment, not to
the first plausible verdict.

1. **builder** fixes the findings **on the PR's own branch** (in the project
   worktree for that PR, or a fresh one checked out from the PR head),
   committing thematically and pushing to the same PR head. No scope creep.
2. CI re-runs on the push. **Wait for it to go green** before re-reviewing
   (Hermes polls `statusCheckRollup`).
3. **pr-reviewer** re-reviews the *updated* diff (`origin/main...<new head>`),
   confirming each prior finding CLOSED and surfacing any new one. Fresh
   context each cycle; no reading the previous report as gospel.
4. Repeat until `approved` — max **3 builder↔reviewer cycles** (same cutoff as
   `review-change`). Each cycle returns to the reviewer with the updated diff.

- Retrying requires new information (the concrete defect), exactly like the base
  system; repeating a stale brief is forbidden.
- If after 3 cycles a `BLOCKER`/`MAJOR` remains: escalate to the human with the
  defect and both positions — never keep iterating.
- If the defect reveals the spec/design is wrong: stop the loop and go back to
  `openspec-update-change` / `openspec-to-architecture`.

## 4. Closure

With `approved` and CI green:

```bash
gh pr diff <n> --stat
gh pr view <n> --json statusCheckRollup   # all checks pass
openspec validate "<change>" --type change --json   # if OpenSpec tracks the PR
```

- The PR stays **open**, `approved`, CI green. It is **not** merged by this
  workflow — merging is the human's or the batch-release flow's call.
- Report: the PR url, the domain personas used, findings by severity (open +
  closed), cycles used, declared debt, and the next step.

## Output

Final report (`templates/final-report.md`) in the project + the PR left approved.
Verdict: `approved` | `changes-requested` | `blocked`.

## Typical errors

- Reviewing the PR description instead of the published diff.
- Re-reviewing the same stale head without waiting for CI green on the fix push.
- Iterating to infinity without escalating (3-cycle cutoff).
- The pr-reviewer merging or fixing code itself (breaks role separation).
- Picking the fixer persona without domain match (backend/frontend mismatch).
