# Template: proposal.md (OpenSpec change)

Structure aligned with `openspec instructions proposal --change "<name>" --json`.
The CLI's `template` is the validity reference; this template adds how to fill it in.

Write to the `resolvedOutputPath` returned by the CLI.

---

```markdown
## Why

<!-- The problem and its current cost. Why now and not later. No filler. -->

## What Changes

<!-- What changes in the system's behavior, in observable terms.
     Specific: new capabilities, modifications, removals. -->

## Capabilities

### New Capabilities

- `<capability-path>`: <what this capability covers>

### Modified Capabilities

- `<existing-capability-path>`: <what requirement changes and in what sense>

## Impact

<!-- Code, APIs, dependencies, data, affected systems. What breaks, if anything. -->
```

## Filling rules

- **Why:** the real problem, not the solution. If you cannot say what is lost today
  without the change, the change is not justified.
- **What Changes:** observable behavior (what the user/system will be able to do that it
  cannot today). No module or class names.
- **Capabilities:** use the existing path when modifying (`openspec list --specs
  --json`); new paths in kebab-case following the project's spec organization.
  Modified capability ⇔ the requirement changes, not just the implementation (that is a
  refactor).
- **Impact:** list real systems of the project; if unknown, it is a gap that goes to
  discovery/architect, not a generic sentence.
- **No deltas:** pure refactor/tooling/docs ⇒ `skip_specs: true` in `.openspec.yaml`
  (a requirement is not invented to satisfy `validate`).
- **One change = one purpose.** Two problems ⇒ two changes.
- `propose` authorizes planning only: once the artifacts are done, it stops and is
  validated.
