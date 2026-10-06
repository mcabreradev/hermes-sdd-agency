# Methodology — TDD and DDD at the build stage Specification

## Purpose

Direct the implementation method inside the agency loop: test-driven development as a **hard rule** for behavior-bearing code (backends, business logic, API endpoints, bug fixes) to stop introducing regressions and add the correct, most working behavior; and domain-driven design as a modeling technique the architect applies when the domain merits it. Pure process guidance that applies to any project the agency runs.

## Requirements

### Requirement: Test-driven build (hard rule)

The builder MUST implement behavior-bearing work test-first — write a failing test that demonstrates the expected behavior, watch it fail for the expected reason, write the minimal code that makes it pass, then refactor — before marking the task implemented. There is no agent discretion to skip test-first for code that carries business logic.

#### Scenario: Behavior change is implemented test-first

- **WHEN** the builder implements a new behavior or fixes a bug that changes observable behavior
- **THEN** it writes the failing test first, confirms the failure is for the expected reason, writes the minimal code that passes it, and refactors while keeping the test green, running a verification per task before moving on

#### Scenario: Behavior-free code is declared not applicable

- **WHEN** the builder omits the test-first cycle for configuration, generated code, boilerplate glue, wiring or a throwaway prototype
- **THEN** it is only because the code has no behavior to prove, and the case is declared `not applicable` in the report with its concrete reason — never a silently skipped default

### Requirement: Domain-driven modeling when the domain merits it

The architect MUST model the change's domain with Domain-Driven Design whenever a signal of `methodology/ddd-domain-discipline` fires, applying that capability's trigger, artifacts and vocabulary rules; and the builder MUST follow the resulting model instead of embedding domain rules implicitly in code. The trigger is not redefined here: the signal list, the recorded verdict and the review of the domain contract are owned by `methodology/ddd-domain-discipline`.

#### Scenario: Architect applies DDD to a domain-rich change

- **WHEN** at least one signal of `methodology/ddd-domain-discipline` fires on the change
- **THEN** the architect shapes the domain model as that capability specifies — the vocabulary resolution and the domain model in the change's design, the glossary in the project's `CONTEXT.md` — and the builder implements following that model

#### Scenario: Skip DDD on thin behavior

- **WHEN** the change is a bounded behavior without a meaningful domain structure and no signal fires
- **THEN** the architect and builder proceed without a DDD model, the architect records the signals it evaluated and found absent, and no domain modeling is forced
