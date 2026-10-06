# methodology/ddd-domain-discipline Specification

## Purpose
Turn domain-driven design from an intention into a contract the loop can fail on: the architect decides the DDD trigger from explicit signals and records the verdict, the ubiquitous language of the change lives in the project's `CONTEXT.md`, the domain model is a required section of the change's design when the trigger fires, and the reviewer verifies all three against the real diff. Verification here is review — an agent reading the diff against a contract — which the repository's mechanism vocabulary names as first class; no executable tool is required.

## Requirements

### Requirement: The DDD trigger is explicit signals

The architect MUST evaluate a fixed set of objective signals on every change and model the domain when at least one fires. The signals are:

- an invariant that must hold across more than one operation, or on every write;
- an entity with identity and a lifecycle;
- a term the change defines or redefines in the project's vocabulary;
- a boundary between two business capabilities;
- vocabulary drift already present: one business concept named in more than one way in the codebase.

The evaluation MUST be recorded in the design whether or not the trigger fires, and the architect MUST NOT leave the trigger undecided. Modeling the domain on a change where no signal fires is equally prohibited: the contract is the signal list, not the architect's initiative.

#### Scenario: A signal fires and the domain is modeled

- **WHEN** a change carries at least one of the declared signals
- **THEN** the architect models the domain, writes the `## Domain` section in the change's design, and the design records which signals fired

#### Scenario: No signal fires and the skip is falsifiable

- **WHEN** none of the declared signals fires on the change
- **THEN** the design records the signals that were evaluated and found absent, and the architect proceeds without a domain model — a partially evaluated or unrecorded trigger is not a valid skip

#### Scenario: The trigger is left undecided

- **WHEN** the design neither carries the `## Domain` section nor names the signals that were evaluated
- **THEN** the architecture stage's validation rejects the design and returns it to the architect naming the missing evaluation

### Requirement: The ubiquitous language lives in the project

When the trigger fires, the vocabulary the change resolves MUST be written in the project's `CONTEXT.md`, in the glossary format of the `domain-modeling` method — one term per concept, a definition of what the term **is** rather than what it does, and the synonyms the project rejects listed under `_Avoid_` — and the design MUST reference the terms it resolves. The glossary belongs to the project and MUST NOT be copied into global memory (`~/.hermes/**`).

#### Scenario: A term is defined or redefined

- **WHEN** the change defines a term the project did not carry, or changes what an existing term means
- **THEN** the project's `CONTEXT.md` carries that term with its definition and its rejected synonyms in the same change, and the design names the term it resolved

#### Scenario: The change needs a meaning the glossary contradicts

- **WHEN** the change requires a term to mean something different from what `CONTEXT.md` already defines
- **THEN** the architect reports the contradiction as a blocker instead of redefining the term silently, and the meaning is settled in the spec before the design continues

#### Scenario: No term is defined or redefined

- **WHEN** the change introduces no new term and redefines none
- **THEN** `CONTEXT.md` is not edited, and that outcome is part of the recorded trigger evaluation

### Requirement: The design carries the domain model

When the trigger fires, the change's design MUST carry a `## Domain` section holding the vocabulary resolution, the entities and aggregates with the invariants that must hold on them, and the boundaries between the change's business capabilities. The section MUST describe the code the change produces, not restate the proposal's motivation: every element of it is verifiable against the real diff.

#### Scenario: The domain section is complete

- **WHEN** at least one signal fired and the design carries the vocabulary resolution, the entities/aggregates with their invariants, and the capability boundaries
- **THEN** the architecture stage's validation accepts the design and the change moves to `plan-change`

#### Scenario: The section is present but hollow

- **WHEN** a signal fired and the `## Domain` section carries no invariant, no boundary or no vocabulary resolution
- **THEN** the validation rejects the design and returns it to the architect naming the missing part — a section present only to satisfy the structure is not a domain model

#### Scenario: A requirement has no place in the model

- **WHEN** a requirement of the delta cannot be located in any entity, aggregate, value or boundary of the design
- **THEN** the gap is reported and the change does not advance to `plan-change`

### Requirement: The reviewer verifies the domain contract

The reviewer MUST verify the domain contract against the real diff and report a finding, with severity and `path:line`, for each violation:

- the terms the code uses are the ones the glossary defines — naming one business concept in two ways, or using a glossary term with a meaning the glossary does not carry, is **MAJOR**;
- every invariant the design states is covered by a test that fails when the invariant is violated — an invariant with no such test is **MAJOR**;
- the code follows the declared model — a structure that contradicts the design's domain model, with the design recording no departure, is **MAJOR**;
- the architect's trigger verdict matches the diff — a diff carrying domain structure with no recorded evaluation is a **BLOCKER**, because the artifact the whole contract is anchored to is missing and the review cannot conclude.

This verification is review: an agent reading the diff against a contract. No executable tool is required for it, and no tool replaces it.

#### Scenario: The diff contradicts the glossary

- **WHEN** the diff names one business concept in two ways, or uses a glossary term with a meaning the glossary does not define
- **THEN** the reviewer reports a `MAJOR` finding with the paths and the term, and the stage does not return `approved`

#### Scenario: An invariant has no test that fails when it is violated

- **WHEN** the design states an invariant on an entity or aggregate and no test in the diff fails when that invariant is broken
- **THEN** the reviewer reports a `MAJOR` finding naming the invariant and the missing test

#### Scenario: The code departs from the declared model

- **WHEN** the implementation introduces a structure that contradicts the design's domain model and the design records no such departure
- **THEN** the reviewer reports a `MAJOR` finding — the silent divergence is exactly what the domain contract exists to catch

#### Scenario: The trigger verdict cannot be checked

- **WHEN** the diff carries domain structure (an invariant, an entity lifecycle, a redefined term) and the design records no trigger evaluation
- **THEN** the reviewer reports a `BLOCKER` naming the missing evaluation, and the review cannot close `approved`

#### Scenario: No signal fired

- **WHEN** the design records that no signal fired
- **THEN** the reviewer verifies that recorded evaluation against the diff and closes with no domain findings — an honest, recorded skip is not a finding

### Requirement: The architecture stage loads its method

The architecture stage MUST be able to load `domain-modeling`, the method `agents/architect.md` requires of it: the `/architecture` bundle carries the skill so the stage resolves it instead of reporting it missing, and the installer's missing-skill warning covers the architecture bundle as it already covers `/feature`.

#### Scenario: The architecture bundle resolves its method skill

- **WHEN** the `/architecture` bundle is built and its skills are resolved
- **THEN** `domain-modeling` appears among the loaded skills and the missing set is empty

#### Scenario: The method skill is not installed

- **WHEN** `domain-modeling` is absent from the Hermes home and the architecture bundle is selected in the installer
- **THEN** the installer's warning names the missing skill and the command that installs it, and it never installs it on its own
