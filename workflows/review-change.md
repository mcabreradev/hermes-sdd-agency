# Workflow: review-change

Adversarial review of the builder's work against the spec, the design and the rules. It does not
correct: it decides whether the implementation can move on to QA.

- **Agents:** `reviewer` (and `builder` for the fixes)
- **Rules:** `rules/quality.md`, `rules/coding.md`, `rules/testing.md`, `rules/openspec.md`
- **Output:** review report (`templates/review-report.md`) + verdict.
- **Personas/method:** `code-reviewer` + `code-simplifier` · `code-review-checklist` · `supply-chain-security` if the diff touches dependencies.

## 0. Preflight (Hermes)

```bash
cd <project-root>
test -f openspec/project.md || echo "MISSING project.md → initialize-project (blocking)"
openspec context --json                                 # root.path == <project-root>
git status --porcelain
git diff --stat
openspec instructions apply --change "<name>" --json      # task progress
<agency-bin>/review-snapshot --base <base>                # freeze the candidate BEFORE review
<agency-bin>/review-tier --base <base>                    # depth follows the diff, not judgment
```

- There is a real diff to review and the change's tasks are implemented (or the brief indicates
  reviewing a specific batch).
- Hermes fixes the **base** of the comparison (`<base>` = reference commit/branch) and
  includes it in the brief. Without an explicit base, the review is not reproducible.
- **The candidate is frozen before anything reads it** (`rules/quality.md`, "Frozen review
  candidate"): the snapshot path goes into the reviewer brief, and the reviewer reports the
  snapshot its findings describe. Re-run `--compare` at delivery; a mismatch means the evidence
  belongs to different content.
- **The tier selects the review's depth** (`rules/quality.md`, "Review tier"): `low` runs the
  standard reviewer with structural checks, `medium` adds the `code-review-checklist` sweep,
  `high` adds the domain persona and `security-auditor` when deps or secrets are in scope. The
  tier never blocks and never replaces `pr-review`'s QA gate; an unassessable diff is never
  treated as `low` — proceed at the higher depth or report the blocker.

## 1. Review (`reviewer` agent)

Brief: project root, diff base, OpenSpec change, spec/design paths, repo
rules, the **snapshot path** the findings describe, the **tier** that sets the depth, and the
criterion: findings with `path:line`, severity and impact; without implementing
fixes; without writing to the project except the report.

The agent reviews: spec compliance, diff scope, correctness and edge cases,
form (`rules/coding.md`), tests (`rules/testing.md`), gate re-run by itself,
consistency with `design.md`, data/secret security, and the **sensitive-path deny list**
(`rules/project-boundaries.md`, section "Sensitive paths"): grep the paths of the declared diff
against the list — a match is a `BLOCKER`, an empty result is recorded as the check's evidence
line (command in `rules/quality.md`).

## 2. Validation of the findings (Hermes)

- Hermes verifies each finding in the real code before passing it to the builder. A finding
  without `path:line` or without evidence is discarded and requested again.
- Classification: `BLOCKER`/`MAJOR` block; `MINOR`/`NIT` are decided by Hermes (fix
  now or record as debt in the final report).
- "approved" is not accepted with open `BLOCKER`/`MAJOR`.

## 3. Correction cycle (builder)

If there are blocking findings: brief to the `builder` with **each** finding (file, line,
impact, proposed fix) and the instruction to touch nothing else.

- Max. 3 builder ↔ reviewer cycles. Each cycle returns to the reviewer with the updated diff.
- If after 3 cycles a `BLOCKER` remains open: escalate to the user with the concrete defect
  and both positions (reviewer and builder), without continuing to iterate.
- If the defect reveals that the spec is incorrect: stop the cycle and go back to
  `openspec-update-change` / `openspec-to-architecture`.

## 4. Closure

Verdict in the repo/project and in the report to Hermes. With `approved`:

```bash
openspec validate "<name>" --type change --json
git diff --stat
```

## Trace (if the run is traced)

If the preflight minted a `runId`, append this stage's trace entry to the run log
before closing — schema, `kind`/`status` values and append rules in
`rules/observability.md`:

```bash
printf '%s\n' '{"timestamp":"<UTC ISO-8601>","runId":"<runId>","change":"<name>","stage":"review-change","kind":"closed","status":"<envelope status>","filesCreated":[],"filesModified":[],"evidence":"<command + output>","blockers":[],"decisions":[],"nextRecommendedStep":"<next>"}' >> reports/<runId>.jsonl
```

- A blocked/failed closure stays `kind: closed` with the defect and the decision
  needed in `blockers` (`bin/run-trace` surfaces both in the summary).
- The log is gitignored by design (`reports/run-*.jsonl`); verify the append with
  `bin/run-trace --file reports/<runId>.jsonl`.

## Output

Report (`templates/final-report.md`): verdict, findings by severity (open and
closed), cycles used, declared debt, and next step (`qa-change`).

## Typical errors

- Reviewing the builder's description instead of the diff.
- Accepting the gate "according to the builder" without re-running it.
- Iterating to infinity in the same discussion without escalating.
- A reviewer that fixes the code: it breaks the system's role separation.
