## 1. Mirror sync

- [x] 1.1 SKILL.md copied from live (334 lines) over the repo mirror — verifies: `diff <repo SKILL.md> <live SKILL.md>` empty-before-teaching
- [x] 1.2 Six references present in the repo skill dir (4 refreshed, 2 new) — verifies: `ls references/` == live list

## 2. Teaching edits (visible in the diff)

- [x] 2.1 Parallelization section teaches the derived verdict (change-collision, 3 verdicts, families; union-of-paths rule gone) — verifies: `grep -q "change-collision"` + no `union of touched paths`
- [x] 2.2 Loop section teaches blocker classes + trust vocabulary with the `self_reported` hard gate — verifies: `grep` for `retryable` `technical` `decision` + `verified` + `self_reported` hits

## 3. Spec + validate

- [x] 3.1 Delta spec written and change validated — verifies: `openspec validate --change orchestration-skill-sync --json` failed == 0

## 4. Close

- [x] 4.1 CHANGELOG bullet (English, user-facing) — verifies: `grep -q "orchestration skill" CHANGELOG.md`
- [x] 4.2 After merge: live sync to `~/.hermes/skills` with pre-copy diff guard — verifies: post-copy `diff` live==repo
