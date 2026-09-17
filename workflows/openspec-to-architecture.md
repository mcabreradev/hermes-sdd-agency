# Workflow: openspec-to-architecture

Translates a validated OpenSpec change into recorded technical decisions, inside the
project. It closes the gap between "what it must do" and "how it is built, without deciding in the
code".

- **Agents:** `architect`
- **Rules:** `rules/openspec.md`, `rules/coding.md`, `rules/quality.md`
- **Output:** the change's `design.md` and/or architecture docs + ADRs in the project.
- **Personas/method:** `code-architect` + `architect-reviewer` · `architecture-decision-records` when recording each ADR.

## 0. Preflight (Hermes)

```bash
cd <project-root>
test -f openspec/project.md || echo "MISSING project.md → initialize-project (blocking)"
openspec context --json                                 # root.path == <project-root>
openspec status --change "<name>" --json
openspec validate "<name>" --type change --json
```

- Without `ERROR` in validate. Without this, go back to `idea-to-openspec`.
- Read the change before delegating: proposal, specs, tasks. The architect's brief is built
  with that + the real state of the relevant code.

## 1. Design (`architect` agent)

Self-contained brief: project root, change name, artifact paths, paths of the
code to be touched, Done criterion and what NOT to do (do not write product code).

The agent produces, at minimum:

- **Boundaries:** which modules/files are touched, which are NOT, and why.
- **Contracts:** interfaces, types, data format, error policy; what is verifiable
  by the reviewer.
- **Discarded alternatives:** at least one, with the concrete reason.
- **Compatibility/migration:** what breaks and how it is handled.
- **Risks** with mitigation.
- **Location of each requirement:** requirement → module/contract. A requirement without a location is
  incomplete design.

It is written into the project: `openspec/changes/<name>/design.md` (structure from
`templates/architecture.md`) and one ADR per lasting decision (`templates/adr.md`).

## 2. Design validation (Hermes)

- [ ] Every requirement of the delta has a technical location.
- [ ] Every decision has a reason + a discarded alternative; the lasting ones have an ADR.
- [ ] There are no new dependencies without justification.
- [ ] There are no open decisions that force the planner to decide.
- [ ] The design respects `rules/coding.md` (no speculative abstractions or flags without a
      consumer).

Loop: maximum 3 iterations with the exact defect. If after the third it remains open:
- if the problem is the spec's (contradiction, unachievable requirement) ⇒ go back to
  `idea-to-openspec` with the finding;
- if it is the scope's/product's ⇒ escalate to the user with the concrete decision that is missing.

## 3. Consistency with OpenSpec

If the design forces the spec to change (a requirement is not achievable as written),
**the spec is not edited from here**: it is reported and the change goes back to `openspec-update-change`.
The design cannot silently contradict the spec.

## Output

Report (`templates/final-report.md`): decisions made (summary + paths), ADRs created,
risks, and next step (`plan-change`).

## Typical errors

- Designing over an unvalidated spec.
- A design that "resolves" requirements by changing their meaning.
- Deciding libraries/dependencies without an ADR.
- Over-designing (abstractions for hypothetical future needs): prohibited by
  `rules/coding.md`.
