## Why

A project had no agreed home for the two documents the loop needs before implementation — its PRD
and its architecture overview. The loop scaffolds `openspec/project.md` (the product context Hermes
reads) and `docs/architecture/` (a directory), but nothing declares where a project's *PRD* or its
*overview* live, what produces them, or how they relate to `project.md`. A run filled the gap with
two root-level files (`PRD.md`, `ARCHITECTURE.md`) that no workflow produced, no stage reviewed and
no gate reads — free-floating docs, and their content had already drifted from the repo (a CI
workflow, a `tests/` directory and a `bin/builder.ts` that do not exist). Where these documents
live must be a fact in the repository, not an improvisation per run.

## What Changes

- A project's **PRD** and its **architecture overview** each get one declared home and one declared
  producer.
- The PRD's home is `docs/PRD.md`; it answers *what we are building and why*. The architecture
  overview's home is `docs/ARCHITECTURE.md`; it records *the system's shape as built*. Both
  describe **the project**, never the agency.
- Product context belongs to `openspec/project.md` (the human's declaration, owned by
  `initialize-project`); the PRD is **derived from it and points at it**, so the two never become
  competing sources for the same facts.
- The PRD is authored at discovery, before any change proposes code; the architecture overview is
  authored by the architect and updated as the system changes.
- `workflows/initialize-project.md` declares the PRD as an artifact; `agents/architect.md` owns
  `docs/ARCHITECTURE.md`.
- A root-level `PRD.md` or `ARCHITECTURE.md` — a product document at the repository root that no
  workflow declares — is a documented defect the reviewer raises.

## Capabilities

### New Capabilities

- `project-docs`: the declared home, producer and relationship of a project's product documents —
  the PRD, the architecture overview, and their relation to `openspec/project.md`.

## Impact

- `workflows/initialize-project.md` (declares the PRD step), `workflows/openspec-to-architecture.md`
  (the architect maintains the overview), `agents/architect.md` (owns the overview),
  `rules/project-boundaries.md` (the product-doc boundary), `rules/openspec.md` (the preflight
  criterion), `rules/quality.md` and `agents/reviewer.md` (the root-level-doc check),
  `workflows/implement-change.md` (the preflight line), `docs/sdd-feature-lifecycle.md`, README.md,
  INSTALL.md, CHANGELOG.md.
- Each consuming project gains a `docs/PRD.md` and a `docs/ARCHITECTURE.md` at the declared homes.
  The agency ships the convention; the project writes its own documents — no product content is
  added to this repo.
