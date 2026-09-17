# Template: design.md / architecture.md

Two uses, same structure:

- `openspec/changes/<name>/design.md` — change design (the CLI asks for it this way and it
  is conditional: it is omitted when there are no real decisions).
- The project's `docs/architecture.md` — current architecture (updated when closing
  changes that modify it).

---

```markdown
## Context

<!-- Current state and constraints that shape the approach. Do NOT repeat the why
     (that is in proposal.md). -->

## Goals / Non-Goals

**Goals:**
<!-- What this design achieves. -->

**Non-Goals:**
<!-- What is explicitly left out (and why not now). -->

## Decisions

<!-- One per decision. Each one: the decision, the reason, and the discarded alternative
     with the concrete reason it was discarded. -->

### Decision: <title>

- **What:** <the decision>
- **Why:** <concrete reason>
- **Discarded alternative:** <which one> — <why not>
- **Consequences:** <what it enables, what it restricts, what becomes difficult>

## Risks / Trade-offs

<!-- Technical and process risks with concrete mitigation. Trade-offs explicitly
     accepted. -->
```

## Filling rules

- Every decision with lasting consequences (new dependency, public contract, persisted
  format, choice of library/pattern) generates an **ADR** with `templates/adr.md`.
- Explicit boundaries: which modules/files are touched and which are NOT. A design with no
  non-goals is usually a design with no limits.
- Contracts first: interfaces, types, data format, error policy. That is what the builder
  implements and the reviewer verifies.
- Every requirement of the delta must have a location (module/contract). A requirement
  with no location = incomplete design ⇒ it does not move on to `plan-change`.
- Forbidden to design for hypothetical needs: no speculative abstractions, no flags with
  no consumer, no "just in case later" (see `rules/coding.md`).
- The design does not change the meaning of the spec: if the spec is unfeasible, it is
  reported and the change goes back to `openspec-update-change`.
