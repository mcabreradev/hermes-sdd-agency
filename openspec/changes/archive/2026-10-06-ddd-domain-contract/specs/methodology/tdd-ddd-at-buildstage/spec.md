## MODIFIED Requirements

### Requirement: Domain-driven modeling when the domain merits it

The architect MUST model the change's domain with Domain-Driven Design whenever a signal of `methodology/ddd-domain-discipline` fires, applying that capability's trigger, artifacts and vocabulary rules; and the builder MUST follow the resulting model instead of embedding domain rules implicitly in code. The trigger is not redefined here: the signal list, the recorded verdict and the review of the domain contract are owned by `methodology/ddd-domain-discipline`.

#### Scenario: Architect applies DDD to a domain-rich change

- **WHEN** at least one signal of `methodology/ddd-domain-discipline` fires on the change
- **THEN** the architect shapes the domain model as that capability specifies — the vocabulary resolution and the domain model in the change's design, the glossary in the project's `CONTEXT.md` — and the builder implements following that model

#### Scenario: Skip DDD on thin behavior

- **WHEN** the change is a bounded behavior without a meaningful domain structure and no signal fires
- **THEN** the architect and builder proceed without a DDD model, the architect records the signals it evaluated and found absent, and no domain modeling is forced
