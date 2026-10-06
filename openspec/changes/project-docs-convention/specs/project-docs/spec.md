# Project docs Specification

## Purpose

Declare where a project's product documents live, who produces them, and how they relate to the
project's product context, so the loop stops improvising a root-level `PRD.md` or `ARCHITECTURE.md`
that no workflow produced and no gate reads. The agency ships the convention; each project writes
its own documents. Verification is review — an agent reading the artifacts against this contract —
and no executable tool is required for it.

## ADDED Requirements

### Requirement: The PRD has a declared home and a producer

A project's PRD MUST live at `docs/PRD.md`, and the `initialize-project` workflow MUST declare it as
an artifact of project initialization. A PRD at any other path — in particular a root-level `PRD.md`
— is not the project's PRD this convention recognizes.

#### Scenario: Initialization declares the PRD

- **WHEN** `initialize-project` runs on a project that has no PRD
- **THEN** it declares `docs/PRD.md` as the home of the PRD and produces or scaffolds that file, and
  the verification `test -f docs/PRD.md` passes

#### Scenario: A root-level PRD is a defect

- **WHEN** a project carries a product PRD at its repository root (`PRD.md`) instead of `docs/PRD.md`
- **THEN** the reviewer reports it as a documented defect naming the declared home, and the file does
  not count as the project's PRD

### Requirement: The architecture overview has a declared home and a producer

A project's architecture overview MUST live at `docs/ARCHITECTURE.md`, and the `architect` stage MUST
own it as the durable record of the system's shape. It is not the change's `design.md` and not an ADR:
those are per-change, while the overview describes the system as built.

#### Scenario: The architect owns the overview

- **WHEN** the `architect` stage runs for a project
- **THEN** it is the owner of `docs/ARCHITECTURE.md`, records the system's shape there, and updates
  it when the architecture changes rather than leaving it frozen at initialization

#### Scenario: The overview is not the change's design

- **WHEN** a change records a design decision
- **THEN** the per-change `design.md` carries the change's decisions and the durable, system-wide
  result is reflected in `docs/ARCHITECTURE.md`, and the two are not treated as the same document

### Requirement: The PRD derives from the product context

`openspec/project.md` MUST remain the project's product context — the human's declaration of purpose,
scope, business rules and constraints — and `docs/PRD.md` MUST derive from it and point at it rather
than restate its facts, so one fact has one home.

#### Scenario: One fact, one home

- **WHEN** the PRD needs a fact that `openspec/project.md` already declares
- **THEN** the PRD references `project.md` for that fact instead of duplicating it, and a fact stated
  in both with divergent values is a defect

#### Scenario: A documentation phase does not open without its PRD

- **WHEN** a project declares the **documentation** phase and its PRD is missing, or still carries
  `Pending` content
- **THEN** `workflows/implement-change.md`'s preflight does not enable implementation — the
  `rules/openspec.md` preflight criterion fails — and the PRD is authored at discovery before that
  phase opens. Enforcement is the documented preflight, named in `rules/openspec.md`; it is not a
  new bin, and the scenario is not satisfied by prose alone

### Requirement: The producer of each document is the stage that owns it

Each document MUST have exactly one producing stage, and the convention MUST name it, so a document
is never authored by an unowned process. The PRD's producer is `initialize-project`, the project's
initialization stage, which creates its home at `docs/PRD.md`; the architecture overview's producer
is the `architect` stage. The `discovery` persona fills the PRD's content — in `initialize-project`
and, when the intent changes later, in `idea-to-openspec` — but the **producing stage** that owns the
document is the one that creates its home and is named here.

#### Scenario: A document with no declared producer

- **WHEN** a product document appears in a project that no declared stage produced
- **THEN** the reviewer reports it as a defect naming the stage that should own it, because a document
  with no producer has no review

#### Scenario: The convention is the agency's, the content is the project's

- **WHEN** this convention is installed
- **THEN** it ships the declared homes and producers only, and no product content enters the agency's
  own repository (no `docs/PRD.md` and no `docs/ARCHITECTURE.md` is created here)
