# Template: spec.md (change delta)

Structure aligned with `openspec instructions specs --change "<name>" --json`.
It goes in `openspec/changes/<name>/specs/<capability-path>/spec.md`. `openspec/specs/**`
is **never** edited inside a change (the main ones are updated on archive).

---

```markdown
## Purpose

<!-- Only NEW capabilities: one or two sentences (50+ characters) about what it is for.
     Delete this section when modifying an existing capability.
     MANDATORY in new capabilities: archiving copies this Purpose into the main spec.
     Without it, the spec is left with "TBD - created by archiving change" (verified v1.13.0). -->

## ADDED Requirements

### Requirement: <!-- requirement name -->

<!-- The system MUST <observable behavior>. No implementation details. -->

#### Scenario: <!-- scenario name -->

- **WHEN** <!-- condition -->
- **THEN** <!-- expected result -->
```

## Valid delta headers

| Header | When |
|---|---|
| `## ADDED Requirements` | new requirement, or a requirement that does not yet exist in the target spec |
| `## MODIFIED Requirements` | a requirement that **already exists** in `openspec/specs/<cap>/spec.md` and changes |
| `## REMOVED Requirements` | a requirement that ceases to exist |
| `## RENAMED Requirements` | a requirement that changes name |

Verified trap: `MODIFIED` on a requirement that does not exist in the target spec is
invalid — `ADDED` is the correct one. And `validate` can pass while `archive` would reject
the delta: this shows in the `ℹ [INFO]` lines.

## Content rules

- **Every requirement needs at least one `#### Scenario:`** or `validate` rejects it.
- One requirement = one verifiable behavior, in normative language (MUST / MUST), without
  naming functions, files or libraries.
- Scenarios in WHEN/THEN format: the observable condition and the expected result.
  No UI steps, no internal data. Every scenario must be convertible into a test
  (`rules/testing.md`) or a QA case (`agents/qa.md`).
- Quantity: as many requirements as needed, none as filler. A small change with 1
  requirement and 2 scenarios is a healthy change.
- No "and also" outside the scope: something new is another change.

## Self-verification before delivery

- [ ] Every capability listed in `proposal.md` has its `specs/<cap>/spec.md`.
- [ ] Every requirement has ≥1 scenario.
- [ ] `MODIFIED`/`REMOVED`/`RENAMED` only on requirements that exist in the target spec.
- [ ] New capability: `## Purpose` section written.
