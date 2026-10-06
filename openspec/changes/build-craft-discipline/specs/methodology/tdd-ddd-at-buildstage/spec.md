# Methodology — TDD and DDD at the build stage (delta)

## MODIFIED Requirements

### Requirement: Test-driven build (hard rule)

The builder MUST implement behavior-bearing work test-first — write a failing test that demonstrates the expected behavior, watch it fail for the expected reason, write the minimal code that makes it pass, then refactor — before marking the task implemented. There is no agent discretion to skip test-first for code that carries business logic.

The craft that makes the cycle produce a test worth keeping — the seam the test is written at, the assertions that prove nothing, the vertical slice — is owned by `methodology/build-craft`; this requirement keeps its force and does not restate it.

#### Scenario: Behavior change is implemented test-first

- **WHEN** the builder implements a new behavior or fixes a bug that changes observable behavior
- **THEN** it writes the failing test first, confirms the failure is for the expected reason, writes the minimal code that passes it, and refactors while keeping the test green, running a verification per task before moving on

#### Scenario: Behavior-free code is declared not applicable

- **WHEN** the builder omits the test-first cycle for configuration, generated code, boilerplate glue, wiring or a throwaway prototype
- **THEN** it is only because the code has no behavior to prove, and the case is declared `not applicable` in the report with its concrete reason — never a silently skipped default

#### Scenario: The cycle is satisfied and the test proves nothing

- **WHEN** a test was written first and fails for the expected reason, but its assertion recomputes the expected value the way the code computes it, or it is coupled to the implementation
- **THEN** the cycle was followed and the test is still a finding: what makes a test worth keeping is `methodology/build-craft`, not the order in which it was written
