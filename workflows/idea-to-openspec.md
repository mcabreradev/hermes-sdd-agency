# Workflow: idea-to-openspec

Turns a user idea into a valid and archivable OpenSpec change, **inside the
project**. It is the entry gate: until this workflow closes, no code is written.

- **Agents:** `discovery` (if context is needed) → `openspec`
- **Rules:** `rules/openspec.md`, `rules/project-boundaries.md`, `rules/quality.md`
- **Output:** `openspec/changes/<name>/` with proposal + specs + design + tasks, `validate`
- **Personas/method:** `sdd-spec-writer` + `research-technical-spike` (explore) · `requirements-clarity` if the idea arrives vague · `verification-before-completion` before declaring `validate` passed.
  without `ERROR`.

## 0. Preflight (Hermes)

```bash
cd <project-root>
test -f openspec/project.md || echo "MISSING project.md → initialize-project"
pwd -P
openspec context --json           # root.path must be <project-root> (or initialize-project)
openspec list --json              # active changes (avoid duplicating/contradicting)
openspec list --specs --json      # existing capabilities
```

If `openspec context --json` does not resolve the project root or `openspec/project.md` does not exist,
this workflow does not start: run `workflows/initialize-project.md`
(`rules/project-boundaries.md`).

- If there is already an active change that covers the idea: do not open another one; continue that
  one (`workflows/plan-change.md`).
- The product context and the code are read **from this project**: no sibling repos.

## 1. Explore (think, do not write code)

Skill `openspec-explore` with the `openspec` agent. Objective: narrow down the problem, the value,
the boundaries and the edge cases, without deciding implementation. It may write artifacts within
a confirmed scope; never code.

Gate: the scope is made explicit in one sentence ("change X does Y for Z"), with what
is left out enumerated.

## 2. Propose (artifacts)

Skill `openspec-propose` (or `openspec-new-change` / `openspec-continue-change` /
`openspec-ff-change` if you want it step by step).

```bash
openspec new change "<name>"                                   # NEVER mkdir
openspec status --change "<name>" --json
openspec instructions proposal --change "<name>" --json
openspec instructions specs    --change "<name>" --json
openspec instructions design   --change "<name>" --json        # conditional
openspec instructions tasks    --change "<name>" --json
```

Each artifact is written to its `resolvedOutputPath` with the `template` as structure:

- `proposal.md` — why, what changes, new/modified capabilities, impact.
- `specs/<capability>/spec.md` — requirements with delta headers and **≥1 scenario per
  requirement**. New capability ⇒ include `## Purpose` (archiving copies it into the main spec;
  without it a TBD is left).
- `design.md` — only if there are real decisions to record.
- `tasks.md` — breakdown by groups (refined by `planner` in `plan-change.md`).

Hard rules:

- `## MODIFIED Requirements` only over requirements that exist in `openspec/specs/`.
- Change without deltas ⇒ `skip_specs: true` in `.openspec.yaml` (the only legitimate path).
- `propose` authorizes **planning only**: when the artifacts are finished, it stops.

## 3. Validate (the gate)

```bash
openspec validate "<name>" --type change --json
openspec validate --all --json
```

- The exit code is 1 when something fails and 0 when everything validates, but the useful verdict is
  in the JSON (`summary.totals`, `items[].issues[].level`): WARNINGs do not change the exit.
- The `ℹ [INFO]` (for example "Archive would refuse this delta") are reported.
- Loop: max. 2 iterations with the same agent; each iteration with the exact ERROR. If the
  second one still fails, it is escalated to the user or it goes back to explore (the problem is one of
  scope, not of wording).

## 4. Closure (Hermes)

- [ ] `validate` without `ERROR`.
- [ ] Every requirement with at least one scenario.
- [ ] Artifacts only inside `openspec/changes/<name>/`.
- [ ] No implementation code written during the entire run.

## Trace (if the run is traced)

If the preflight minted a `runId`, append this stage's trace entry to the run log
before closing — schema, `kind`/`status` values and append rules in
`rules/observability.md`:

```bash
printf '%s\n' '{"timestamp":"<UTC ISO-8601>","runId":"<runId>","change":"<name>","stage":"idea-to-openspec","kind":"closed","status":"<envelope status>","filesCreated":[],"filesModified":[],"evidence":"<command + output>","blockers":[],"decisions":[],"nextRecommendedStep":"<next>"}' >> reports/<runId>.jsonl
```

- A blocked/failed closure stays `kind: closed` with the defect and the decision
  needed in `blockers` (`bin/run-trace` surfaces both in the summary).
- The log is gitignored by design (`reports/run-*.jsonl`); verify the append with
  `bin/run-trace --file reports/<runId>.jsonl`.

## Output

Report (`templates/final-report.md`) with: change name, artifacts and paths, `validate`
output, open risks and recommended next step (`openspec-to-architecture`).

## Typical errors

- `validate` "passes" and the archive fails later: read the INFO.
- Creating the change by hand: `.openspec.yaml` and the metadata are missing.
- Requirement without a scenario: `validate` rejects it.
- Mixing two ideas into one change: one change = one purpose; the rest is another change.
