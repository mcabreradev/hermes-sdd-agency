# Example change — add-priority-tags

A complete, minimal OpenSpec change to study before running the loop. It shows the
real shape of the three artifacts the openspec, architect and planner stages produce.
Everything here follows the templates in `../templates/` exactly.

> **Scope note:** this is an *educative* example. The "product" (a document search
> tool) is fictional and lives only here — no project is harmed.
>
> To create a change like this in a real project, the **openspec stage** scaffolds it
> with `openspec new change add-priority-tags`; you never write `openspec/changes/*`
> by hand (a rule). The layout below is only so you can see the target shape.

```
openspec/changes/add-priority-tags/
  proposal.md          # why + what changes + capabilities (openspec stage)
  specs/search/spec.md # requirement deltas + scenarios (openspec stage)
  tasks.md             # granular verifiable plan (planner stage)
```

---

## `proposal.md`

```markdown
## Why

Users can't tell urgent documents apart in the search results page, so important
contracts get lost among routine files. Today there is no way to mark a document as
high priority.

## What Changes

- Documents gain an optional **priority** (high | normal). Normal is the default.
- Search results can be **filtered by priority** and **sorted with high first**.
- Setting priority requires write access to the document; it is an account-level
  capability, not public.

## Capabilities

### New Capabilities

- `search`: documents carry a priority, and results can be filtered/sorted by it.

## Impact

- Data: adds a `priority` field to the document record (migration required).
- API: `GET /documents` accepts `priority` and `sort=priority`; `PATCH /documents/:id`
  accepts `priority`.
- No breaking changes to existing clients.
```

---

## `specs/search/spec.md`

```markdown
## Purpose

Documents carry an optional priority; search results can be filtered and sorted by it
so that urgent items surface first.

## ADDED Requirements

### Requirement: Document carries an optional priority

The system MUST support a document-level `priority` of `high` or `normal`, defaulting
to `normal`.

#### Scenario: default priority is normal

- **WHEN** a document is created without specifying a priority
- **THEN** its priority is `normal`

#### Scenario: high priority is persisted

- **WHEN** a client sets a document's priority to `high`
- **THEN** the document is retrievable with `priority == high` on later reads

### Requirement: Results filterable by priority

The system MUST return only documents whose priority matches the requested filter when
`priority` is provided.

#### Scenario: filter to high only

- **WHEN** a search requests `priority=high`
- **THEN** every returned document has `priority == high`

### Requirement: Results sortable high-first

The system MUST order high-priority documents before normal ones when `sort=priority`.

#### Scenario: high before normal, stable within priority

- **WHEN** a search requests `sort=priority` and the matches include both priorities
- **THEN** all `high` results appear before all `normal` results

### Requirement: Setting priority requires write access

The system MUST reject a priority change with `403` when the caller lacks write access
to the document.

#### Scenario: read-only caller rejected

- **WHEN** a caller without write access submits `PATCH` with `priority=high`
- **THEN** the system responds `403 Forbidden` and the priority is unchanged
```

---

## `tasks.md`

```markdown
## 1. Document model

- [ ] 1.1 Add `priority` field (enum `high|normal`) to the document schema — verifies:
      `bun test src/models/document.test.ts` (default-normal + high-persisted scenarios)
- [ ] 1.2 Migration for existing records (default `normal`) — verifies:
      `bun run migrate && bun run migrate:verify`

## 2. Read path

- [ ] 2.1 Accept `priority` filter in `GET /documents` — verifies:
      `curl '...?priority=high'` returns only high (filter scenario)
- [ ] 2.2 Accept `sort=priority` high-first ordering, stable within priority — verifies:
      `curl '...?sort=priority'` returns high-before-normal (sort scenario)

## 3. Write path

- [ ] 3.1 Accept `priority` in `PATCH /documents/:id` with write-access gate — verifies:
      `bun test src/handlers/patch-document.test.ts` (403 scenario)
```

---

## Walkthrough against the loop

| Stage | What happens to this change |
|---|---|
| 1 discovery | explore the repo (document schema, read/write paths), write a PRD that this proposal condenses |
| 2 openspec | `openspec new change add-priority-tags`, then this `proposal.md` + `spec.md`; `validate` passes |
| 3 architect | confirm the migration + API shape are right; ADR only if a real alternative is rejected |
| 4 planner | this `tasks.md`; change becomes `ready` |
| 5 builder | implements 1.1 → 3.1, marking `- [x]` only as each verifies green |
| 6 reviewer | adversarial diff vs the spec; the 403 gate and sort stability are checked |
| 7 qa | executes the 5 scenarios for real behavior |
| 8 release | notes + `openspec archive` + sync to `openspec/specs/search/spec.md` + final report |

## Why this shape

- **One requirement per verifiable behavior**, normative wording, no implementation
  detail (no function names, no files).
- **Every requirement has ≥1 scenario** in WHEN/THEN, each convertible to a test or a
  QA case. That is what makes the delta testable and the whole loop auditable.
- **tasks.md** groups by dependency, each task carries its verify command, and none
  depends on an open decision.
- The `## Purpose` section exists because this capability is **new** — archiving copies
  it into the main spec; without it the spec is left `TBD` (`templates/spec.md`).
