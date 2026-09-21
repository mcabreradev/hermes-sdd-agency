# Workflow: autonomous-change (AUTONOMOUS MODE)

Runs the full SDD loop end-to-end with as little human input as possible, then
hands the user a PR to review and merge. It is the `/do` bundle's workflow.

Read `rules/orchestration.md` first; the mandatory envelope, verification and
role rules all still apply. This workflow is an **override on top of them**: it
relaxes the "ask the human" rules (§Mandatory human approval) for routine
decisions, but **does not relax** role separation, verification in the repo, the
no-code-before-validated-change gate, or "agents never talk to each other".

- **Agents:** discovery · openspec · architect · planner · builder · reviewer ·
  qa · release (one per stage, loaded stage by stage — never all at once)
- **Rules:** `rules/orchestration.md`, `rules/openspec.md`, `rules/sdd.md`,
  `rules/testing.md`, `rules/quality.md`
- **Output:** code + tests for the change, archived + synced, a PR (draft) for
  human review, and `templates/final-report.md` in the project.
- **Terminal state:** the PR is the deliverable. The human reviews and merges.
  Never publish, never tag, never merge.

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
  `workflows/initialize-project.md` first (it is the only human-input step this
  mode allows, and it is allowed). That initialization is the one place the
  human answers business/architecture questions up front.
- The user invoked `do` with an idea. Everything after this point in this
  workflow is the confidence gate: routine → run, non-trivial → wait.

## 1. Idea → validated OpenSpec change (discovery + openspec)

Follow `workflows/idea-to-openspec.md` but without the human approval pause for
routine scope. The discovery agent narrows the idea; the openspec agent writes
the change.

- **Routine:** scope is made explicit ("change X does Y for Z"), requirements
  get ≥1 scenario, `validate` passes. Do not ask how to name it or what "about"
  scope means — pick the minimal faithful reading and record it as a decision.
- **Non-trivial (STOP):** if the idea is ambiguous in a way that changes visible
  behaviour, or the scope genuinely cannot be stated without a business
  decision, stop and ask the human (options + recommendation + impact).

## 2. Confidence-gate triage (Hermes) — the core difference

After the validated change, Hermes decides per stage which track to take. This
is decided from the spec/design, not by trusting an agent.

| Signal in the change | Track |
|---|---|
| New public API/contract, schema/data-model change, security (auth/secrets/exposure), cost-heavy-to-revert architecture, ambiguous business rule that changes user-visible behaviour | **WATCHFUL** → stage runs, but on the first non-trivial decision it stops and waits |
| Everything else — routine feature, bounded behavior, follows existing stack | **AUTONOMOUS** → run with defaults |

The default track is **AUTONOMOUS**. "Routine sleeps, non-trivial wakes."

## 3. Per-stage loop (one agent per stage via `delegate_task`)

Independent stages run in parallel; dependent ones wait for Hermes to verify
the previous output first (`git status --porcelain`, `git diff --stat`, re-run
the gate — an agent reply is a self-report, never a fact).

1. **architect** → design + ADRs for the decisions that appear
   (`workflows/openspec-to-architecture.md`).
2. **planner** → task breakdown (`workflows/plan-change.md`).
3. **builder** → write code + tests in bounded batches (`workflows/implement-change.md`).
4. **reviewer** → adversarial review of the diff (`workflows/review-change.md`).
5. **builder** → fix reviewer findings, max 3 cycles.
6. **qa** → real execution of the scenarios (`workflows/qa-change.md`).
7. **builder** → fix QA findings, max 3 cycles.
8. **release** → close: archive the change + sync specs, final report
   (`workflows/release-change.md`), then the PR.

### Decision defaults (AUTONOMOUS track)

When a routine stage would normally "ask the human":

- **Architecture (routine):** follow the project's existing stack/patterns
  (`AGENTS.md`, tech stack, existing code). Path of least resistance; no new
  non-standard dependency.
- **Business (routine):** if the idea does not state a business rule, implement
  the minimal behavior and mark **"ASSUMED — verify in PR"** in the report +
  ADR. Never invent a rule.
- **Scope (routine):** never expand. New scope → cut it off and record it
  (another change).

### When it STOPS (WATCHFUL track, or anything non-trivial in AUTONOMOUS)

Stop that stage, report the decision with **options + a recommendation +
impact**, and wait for the human. Do not assume it. Examples: high cost to
revert, a public contract/API, schema/data-model change, security
(auth/secrets/exposure), an ambiguous business rule that changes visible
behaviour, splitting the feature, accepting structural debt, a new dependency
that is not standard for the stack.

Every decision actually taken is recorded as an ADR in the project
(`docs/adr/`) and listed in the final report — the user sees them in the PR and
can correct silently.

## 4. Escalation cutoffs (same as the base system)

- Max 5 builder iterations per task, 3 builder↔reviewer cycles, 3
  builder↔qa cycles. Retrying requires new information (exact defect:
  command, output, `path:line`); repeating the same brief is forbidden.
- Two failures with the same error ⇒ the spec or design is wrong: go back a
  stage, not in circles.
- A `BLOCKER`/`MAJOR` still open after its cutoff, or a `qa: fail` persisted,
  is escalated to the human with the concrete defect and both positions — even
  in autonomous mode, a stuck quality wall wakes the user.

## 5. Closure and PR

With review approved + QA pass + everything committed:

1. Write the final report (`templates/final-report.md`) in the project, with
   the **Decisions made** section listing every ADR/ASSUMED.
2. Open the PR (draft) against the default branch: the change, the spec, the
   ADRs, the decision list, and everything flagged ASSUMED. Title/body English.
3. **Post-open quality gate (mandatory):** once the PR is open and CI is green,
   run `workflows/pr-review.md` — a domain-experienced reviewer
   (backend/frontend persona by the diff) reviews the published PR and the
   builder↔reviewer loop drives it to `approved` (max 3 cycles). Fixes go on
   the PR's own branch; the PR is left open, approved, CI green.
4. Never merge, never publish, never tag. The PR awaits the human.

## Output

Final report in the project + PR (draft). The report: closed stages with
evidence, artifacts and paths, gates run, OpenSpec status, ASSUMED decisions to
verify, declared debt, and a single next step (the PR).

## Typical errors

- Letting `do` assume a non-trivial security/architecture/contract decision —
  this is the one failure this mode must never make.
- The builder fixing the reviewer's findings (role separation still holds).
- Closing without archiving + syncing the change (never optional).
- Accepting an agent's self-report without re-verifying in the repo.
- Publishing/tagging/merging: autonomous mode still ends in the PR.
