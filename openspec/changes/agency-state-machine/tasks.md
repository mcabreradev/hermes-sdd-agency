## 1. `bin/agency-next`

- [x] 1.1 Add `bin/agency-next` (bash 3.2, read-only, `--help`): resolves the OpenSpec root and the active change, and prints one public state (`working` | `checking` | `ready` | `needs-decision`), the precise state underneath it, the single next transition, and the command that performs it. Verifies: `bash -n bin/agency-next` and `bin/agency-next --help` exits 0 naming the four public states
- [x] 1.2 Derive the artifact portion of the state from the OpenSpec CLI JSON only (never from a session's memory): `openspec list`, `openspec status`, `openspec instructions apply`. Verifies: with an all-tasks-ticked change the command reports the review transition, and with partial tasks it reports `working`
- [x] 1.3 Read the review evidence: when `bin/review-snapshot`'s manifest exists for the change, compare it against the current tree and report the stale-evidence state on a mismatch. Verifies: a fixture repo where the manifest mismatches prints the stale-evidence precise state naming both fingerprints
- [x] 1.4 Report the no-active-change case plainly with the transition that starts one, instead of inventing a stage. Verifies: `bin/agency-next` in a repo with no active change prints that state and exits 0
- [x] 1.5 Implement the declared precision limits: an unavailable input (no run trace, `gh` missing, no remote configured) still yields the provable state plus a section naming every transition whose verdict could not be determined, with the reason. Verifies: a run with `PATH` stripped of `gh` in a repo with a remote prints the precision section naming the PR state as undetermined
- [x] 1.6 Guarantee determinism and read-only behaviour: identical output across runs, and `git status --porcelain` plus `git rev-parse HEAD` unchanged. Verifies: two runs diff byte-identical, and the tree inspection before/after shows no change
- [x] 1.7 Print, as part of the output, that the state is informational and that the gates remain the reviewer's and QA's verdicts. Verifies: `grep -qi 'informational' <(bin/agency-next)` or the help text, and the output names the gates
- [x] 1.8 Add `fixtures/agency-next/check.sh`: builds throwaway repos (planning-complete/partial tasks, all tasks done with no review evidence, a stale review snapshot, no active change, `gh` absent) and asserts the public state, the precise state and the exit contract for each. Verifies: `fixtures/agency-next/check.sh` exits 0 and prints one line per case with the expected state

## 2. Rule and workflow wiring

- [x] 2.1 Add the state/transition table to `rules/orchestration.md`: the four public states, the precise vocabulary, the one-transition rule, and the statement that the state is informational — it never blocks, authorizes or replaces a gate. Verifies: `grep -q 'agency-next' rules/orchestration.md` and `grep -qi 'informational' rules/orchestration.md`
- [x] 2.2 Use it in `workflows/continue-change.md` as the resume derivation, keeping the existing checkboxes and `git diff` as the cross-check it already documents. Verifies: `grep -q 'agency-next' workflows/continue-change.md`
- [x] 2.3 Document the command in `README.md` and `INSTALL.md` alongside the other `bin/` entries. Verifies: `grep -q 'agency-next' README.md INSTALL.md`

## 3. Closure

- [x] 3.1 `openspec validate "agency-state-machine" --type change --json` reports no ERROR and every `ℹ INFO` is read and reported. Verifies: the command's JSON with `summary.totals.failed == 0` quoted in the report
- [x] 3.2 Run the repo's real checks on everything touched: `bash -n` on every `bin/` script and fixture script, all fixture checks green, and `bin/no-smoke-worktree` still exits 0. Verifies: quoted exit codes and the fingerprint value
- [x] 3.3 QA the installer still carries the new bin to a temp prefix. Verifies: `test -x <temp-prefix>/bin/agency-next` plus the installer's exit code
- [x] 3.4 Update `CHANGELOG.md` `[Unreleased]` with one short entry, keeping the Gentle-AI (MIT) attribution. Verifies: `grep -q 'agency-next' CHANGELOG.md`
- [ ] 3.5 Tick every task only against its own verification command, then archive + sync as a separate follow-up. Verifies: `openspec instructions apply --change "agency-state-machine" --json` with `progress.remaining == 0`
