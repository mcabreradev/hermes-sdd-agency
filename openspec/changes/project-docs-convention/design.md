# Design

## Context

The loop scaffolds a project and tells Hermes where the product context lives: `openspec/project.md`
(the `## Agentic Workflow Rules` marker, the human's declaration), `docs/architecture/` (a place for
the architecture) and `docs/decisions/` (ADRs). What it never declares is where a project's **PRD**
lives or where its **architecture overview** lives.

Two files reached the root of this repository the way the gap predicts: `PRD.md` and
`ARCHITECTURE.md`, authored by no workflow in the loop. They were untracked, unreviewed and never
read by a gate — and their content had drifted from the repo in the first paragraph (an
`.github/workflows/ci.yml`, a `tests/` directory, `bin/builder.ts`, `pnpm-lock.yaml`, none of which
exist here). A product document with no declared producer is a document with no review.

The constraint this design works under: the agency ships **process only** and no project's product
content (`rules/project-boundaries.md`). A convention about where product documents live is process,
so it belongs here; the documents themselves never do.

## Goals / Non-Goals

**Goals**

- One declared home and one declared producer for the PRD and for the architecture overview.
- The PRD reads as derived from `openspec/project.md`, not as a second, competing product context.
- The architecture overview is owned by the stage that owns architecture, and is updated as the
  system changes rather than frozen at initialization.
- A root-level product doc is a named defect, so the next run's improvisation is caught by review.

**Non-Goals**

- No product content in this repository: no `docs/PRD.md` or `docs/ARCHITECTURE.md` is created here.
- No new bin and no executable gate: the checks are review, an agent reading the artifact against
  the contract — the same mechanism vocabulary the DDD contract uses for a contract with no
  mechanical form.
- Not a rewrite of `docs/` for this repo beyond the README/INSTALL/CHANGELOG lines the change touches.

## Decisions

### D1 — `docs/PRD.md` and `docs/ARCHITECTURE.md`, not root-level files

The declared homes are under `docs/`, next to `docs/architecture/` and `docs/decisions/` that
`initialize-project` already creates. The alternative — root-level `PRD.md` / `ARCHITECTURE.md`,
which is exactly what the incident produced — is rejected: the repository root is where the process's
own entry points live (README, INSTALL, LICENSE, install.sh), and a product document there is
indistinguishable from a process document to every reader. `docs/` already carries the project's
prose (`evidence-bins`, `sdd-feature-lifecycle`), so a product document beside it is coherent.

### D2 — Separation of concerns: `project.md` owns context, the PRD owns the product, the overview owns the system

The trap is three files saying the same thing and drifting. The boundary is drawn explicitly in the
capability: `openspec/project.md` is the human's declaration (purpose, scope, business rules,
constraints); `docs/PRD.md` is the product document derived from it and **points at it** rather than
restating the facts; `docs/ARCHITECTURE.md` is the system's shape as built. A fact belongs to one of
the three, and the PRD linking to `project.md` is what keeps "the same fact in two places" from
being a defect by construction.

### D3 — The PRD is authored at discovery; the overview by the architect

`initialize-project` already runs the `prd` persona at discovery and already owns `docs/architecture/`.
The overview's producer is the `architect` stage (`openspec-to-architecture`), which owns `design.md`
and ADRs — the architecture overview is the durable, system-wide rendering of what those decisions
produce. Rejected alternative: authoring the overview at `initialize-project` (it would be a snapshot
of a system that does not exist yet, stale the moment the first change lands).

### D4 — No new bin: the checks are review

A doc's home is verifiable by eye and by `test -f` in a `verifies:`, but its *content* (the overview
matching the system) is not mechanically checkable, and a bin that pretended to would be decoration.
The contract is stated so review can fail on it, exactly as `methodology/ddd-domain-discipline`
states its reviewer checks with no tool. This keeps `bin/` at eight and adds no dependency.

### D5 — The root-level doc is the reviewer's check, not a deny-list entry

`rules/project-boundaries.md` already carries a sensitive-path deny list for security paths. A stray
product document is not sensitive — it is *undescribed* — so it belongs in `rules/quality.md` /
`agents/reviewer.md` as a checklist item (`MINOR`), not in the security deny list (`BLOCKER`).
Conflating the two would put a documentation slip in the same class as a leaked secret.

## Risks / Trade-offs

- **A convention with no content created here reads as a no-op.** Mitigation: the capability's
  requirements are concrete homes and producers, and `initialize-project` gets a real step and a task
  verification (`test -f docs/PRD.md`), so the consuming project is left with the artifact.
- **Two homes plus `project.md` invite drift.** Mitigation: D2 states which fact belongs where and
  requires the PRD to point at `project.md`; the reviewer check names the competing-source case.
- **A `MINOR` root-doc check could be ignored.** Acceptable: it is documentation, and the standing
  rule already lets Hermes decide `MINOR`s; it is a lead for the reviewer, not a gate.

## Delivery strategy

`single-pr`. The change is one convention delivered as prose across the files that already own the
relevant stages; there is no slice boundary at which the behavior is usable alone (a home declared
without the producer, or the producer without the check, is half a convention). The authored-line
figure is measured before the final commit and recorded here; it is expected to be under the
advisory ~400-line budget (`rules/coding.md`), so no larger strategy is forced.

## Domain — trigger evaluation

**Signals evaluated (all five, per `agents/architect.md`):**

1. *an invariant that must hold across more than one operation, or on every write* — **absent**. The
   change states where documents live and who writes them; nothing is enforced on every write.
2. *an entity with identity and a lifecycle* — **absent**. `docs/PRD.md` is a file with a path, not
   a stateful entity with transitions.
3. *a term the change defines or redefines in the project's vocabulary* — **present**. The change
   redefines *PRD* and *architecture overview* as terms with a declared home, a producer and a
   relation to `project.md`; the vocabulary is the substance of the capability.
4. *a boundary between two business capabilities* — **present** (weak). It draws a boundary between
   product context (`project.md`) and product documents (`docs/PRD.md`, `docs/ARCHITECTURE.md`).
5. *vocabulary drift already present* — **present**. This repo carried root-level `PRD.md` and
   `ARCHITECTURE.md` alongside a scaffolded `docs/architecture/`, with no vocabulary distinguishing
   a product doc from a process doc.

**Verdict: the trigger fired (signals 3, 4, 5; 4 weakly). The domain is modeled.**

### Vocabulary resolution

The terms this change fixes, and where they belong. This repo ships **no** `CONTEXT.md` — the
glossary is each *project's* (`rules/coding.md`, "Domain model"); this change defines the vocabulary
of the convention itself:

| Term | What it **is** | `_Avoid_` |
|---|---|---|
| product context | the human's declaration in `openspec/project.md` — purpose, scope, rules, constraints | "requirements doc", "spec" |
| PRD | the project document at `docs/PRD.md`, derived from the product context, answering *what and why* | "project.md", "spec" |
| architecture overview | the project document at `docs/ARCHITECTURE.md`, the durable record of the system's shape as built | "design.md" (that is the change's), "ADR" |
| process document | a file the agency ships — README, INSTALL, a rule, a workflow | "doc" |

### Invariants and the tests that must fail when violated

This change introduces no runtime and no behavior-bearing code, so its invariants are **artifact**
invariants: each is provable by a `verifies:` command that fails when it is violated, and each is
bound to a task below.

- The declared homes are named where the producers are: `workflows/initialize-project.md` names
  `docs/PRD.md`, `agents/architect.md` names `docs/ARCHITECTURE.md`.
- No product content enters this repository: no `docs/PRD.md` and no `docs/ARCHITECTURE.md` exists in
  the tree (`rules/project-boundaries.md`).
- The reviewer check exists and names the root-level defect; `rules/quality.md` states the boundary.
