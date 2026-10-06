## 1. The gate itself

- [x] 1.1 `bin/phase-gate` exists, is executable, and reads `phase` + `application-code` from the `## Phase` block of `openspec/project.md` — verifies: `test -x bin/phase-gate && bin/phase-gate --help | head -5`
- [x] 1.2 The documentation phase refuses a tree that carries a tracked file under the declared paths, naming the paths, exit 1 — verifies: `bin/phase-gate --root fixtures/phase-gate/roots/docs-violating; echo "exit=$?"` prints the violating path and `exit=1`
- [x] 1.3 The documentation phase passes a tree with no such file, exit 0 — verifies: `bin/phase-gate --root fixtures/phase-gate/roots/docs-clean; echo "exit=$?"` prints `exit=0`
- [x] 1.4 The implementation phase imposes nothing and passes — verifies: `bin/phase-gate --root fixtures/phase-gate/roots/implementation; echo "exit=$?"` prints `phase: implementation` and `exit=0`
- [x] 1.5 An undeclared, unrecognized or path-less phase cannot be assessed and exits 2, never 0 — verifies: `for d in fixtures/phase-gate/roots/no-declaration fixtures/phase-gate/roots/unknown-phase fixtures/phase-gate/roots/no-paths; do bin/phase-gate --root "$d"; echo "$d exit=$?"; done` shows `exit=2` three times
- [x] 1.6 The verdict is stable across runs over an unchanged tree — verifies: `diff <(bin/phase-gate --root fixtures/phase-gate/roots/docs-violating) <(bin/phase-gate --root fixtures/phase-gate/roots/docs-violating)` is empty
- [x] 1.7 The gate reads the project's own tree and not its ignored worktrees' copies — verifies: a fixture root carrying the code only under a `.worktrees/` subdirectory passes, printed as `exit=0`

## 2. The suite that pins it

- [x] 2.1 `fixtures/phase-gate/check.sh` runs one case per row of the design's exit-code table and prints a case count — verifies: `bash fixtures/phase-gate/check.sh; echo "exit=$?"` prints `checked=7 failed=0` and `exit=0`
- [x] 2.2 The suite fails closed: it exits non-zero when the bin under test is absent, printing a distinct code, and never reports a false green — verifies: `PATH=/usr/bin:/bin bash fixtures/phase-gate/check.sh; echo "exit=$?"` is non-zero with the skip message
- [x] 2.3 Each refusal case is paired with a near-miss that must stay clean, so a pattern widened to recall is caught — verifies: `fixtures/phase-gate/roots/docs-clean-miss/` (a behavior-bearing file outside the declared globs, e.g. `packages/worker/main.ts`) passes while `docs-violating` refuses

## 3. The rule and the loop

- [x] 3.1 `rules/openspec.md` carries the phase gate as a precondition of the Hard rule and in the preflight checklist — verifies: `grep -n 'phase-gate' rules/openspec.md` names both places
- [x] 3.2 `rules/coding.md`'s precondition requires the declared phase to permit implementation — verifies: `grep -n 'phase' rules/coding.md | head` shows the precondition
- [x] 3.3 `workflows/implement-change.md` runs the gate in its blocking preflight — verifies: `grep -n 'phase-gate' workflows/implement-change.md`
- [x] 3.4 `agents/builder.md` carries the phase precondition in its brief — verifies: `grep -n 'phase' agents/builder.md`
- [x] 3.5 `rules/orchestration.md` classifies a phase refusal as `decision` and declares the phase-gated state — verifies: `grep -n 'phase' rules/orchestration.md | head`
- [x] 3.6 `bin/agency-next` does not propose `implement-change` in a documentation-phase project — verifies: over a fixture repo in the documentation phase, `bin/agency-next --change <name>` prints the phase-gated transition and never `implement-change`

## 4. Surfaces and closure

- [x] 4.1 `docs/phase-gate.md` documents the declaration, the exit codes and a real run — verifies: `grep -n 'phase: documentation' docs/phase-gate.md`
- [x] 4.2 `README.md`, `INSTALL.md`, `docs/evidence-bins.md` and `CHANGELOG.md` count and describe the new bin — verifies: `grep -c 'phase-gate' README.md INSTALL.md docs/evidence-bins.md CHANGELOG.md` is non-zero in each
- [x] 4.3 `INSTALL.md` tells a user to declare the phase and wire the gate in their CI, including the migration note for projects that carry no declaration — verifies: `grep -n 'Phase' INSTALL.md`
- [x] 4.4 `bash -n` passes on the new bin and the new suite — verifies: `bash -n bin/phase-gate && bash -n fixtures/phase-gate/check.sh; echo "exit=$?"` is `exit=0`
- [ ] 4.5 The OpenSpec change validates with no ERROR and archives cleanly — verifies: `openspec validate documentation-phase-gate --type change --json` shows `summary.totals.failed` at 0
