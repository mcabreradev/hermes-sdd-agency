# Workflow: resume-change (RESUME MODE)

Continues a change that already has a **validated OpenSpec change**
(proposal/spec/tasks) and runs the pending stages to completion, ending in a PR
(draft) for human review. It is the `/resume` bundle's workflow.

It does **not** start from an idea: there is no discovery or spec stage to run.
It detects where the flow stopped and picks up from the first pending stage. It
reuses the same rules, agents, preflight and verification as the base system,
plus the `autonomous-change` confidence gate.

Read `rules/orchestration.md` first. The mandatory envelope, role separation,
verification-in-repo, and no-code-before-validated-change rules all still apply.

- **Agents:** the pending stages' agents (builder · reviewer · qa · release),
  one per stage, loaded stage by stage — never all at once
- **Rules:** `rules/orchestration.md`, `rules/openspec.md`, `rules/sdd.md`,
  `rules/testing.md`, `rules/quality.md`
- **Output:** code + tests for the change (if pending), archived + synced, the
  existing PR draft updated with code/reports/synced specs, and
  `templates/final-report.md` in the project.
- **Terminal state:** the (updated) PR is the deliverable. The human reviews
  and merges. Never publish, tag, or merge.

## 0. Preflight (Hermes) — blocking

```bash
cd <project-root>
test -f openspec/project.md || echo "MISSING project.md → initialize-project"
pwd -P
openspec context --json                  # root.path must be <project-root>
git status --porcelain
git log --oneline -5
```

- If `openspec/project.md` is missing or the root does not resolve, run
  `workflows/initialize-project.md` first. Do not invent a root.
- `resume` requires an **active change**. If none exists, this is not the right
  workflow — tell the user (`/do` or `/feature` starts one).

## 1. Detect — where did the flow stop? (Hermes, never by assumption)

```bash
openspec list --json                     # the active change(s)
openspec status --change "<name>" --json # artifacts, tasks, applyRequires
openspec validate "<name>" --type change --json  # must be ERROR-free (rules/openspec.md)
openspec instructions apply --change "<name>" --json  # state: ready | all_done
git diff --stat origin/<base>..HEAD      # is there already any implementation?
gh pr list --head <branch> --json number,title  # does a PR draft exist?
```

Read the real output. Determine, in this order:

1. **The change** — its name from `openspec list`, its `validate` verdict and
   task state.
2. **What is already done** — which tasks are `- [x]`, whether
   `design.md`/`tasks.md` exist, whether any code is already committed (`git
   diff`).
3. **Whether a PR draft exists** — if one does, that is the PR to update; never
   open a second one.

From that, resolve the first **pending** stage:

| Already done | First pending stage |
|---|---|
| proposal + spec + tasks; no code | `implement-change` |
| code committed; not reviewed | `review-change` |
| review approved; not QA'd | `qa-change` |
| review + QA green; not closed | `release-change` (archive + sync + finalize PR) |

- **If something earlier looks incomplete or half-signed-off** (e.g. `design.md`
  missing, tasks partially done with no evidence), do not silently skip: record
  it and ask, or go back the appropriate stage via `openspec-update-change` /
  `plan-change`. Never advance past a stage that is not actually closed.

## 2. Confidence-gate triage (Hermes)

Same as `autonomous-change`: read the spec/design and split the pending stages
into tracks.

| Signal in the change | Track |
|---|---|
| New public API/contract, schema/data-model change, security (auth/secrets/exposure), cost-heavy-to-revert architecture, ambiguous business rule changing user-visible behaviour | **WATCHFUL** → runs, but stops and waits on the first non-trivial decision |
| Everything else — routine, bounded, follows the existing stack | **AUTONOMOUS** → run with defaults |

Default is **AUTONOMOUS**. "Routine sleeps, non-trivial wakes."

## 3. Run the pending stages (one agent per stage via `delegate_task`)

Run from the first pending stage through `release-change`, one agent per stage,
independent stages in parallel. Each re-verifies in the repo before the next
advances.

1. **builder** → write code + tests in bounded batches, if pending
   (`workflows/implement-change.md`).
2. **reviewer** → adversarial review of the diff (`workflows/review-change.md`).
3. **builder** → fix reviewer findings, max 3 cycles.
4. **qa** → real execution of the scenarios (`workflows/qa-change.md`).
5. **builder** → fix QA findings, max 3 cycles.
6. **release** → close: archive the change + sync specs, final report
   (`workflows/release-change.md`), then finalize the PR.

### Decision defaults (AUTONOMOUS track)

When a routine stage would normally "ask the human":

- **Architecture (routine):** follow the project's existing stack/patterns
  (`AGENTS.md`, tech stack, existing code). Path of least resistance; no new
  non-standard dependency.
- **Business (routine):** if the spec does not state a business rule, implement
  the minimal behavior and mark **"ASSUMED — verify in PR"**. Never invent a rule.
- **Scope (routine):** never expand. New scope → cut it off and record it
  (another change).

### When it STOPS (WATCHFUL track, or anything non-trivial in AUTONOMOUS)

Stop that stage, report options + recommendation + impact, and wait for the
human. Do not assume. Examples: high cost to revert, public contract/API,
schema/data-model change, security (auth/secrets/exposure), an ambiguous
business rule changing visible behavior, splitting the feature, accepting
structural debt, a non-standard new dependency.

Every decision actually taken is recorded as an ADR in the project
(`docs/adr/`) and listed in the final report — the user sees them in the PR.

## 4. Escalation cutoffs (base system)

- Max 5 builder iterations per task, 3 builder↔reviewer cycles, 3
  builder↔qa cycles. Retry requires new information (exact defect: command,
  output, `path:line`); repeating the same brief is forbidden.
- Two failures with the same error ⇒ spec or design is wrong: go back a stage.
- A `BLOCKER`/`MAJOR` still open after its cutoff, or a persisted `qa: fail`, is
  escalated to the human — a stuck quality wall wakes the user even in resume mode.

## 5. Close and update the PR

With review approved + QA pass + everything committed:

1. Write the final report (`templates/final-report.md`) in the project, with
   the **Decisions made** / ASSUMED section.
2. **Archive the change + sync specs** (`openspec archive <name> --yes`,
   `openspec validate --archived --json`), because the synced specs must go
   into the PR (per `rules/openspec.md` closure). **Update** the existing PR
   draft — never open a second one — with the code, the reports, the ADRs and
   the synced specs. Title/body English.
3. Never merge, never publish, never tag. The PR awaits the human.

## Output

Final report in the project + the updated PR (draft). The report: closed stages
with evidence, the stage it resumed from, gates run, OpenSpec status, ASSUMED
decisions to verify, declared debt, and a single next step (the PR).

## Typical errors

- Assuming `resume` starts a new PR — it detects and updates the existing draft.
- Re-running discovery/spec when they are already validated (there is no idea stage here).
- Skipping a stage that is not actually closed and advancing blindly.
- Letting a routine resume take a non-trivial security/architecture/contract decision.
- Closing without archiving + syncing into the PR.
- Accepting an agent's self-report without re-verifying in the repo.
