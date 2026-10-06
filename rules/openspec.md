# Rule: OpenSpec

The system's gate: without a spec there is no code. These rules do not admit exceptions
"because it is small" or "because it is urgent".

## Hard rule

**No implementation code is written before an OpenSpec change exists in the
project and is validated.** It applies to features, fixes, refactors and configuration
changes. Before that, only the following are allowed: exploration, writing the change and
reading the existing code.

**A validated change is a necessary condition, never a sufficient one: the project's declared
phase must also permit implementation.** A change being complete, `apply-ready` and validated is
not an authorization to write code — that is the failure this rule already failed to prevent once.
A project declares its phase in `openspec/project.md` (`## Phase`) and `bin/phase-gate` derives
the verdict from the resulting tree: in a **documentation** phase, application code paths SHALL be
absent, and a change that introduces them is refused however valid it is. The phase is the
human's to open; an agent SHALL NOT set or change it to unblock its own work. A missing or
unrecognized declaration is `cannot assess` (exit 2), never a pass.

Mandatory order:

```
explore → propose → validate → apply → verify → archive
```

## Task size and fast path

Three levels, decided by Hermes (never by the agent), to keep strictness where it
protects without turning small work into ceremony.

**The phase gate cuts across all three levels and none of them bypasses it.** The fast path is
about which artifacts a change carries, never about whether the project is open for
implementation: a cosmetic edit or a `skip_specs` fix in a documentation-phase project is refused
the same way a feature is.

| Level | Examples | Path |
|---|---|---|
| **Cosmetic — no behavior change** | typo in a user-facing message, indentation, renaming a local variable | Direct change to the task, **no OpenSpec change**. Nothing verifiable at spec level. |
| **Minimal — bounded, with behavior** | bug fix with its regression test, changing a visible error message, reordering an endpoint | **OpenSpec change with `skip_specs: true`** — proposal + task, fix, regression test that fails without the fix, review, archive. |
| **Feature — business rules / contract / architecture** | new functionality, changing a contract, an architectural decision | **Full loop** with delta spec, personas, formal QA. |

Invariants on the fast path:

- **A "minimal" change is never an excuse to skip the OpenSpec change when there is
  behavior involved.** The change exists, is validated, applied and archived; only the
  requirement deltas are skipped. `skip_specs: true` covers refactors, low-risk fixes
  and behavior-bounded changes — it is never a shortcut around evidence or verification.
- **A one-line fix always carries its regression test** (`rules/testing.md`: a test that
  passes before and after proves nothing).
- **"It is small" cannot silence verification.** The classification belongs to Hermes,
  which consults the human if unsure; a level boundary is never self-assigned by the agent.
- The cosmetic level is not "a code task": it changes nothing about behavior, so it does
  not enter the loop. Anything that touches observable behavior goes through *minimal*
  or *feature*, never straight to the tree.

## Preflight (before apply)

```bash
cd <project-root>
openspec context --json                                  # resolved root
openspec list --json                                     # active changes
openspec status --change "<name>" --json                 # artifacts, applyRequires
openspec instructions apply --change "<name>" --json     # state, tasks, contextFiles
openspec validate "<name>" --type change --json          # must pass
```

Enabling criterion for implementing (all):

- [ ] The project's declared phase permits implementation: `bin/phase-gate` exits 0 (see "Hard rule").
- [ ] In a **documentation** phase, the project's PRD exists at `docs/PRD.md` and is not `Pending`
      (`test -f docs/PRD.md && ! grep -qiE '^Pending' docs/PRD.md`): a documentation phase does not
      open with its product document missing (`project-docs`; `rules/project-boundaries.md` "Hard
      rules" #12). The PRD's home and producer are declarations, not suggestions — where the check
      runs, it runs as this preflight line, never as an invented bin.
- [ ] `openspec/changes/<name>/` exists, created by the CLI (`openspec new change`), never by hand.
- [ ] `applyRequires` complete (`tasks` as a minimum).
- [ ] `validate` passes without `ERROR`. The `ℹ [INFO]` are read, not ignored.
- [ ] `state` of `instructions apply` is `ready` (not `blocked`).

If something fails ⇒ go back to `workflows/openspec-to-architecture.md` or ask the
user for a decision. The change is not "fixed" by hand to pass the preflight.

## Artifact authoring

Write each artifact in the `resolvedOutputPath` returned by
`openspec instructions <artifact> --change "<name>" --json`, with the `template` as
structure. The `context` and `rules` of the instruction JSON are **constraints, not
content to copy**. Hermes' reusable templates are in
`~/.hermes/templates/`; the CLI's official ones are the reference for valid structure.

Details verified on this machine (v1.13.0):

- `design.md` is conditional: it is omitted when there are no real decisions to record.
- `specs` is omitted only with `skip_specs: true` in `openspec/changes/<name>/.openspec.yaml`,
  never by one's own judgment. `validate` rejects a change without deltas and without that marker.
- `openspec new change` creates the change **even if there is no root, in the cwd**: verify the
  root beforehand (see `rules/project-boundaries.md`).
- `validate` with no arguments validates nothing ("Nothing to validate") and exits 1. Use
  `openspec validate --all`, `--changes`, `--specs`, `--archived` or the change name.
- `validate` exits **1 when something fails** (verified in v1.13.0: invalid change ⇒ exit 1;
  everything valid ⇒ exit 0). The useful verdict is still in the JSON
  (`summary.totals.failed`, `items[].issues[].level`): the `WARNING`s do not change the exit
  code, and the archiving notices appear as `ℹ [INFO]` inside a valid change.
- `--all` and `--changes` cover only **active** changes plus specs; archived ones are validated
  with `--archived` (that option crosses the archived ones against the main specs).
- Do not validate an archived change by passing its name positionally
  (`validate "2026-09-13-<name>" --type change`): it resolves the archive directory and
  reports "No deltas found" as a false ERROR. For archived ones, `--archived`.
- `--store <id>` fixes a registered standalone OpenSpec root; it is sticky per session.
  In this system it is not used: OpenSpec lives in each project's repo.
- `openspec list` does not show specs; for that, `openspec list --specs --json`.

## Prohibited inside the loop

- Creating `openspec/changes/<name>/` with `mkdir`/`write_file`: the CLI scaffold writes
  `.openspec.yaml` and other required metadata.
- Marking `- [x]` in `tasks.md` without the specified behavior being implemented
  and verified. If something remains partial, the task stays `- [ ]` and the reason is stated.
- Expanding or cutting the change's scope by the agent's decision: if new scope
  appears, stop and propose another change.
- Editing `openspec/specs/<cap>/spec.md` (main specs) inside a change: the
  main specs are updated on archiving (inline sync), not before.
- Archiving with a sync in flight, or archiving without `validate --archived` passing.

## Known traps (verified)

- A main spec whose first line is a delta header (`## ADDED Requirements`) is left
  inert: `validate --specs` flags it with `ERROR` (missing `## Purpose`/`## Requirements`),
  `openspec list --specs --json` shows it with `requirementCount: 0`, and `archive` rejects
  any change that modifies it with "target spec is structurally invalid" (and announces it
  beforehand, as `ℹ [INFO]` in the change's validate). Detect:

  ```bash
  grep -rl "^## ADDED Requirements" openspec/specs/*/spec.md
  openspec validate --specs --json | jq -c '.items[]|select(.valid==false)|.id'
  ```

  Fix: replace the delta header with `## Purpose` + `## Requirements`.
- A change's `validate` can pass (only `WARNING` + `INFO`) and the archive can still
  reject it: the exact reason comes in the `ℹ [INFO] ... Archive would refuse this delta`.
  Verified: `openspec archive` aborts without touching files (`Aborted. No files were
  changed.`). Read the INFO before promising that a change is archivable.
- `skip_specs: true` in `.openspec.yaml` allows validating a change without deltas, and exits with
  `INFO` — it is the legitimate path for refactors/tooling/docs, not a shortcut to avoid writing
  scenarios.
- `## MODIFIED Requirements` on a requirement that **does not exist** in the target spec is
  invalid: `## ADDED Requirements` is the right one.
- When archiving a change that CREATES a capability, the new spec is left with
  `Purpose: TBD - created by archiving change <name>`; write the real Purpose
  immediately afterwards. Verified in v1.13.0: if the **delta** includes `## Purpose`, the
  archiving preserves it and there is nothing to correct — writing the Purpose in the delta is the
  preferred path.

## Contract with the rest of the system

- `rules/orchestration.md` governs who can touch these commands (only Hermes and the
  openspec stage's agent).
- `rules/sdd.md` defines when the full agency loop runs (vs this fast path) and the
  language contract.
- `rules/quality.md` defines the format of the outputs that prove that `validate`
  passed (command + output, not claims).
- The workflow `workflows/implement-change.md` does not start if the preflight of this
  file is not satisfied.
