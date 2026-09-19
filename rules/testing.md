# Rule: Testing

The spec rules: tests verify the specified behavior, not the one the code
ended up having.

## Origin of the tests

- The `#### Scenario:` of the delta spec (`openspec/changes/<name>/specs/<cap>/spec.md`) are
  the source of truth for expected behavior. Every relevant scenario must be able to
  be traced to a test (or to the QA case that covers it).
- A fix always carries a regression test that **fails without the fix**: if the test passes
  before and after, it proves nothing.
- Tests are not written to freeze values that change by design (catalogs,
  versions, counts). Relationships and contracts between data are tested, not snapshots.

## Test-driven development (default method)

Behavior-bearing work is implemented **test-first** by default. This is the agency's
antidote to trial-and-error loops: behavior is pinned by a failing test before any
implementation exists.

- **RED:** write one minimal test that demonstrates the expected behavior from the spec
  scenario. Run it and confirm it fails **for the expected reason** (feature missing, not
  a typo). A test that passes before the code exists is testing the wrong thing.
- **GREEN:** write the minimal code that makes it pass. No extra features, no
  refactoring beyond the test.
- **REFACTOR:** clean up while keeping the test green. Do not add behavior.
- Verify RED and GREEN per task, with the real run output, before moving to the next
  task.

**Skipping TDD is the exception, not the default.** The builder deliberately omits the
cycle only for UI glue, generated code, configuration/transpilation or a throwaway
prototype — and records each omission with its concrete reason in the report. Everything
that changes observable behavior is test-first unless the omission is justified there.

## Prohibitions

- A test is not weakened, skipped (`skip`) nor deleted to make the gate pass. If an
  existing test contradicts the spec, that is a spec conversation, not a silent
  edit.
- The environment is not falsified to make a test pass (mocking the operating system, the
  clock, the network or the database when the real behavior is what is to be verified).
  The legitimate exception is isolating a non-deterministic external dependency, declared
  as such.
- Tests that were not run are not declared green.
- Tests from another project are not copied as a content template; only the form.

## Execution

- The repo's real gate is run, as the repo declares it, not an invented command
  nor a convenient subset:

  ```bash
  git diff --stat
  cat package.json | jq '.scripts'    # or Makefile / justfile / pyproject.toml
  ```

- If the project has git hooks, run their equivalent before committing (the hook is not
  the place where you discover that the code does not pass).
- Test commands are executed from the project root, without changing projects.
- A test that only passes on retry is flaky: it is reported as a stage defect, with
  the evidence of both results.
- If the gate cannot be run (lack of environment, credentials or time), the report is
  `blocked` with the reason; green is never declared by omission.

## Isolation

- Tests do not depend on the machine's global state nor on other projects: no
  absolute paths to the home, shared data or services turned on "from before".
- Tests do not write outside the project (nor in `~/.hermes/`, nor in neighboring repos).
- Tests do not require network unless the specified behavior is network-related, and in
  that case they are explicitly marked.

## Tests are not QA

- The builder delivers unit/integration tests of the change; the **qa** agent validates the
  behavior against the spec with real execution (it includes edge cases and the
  complete user path).
- QA does not replace tests and tests do not replace QA: if QA finds a defect,
  the fix goes back to the builder and brings its regression test.
- QA's evidence is the real executed result (command, output, textual capture of the
  failure), not reading the code.

## Output

When closing the stage, the report to Hermes includes:

- exact gate command and its result (green/red with the relevant output);
- which spec scenarios remain covered and which do not;
- defects found with severity (`rules/quality.md`) and state;
- declared debt: missing coverage and why it was not covered now.
