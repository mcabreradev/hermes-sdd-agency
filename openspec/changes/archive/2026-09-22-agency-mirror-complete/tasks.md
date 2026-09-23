## 1. Mirror

- [x] 1.1 Five SKILL.md mirrored byte-identical from live (4 in `skills/software-development/`, 1 in `skills/autonomous-ai-agents/`) — verifies: `diff -r` live vs repo empty for the five dirs
- [x] 1.2 Seven references mirrored (maintenance 3, release-closure 2, export 1, packaging 1; invocation has none) — verifies: `ls` each `references/` matches live

## 2. Public readiness

- [x] 2.1 No personal path or credential in the five SKILL.md + references — verifies: grep `/Users/migue` + `BEGIN (RSA|OPENSSH|EC) PRIVATE` empty; the vault rule present by design in `sdd-agency-maintenance`

## 3. Spec + validate

- [x] 3.1 Delta spec written, change validated — verifies: `openspec validate --change agency-mirror-complete --json` failed == 0

## 4. Close

- [x] 4.1 CHANGELOG bullet (English, user-facing) — verifies: `grep -q "agency skills" CHANGELOG.md`
- [x] 4.2 `openspec validate --all` green (post-merge) — verifies: failed == 0
