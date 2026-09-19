## 1. TDD as the builder's hard rule

- [x] 1.1 Add TDD as a hard rule to `rules/testing.md` (test-first RED→GREEN→REFACTOR, watch the test fail for the expected reason, minimal code to pass, refactor green; applies to backends, business logic, API endpoints, bug fixes) — verifies: `grep -q test-first rules/testing.md`
- [x] 1.2 Add the `not applicable` rule to `rules/testing.md` — code with no behavior to prove (config, generated code, glue, throwaway) is declared not applicable with its reason; never a skipped default — verifies: `grep -q "not applicable" rules/testing.md`
- [x] 1.3 Add TDD as a hard rule to the builder's persona/method and protocol (`agents/builder.md`) — verifies: `grep -q "test-driven-development" agents/builder.md`

## 2. DDD as an architect modeling technique

- [x] 2.1 Add DDD as a modeling technique applied when the domain merits it to `agents/architect.md` (entities/aggregates, ubiquitous language, bounded contexts; skip on thin behavior) — verifies: `grep -q "Domain-Driven" agents/architect.md`
- [x] 2.2 State that the builder follows the DDD model once the architect chose it (`rules/coding.md`) — verifies: `grep -q "domain" rules/coding.md`

## 3. Workflow and docs cross-reference

- [x] 3.1 State in `workflows/implement-change.md` that the builder implements TDD-first by hard rule — verifies: `grep -q "test-first" workflows/implement-change.md`
- [x] 3.2 Update `README.md` complementary-skills section to mention TDD/DDD methodology — verifies: `grep -q "TDD" README.md`
- [x] 3.3 Update `docs/sdd-feature-lifecycle.md` to reflect the TDD/DDD-directed build stage — verifies: `grep -q "test-first" docs/sdd-feature-lifecycle.md`
