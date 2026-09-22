# Rule: Quality

Quality is verifiability. A stage is closed when there is reproducible evidence,
not when the agent reports that it finished.

## Evidence > claim

- Every agent output must cite **command + real output** (or path + exact fragment)
  that proves what it claims.
- A "ready", "done" or "verified" without evidence is treated as a failure: it goes back to the agent
  with the same brief and the evidence requirement.
- Hermes re-verifies in the real repo before accepting: an agent's output is a
  self-report, not a fact.
- Never fabricate output. If something could not be executed, the blocker is reported as is.

## Content evidence: bind reviews and QA to the tree, not to a claim

A claim that a stage "reviewed" or "tested" the work is a self-report; it proves nothing
unless it is bound to the actual content it was performed on. A working-tree content
fingerprint is that binding.

- `bin/no-smoke-worktree` prints a **content hash of the working tree** (git `write-tree`
  over a temp index with `git add -A`). Same content ⇒ same hash; any change to source —
  including **untracked new files** — changes the hash. It survives rebase/amend/squash
  that preserve content.
- **Reviewer and QA stages must record the fingerprint** they performed their stage on,
  and `release-change` must record the fingerprint of the tree it closes.

```
reviewer fingerprint:  $(cd <project-root> && <agency-bin>/no-smoke-worktree)
qa fingerprint:        $(cd <project-root> && <agency-bin>/no-smoke-worktree)
release fingerprint:   $(cd <project-root> && <agency-bin>/no-smoke-worktree)
```

where `<agency-bin>` is the agency's `bin/` dir as installed (e.g. `~/.hermes/bin`).
`install.sh` copies `bin/` into the target; the fingerprint is taken from inside the
project root so `git rev-parse` finds the right repo.

- At merge time, compare: **if the closed tree's fingerprint differs from the one the
  reviewer/QA reported, the validation was performed on older (or different) content and is
  not proof that the shipped tree was reviewed.** Treat the mismatch as a blocker: re-review
  or re-test before landing.
- The command and its output are the evidence line; the hash alone, without the command that
  produced it, is a bare token and does not count.


## Output formats (contract of each agent)

The mandatory envelope is defined in `rules/orchestration.md` (section "Mandatory output
contract for agents"): it is the single source of truth for the format.

```
status:              done | blocked | failed | needs-context
                     (+ approved | changes-requested in reviewer; pass | fail in qa)
summary:             one line, without narrating the process
projectRoot:         absolute path of the project
filesCreated:        absolute paths created (or [])
filesModified:       absolute paths modified (or [])
blockers:            what prevents finishing + what decision is needed (or [])
nextRecommendedStep: proposed next step (Hermes decides)
evidence:            commands + relevant output; path:line
openQuestions:       doubts that change design, scope or business (or [])
```

- `done` requires evidence for **each** objective of the brief. An objective without evidence
  ⇒ the response is degraded to `blocked`.
- `blocked` and `failed` must name the exact defect: command, output, `path:line`.
- `needs-context` only when the lack of context prevents progress and cannot be resolved
  by reading the repo.
- No field is omitted: without it, the response is invalid and goes back to the agent with the
  same brief and the format requirement.

## Definition of Done by task type

| Task | Done requires |
|---|---|
| discovery | inventory with evidence (paths, commands), without inventing behavior |
| openspec (propose) | `validate` without ERROR + `ℹ INFO` read and reported |
| architect | decisions with discarded alternatives and risks; ADR if applicable |
| planner | granular `tasks.md` (steps of ≤1 day), each task verifiable |
| builder | repo build/lint/tests green + only declared files touched |
| reviewer | findings with `severity`, `path:line`, impact and proposed fix |
| qa | executed cases, real result, failure evidence when it fails |
| release | versioning and notes coherent with the diff; nothing that fails the repo gate |

## Declared diff rule

- The agent declares **beforehand** which files it is going to touch; any file touched outside
  that list is a defect that the reviewer raises.
- No silent collateral changes: no mass reformatting, version bumps or
  "I took the opportunity and fixed it" in the same step.
- The agent's work is verified with the real diff (`git diff`, `git status`), not with
  its description of it.

## Repository gate

Before declaring something finished, the project's real gate is run, read from the repo
(not invented):

```bash
cat package.json | jq '.scripts'          # or Makefile / justfile / pyproject.toml
git diff --stat
```

- If the project declares git hooks (husky, pre-commit), run their equivalent **before**
  committing, do not discover it in the hook.
- A test that passes on retry is flaky: it is reported as a defect, not as green.
- Never declare a gate green that was not run. If the gate cannot be run (environment,
  credentials, time), the report is `blocked` with the reason.

## Agent conduct rules

- Agents do not communicate with each other; every output goes to Hermes with the format above.
- Agents do not modify `~/.hermes/**` (workflows, rules, agents, templates,
  global memory). If they detect that a rule is missing or incorrect, they report it to Hermes
  as a finding; Hermes decides whether to update the global system.
- Agents do not update global memory with project facts: what is specific to the
  project is written in the project.
- **Every report declares the `projectRoot` used in that run.** A report whose
  `projectRoot` does not match the verified root (`openspec context --json` contrasted
  against the expected one, `rules/project-boundaries.md`) is invalid and is returned to the agent.
- Agents do not archive changes nor touch `openspec/specs/` unless the workflow explicitly
  tells them to.

## Severities

```
BLOCKER   prevents the specified functionality from existing or the gate from passing
MAJOR     incorrect behavior or real risk, with a workaround
MINOR     quality, maintainability, consistency
NIT       style preference, does not block
```

`BLOCKER` and `MAJOR` block the stage's progress. `MINOR` and `NIT` are recorded and
Hermes decides (fix now or leave it as declared debt in the final report).

## Sensitive-path check (reviewer)

The deny list of sensitive paths lives in `rules/project-boundaries.md` (section "Sensitive
paths"). It is enforced on the declared diff, not on the author's intent:

```bash
# paths touched by the declared diff
git diff --name-only <base>...HEAD > /tmp/diff-paths.txt
# deny-list grep — the pattern is the machine form of the table in rules/project-boundaries.md
grep -nE '(^|/)\.ssh/|(^|/)\.env[^/]*$|(^|/)secrets/|\.(pem|key|p12|pfx)$|(^|/)\.aws/credentials|(^|/)\.credentials/|(^|/)\.config/gh/hosts\.yml|(^|/)Library/Keychains/' /tmp/diff-paths.txt
```

- **The table and this pattern are one decision in two forms.** Adding a row to the boundaries
  table without extending the pattern (or the reverse) is a defect the reviewer raises: the
  fixture `fixtures/sensitive-paths/check.sh` carries one case per table row, so a row with no
  matching pattern shows up as a failing case.
- **A match is a `BLOCKER`**, recorded with `path:line` of the offending declaration; the stage
  does not advance regardless of what the file appears to contain.
- **An empty result is the evidence line** for this check: record the command and its empty
  output. Do not report "verified" without the command that produced it.
- This check is additive to the other security findings (secrets in code, sensitive logs); it
  does not replace judgment about a sensitive path that is not enumerated.

## Frozen review candidate (snapshot before review)

A review whose findings describe content that moved mid-review is unfalsifiable. The candidate
is therefore frozen **before** anything reads it:

```bash
# in the project root, before the reviewer is dispatched
<agency-bin>/review-snapshot --base <base-ref>            # writes reports/review-snapshot.json
# at delivery, after the fixes, on the tree to be closed
<agency-bin>/review-snapshot --compare reports/review-snapshot.json
```

- **The reviewer and QA briefs cite the snapshot path**, and their report states the snapshot
  they worked against. The snapshot — not the reviewer's memory of what it read — is what the
  findings describe.
- **The comparison is content-based, never commit-based.** It checks the working-tree
  fingerprint **and** the diff hash, and re-verifies the snapshot's own recorded base — so a
  rebase, amend or squash that preserves content still matches and is never blocked, while a
  manifest whose base or diff hash was forged (or whose base no longer resolves) is reported
  as a mismatch or as "cannot assess", never as MATCH. Comparing commit shas would block
  exactly the legitimate rewrites the existing fingerprint rule avoids.
- **A `MISMATCH` is a blocker of the existing fingerprint class**: the evidence belongs to
  different content, so re-review or re-test before closing. The command only reports it —
  what to do next (re-review, revert, re-snapshot) is the orchestrator's and the user's call.
- **The snapshot is never written into the tracked worktree.** Its default path is gitignored,
  and a `--out` inside the repository that is not verifiably ignored is **refused** (exit 2,
  naming the missing entry) — writing it there would change the very content fingerprint it
  records, producing a false `MISMATCH` at delivery with nobody having touched anything.
  `install.sh` does not carry this repo's `.gitignore` into a consuming project, so the tool
  enforces the condition instead of relying on the consumer having copied the entry.

## Review tier (depth follows the diff)

Review depth follows the diff's own shape instead of the reviewer's judgment. The declared
rules are the table below, implemented by `<agency-bin>/review-tier` (default base `main`):

| Tier | When | Review shape |
|---|---|---|
| `low` | only documentation/process paths, no behavior-bearing path | one reviewer, structural checks, no persona fan-out |
| `medium` | behavior-bearing, no high-consequence path, within the size bound | reviewer + `code-review-checklist` sweep |
| `high` | any high-consequence path, or over the size bound | deeper persona set (domain persona + `code-simplifier`, `security-auditor` when deps or secrets are in scope) |

**High-consequence path classes** (any one forces `high`, however few lines):

| Class | Matches |
|---|---|
| `schema-migration` | `*.sql`, migrations dirs, Prisma schema |
| `auth` | auth/login/session/permission/rbac code |
| `security-config` | `.env*`, CORS/helmet/CSRF config, `.npmrc`, `.netrc` |
| `dependency-manifest` | `package.json`, lockfiles, `Cargo.toml`/`go.mod`/`requirements.txt`/`Gemfile`/`pyproject.toml` |

**Size bound:** 400 authored changed lines (additions + deletions) — the same advisory figure
as `rules/coding.md`, applied here as the exact tier boundary: **at or under 400 is `medium`,
over 400 is `high`**. The bound is declared here and hard-coded in the bin; it is deliberately
**not** an environment knob, because a variable that can silently lower a tier would be an
implementation branch with no rule behind it.

- **The tier selects depth and nothing else.** It never blocks a stage, closes a change,
  authorizes a merge, or substitutes for the formal QA gate that `workflows/pr-review.md`
  mandates. Delivery stays human-owned.
- **An unassessable diff is never `low`.** The command reports "cannot assess" and exits
  non-zero when the diff cannot be measured (not a repository, missing git, an unknown base)
  **or when the diff is empty** — a base that equals `HEAD` (work committed onto the base
  branch, or a wrong ref) yields no paths and no lines, which is not evidence that the change
  is documentation-only. The review then proceeds at the higher depth or reports a blocker —
  never on an optimistic default.
- **The tier and its reasons are printed together**, and each rule that fired is named together
  with the paths that produced it, so a reviewer can contradict the tier by pointing at the
  table instead of arguing about judgment. Changing the classes or the bound is a rule change
  here, not a code change in the bin.
