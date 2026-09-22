## 1. `bin/review-snapshot`

- [x] 1.1 Add `bin/review-snapshot` (bash 3.2, read-only): resolves base (default `main`, overridable with `--base`) and `HEAD`, computes the content fingerprint via `bin/no-smoke-worktree`, computes the diff hash of `<base>...HEAD`, and writes the snapshot to `--out` (default `reports/review-snapshot.json`). Verifies: `bash -n bin/review-snapshot` and `bin/review-snapshot --out "$TMPDIR/snap.json"` exits 0 with the file containing base, head, fingerprint and diffHash keys
- [x] 1.2 Guarantee read-only behaviour: the command must not modify the index, the refs or any tracked file. Verifies: `git status --porcelain` is empty before and after a run, and `git rev-parse HEAD` is unchanged
- [x] 1.3 Make a re-run over an unchanged tree report an identical fingerprint and diff hash. Verifies: two runs to two `--out` paths, then `diff` of just those fields shows no difference
- [x] 1.4 Expose a comparison mode that reports match or mismatch with both values named. Verifies: `bin/review-snapshot --compare <snap.json>` exits 0 on an unchanged tree and exits non-zero naming both fingerprints after a file is modified
- [x] 1.5 Add the fixture/check under `fixtures/review-snapshot/`: a check script that takes a snapshot, mutates a file, re-checks and asserts the mismatch is reported — and takes the same snapshot after a content-preserving commit, asserting it still matches. Verifies: `fixtures/review-snapshot/check.sh` exits 0 and prints a MATCH and a MISMATCH case
- [x] 1.6 Gitignore the snapshot default path so a snapshot of a moving tree cannot break the fingerprint it records. Verifies: `git check-ignore reports/review-snapshot.json` exits 0

## 2. `bin/review-tier`

- [x] 2.1 Add `bin/review-tier` (bash 3.2, read-only) implementing the declared table in `rules/quality.md`: it measures authored changed lines over `<base>...HEAD` and matches the touched paths against the high-consequence classes, and prints the tier plus the rule(s) that fired. Verifies: `bash -n bin/review-tier` and a run over a docs-only fixture diff prints `low` with the fired reason
- [x] 2.2 Implement the high-consequence path classes so each one forces `high` regardless of size. Verifies: one fixture diff per declared class (schema/migration, auth, security config, dependency manifest/lockfile) each prints `high` naming that class
- [x] 2.3 Implement the size bound: a diff touching no high-consequence path and under the bound is `medium`, above it is `high`. Verifies: fixtures under and over the bound print `medium` and `high` respectively, each naming the size rule
- [x] 2.4 Report "cannot assess" instead of `low` when the diff cannot be measured (unknown base, not a repository, missing tool). Verifies: a run with `--base <nonexistent-ref>` prints a not-assessed verdict and exits non-zero, with no tier value printed
- [x] 2.5 Make the tier deterministic: the same diff always yields the same tier and reason. Verifies: two runs over the same fixture diff produce byte-identical output
- [x] 2.6 Add `fixtures/review-tier/`: one case per declared path class, plus an over-bound and an under-bound case, plus the ordinary behaviour case, and a check script asserting each expected tier. Verifies: `fixtures/review-tier/check.sh` exits 0 and prints one line per case with the expected tier

## 3. Rules, workflow and agent wiring

- [x] 3.1 Add to `rules/quality.md`: the snapshot-before-review rule (freeze the candidate, cite the snapshot in the reviewer/QA brief, re-compare at delivery, mismatch is a blocker of the existing fingerprint class). Verifies: `grep -qi 'review-snapshot' rules/quality.md` and `grep -qi 'snapshot' rules/quality.md`
- [x] 3.2 Add to `rules/quality.md` the declared tier table (path classes, size bounds, the three tiers) and the statement that the tier selects depth only — it never blocks, closes or replaces the `pr-review` QA gate, and an unavailable assessment is never `low`. Verifies: `grep -q 'review-tier' rules/quality.md` and `grep -qi 'informational' rules/quality.md`
- [x] 3.3 Wire the snapshot into `workflows/review-change.md` preflight and the reviewer brief, and the tier into the persona/checks selection. Verifies: `grep -qi 'review-snapshot' workflows/review-change.md` and `grep -qi 'review-tier' workflows/review-change.md`
- [x] 3.4 Reference both in `agents/reviewer.md` (the snapshot is what the findings describe; the tier selects the checks). Verifies: `grep -qi 'review-snapshot' agents/reviewer.md` and `grep -qi 'tier' agents/reviewer.md`
- [x] 3.5 Document both bins in `README.md` and `INSTALL.md` alongside the existing `bin/` entries. Verifies: `grep -q 'review-snapshot' README.md INSTALL.md` and `grep -q 'review-tier' README.md INSTALL.md`

## 4. Closure

- [x] 4.1 `openspec validate "evidence-bound-review" --type change --json` reports no ERROR and every `ℹ INFO` is read and reported. Verifies: the command's JSON with `summary.totals.failed == 0` quoted in the report
- [x] 4.2 Run the repo's real checks on everything touched: `bash -n` on every `bin/` script and fixture script, both fixture checks green, and `bin/no-smoke-worktree` still exits 0. Verifies: quoted exit codes and the fingerprint value
- [x] 4.3 QA the installer still carries the new bins to a temp prefix. Verifies: `test -x <temp-prefix>/bin/review-snapshot` and `test -x <temp-prefix>/bin/review-tier` plus the installer's exit code
- [x] 4.4 Update `CHANGELOG.md` `[Unreleased]` with one short entry per bin, keeping the Gentle-AI (MIT) attribution. Verifies: `grep -q 'review-snapshot' CHANGELOG.md && grep -q 'review-tier' CHANGELOG.md`
- [ ] 4.5 Tick every task only against its own verification command, then archive + sync as a separate follow-up. Verifies: `openspec instructions apply --change "evidence-bound-review" --json` with `progress.remaining == 0`
