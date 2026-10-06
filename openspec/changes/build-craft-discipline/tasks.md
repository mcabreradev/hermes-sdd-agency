## 1. The three method skills

- [x] 1.1 Write `skills/build-craft/SKILL.md`: the seam rule (seams named and agreed before the first test, a test at an unconfirmed seam is not written), a good test verifies behaviour through the interface, the three anti-patterns (implementation-coupled, tautological, horizontal slicing), and vertical slices one at a time — verifies: `test -f skills/build-craft/SKILL.md && grep -qi 'seam' skills/build-craft/SKILL.md && grep -qi 'tautological' skills/build-craft/SKILL.md && grep -qi 'vertical slice' skills/build-craft/SKILL.md`
- [x] 1.2 Write `skills/bug-diagnosis/SKILL.md`: the diagnosis loop — a command already run that goes red on this bug before any hypothesis, minimise the repro, rank falsifiable hypotheses, instrument one variable at a time, fix only at a seam where the regression test exercises the real pattern — verifies: `test -f skills/bug-diagnosis/SKILL.md && grep -q 'red on this bug' skills/bug-diagnosis/SKILL.md && grep -q 'falsifiable' skills/bug-diagnosis/SKILL.md`
- [x] 1.3 Write `skills/module-design/SKILL.md`: the shared vocabulary (module, interface, implementation, depth, seam, adapter, leverage, locality), deep vs shallow, the deletion test, one adapter = a hypothetical seam and two make it real, the interface is the test surface, and accept-don't-create dependencies — verifies: `test -f skills/module-design/SKILL.md && for t in 'module' 'interface' 'depth' 'seam' 'adapter' 'leverage' 'locality' 'deletion test'; do grep -qi "$t" skills/module-design/SKILL.md || exit 1; done`
- [x] 1.4 Each skill carries a Hermes-clean frontmatter and no host-specific mechanism from the upstream kit (no router, no setup command, no slash command, no runtime, no `npx`) — verifies: `! grep -rqiE 'ask-matt|setup-matt|/clear|/compact|npx skills|claude plugins' skills/build-craft skills/bug-diagnosis skills/module-design && for f in skills/build-craft skills/bug-diagnosis skills/module-design; do head -3 "$f/SKILL.md" | grep -q '^description: "Use when' || exit 1; done && test "$(for f in skills/build-craft skills/bug-diagnosis skills/module-design; do sed -n 's/^description: "\(.*\)"$/\1/p' "$f/SKILL.md"; done | cut -c1-57 | grep -c '^Use when')" = "3"` (the trigger's first 57 characters are the routing signal the Hermes index truncates to; each must open with the trigger)
- [x] 1.5 The trigger sentence of every new skill fits the 57-character window the Hermes index truncates to, so the trigger reads whole rather than cut mid-phrase — verifies: `for f in skills/build-craft skills/bug-diagnosis skills/module-design; do d=$(sed -n 's/^description: "\(.*\)"$/\1/p' "$f/SKILL.md"); s="${d%%.*}"; test "${#s}" -le 57 || { echo "TOO LONG: $f ${#s}"; exit 1; }; done && echo 0`

## 2. The rules that state the craft

- [x] 2.1 `rules/testing.md`: add a "Test craft" section — the seams are agreed and written down before the first test, expected values come from an independent source of truth (the anti-pattern is the assertion that recomputes the expected value the way the code computes it), a test verifies behaviour through the interface, and work proceeds in vertical slices — verifies: `grep -q '## Test craft' rules/testing.md && grep -q 'independent source of truth' rules/testing.md && grep -q 'vertical slice' rules/testing.md`
- [x] 2.2 `rules/testing.md`: add a "Diagnosis before a fix" section — a bug whose cause is not visible is diagnosed with a command that goes red on *this* bug before a hypothesis is committed to, and a fix ships the regression test that fails without it — verifies: `grep -q '## Diagnosis before a fix' rules/testing.md && grep -qi 'red on' rules/testing.md`
- [x] 2.3 `rules/testing.md` keeps the hard rule's force: the "no agent discretion on skipped test-first" sentence survives and the change introduces no new discretion phrasing into the cycle — verifies: `grep -q 'There is no' rules/testing.md && grep -q 'agent discretion on skipped test-first' rules/testing.md && test "$(grep -ciE 'default with|agent discretion on skipping|agent.s judgment|may skip' rules/testing.md)" = "0"` (the sentence is wrapped across two lines, so it is matched in two tokens; the regex half is 0 in the pristine file at `main` too — it is the invariant that the craft sections add no exemption, not a count of new lines)
- [x] 2.4 `rules/quality.md` "Definition of Done by task type": the `builder` row carries the craft (the seams under test agreed and declared; no assertion whose expected value recomputes the implementation), the `reviewer` row carries the anti-pattern checks — verifies: `grep -q 'seams under test agreed and declared' rules/quality.md && grep -q 'tautological' rules/quality.md`

## 3. The stages that load and check it

- [x] 3.1 `agents/builder.md`: the method list gains `build-craft` (the test discipline) and `bug-diagnosis` (the loop that precedes a fix), keeping `test-driven-development` as the red-green cycle — verifies: `grep -q 'build-craft' agents/builder.md && grep -q 'bug-diagnosis' agents/builder.md && grep -q 'test-driven-development' agents/builder.md`
- [x] 3.2 `agents/builder.md`: state that a stuck task is diagnosed before a hypothesis, and that the seam of a module the change introduces is recorded — verifies: `grep -qi 'red on' agents/builder.md && grep -q 'seam' agents/builder.md`
- [x] 3.3 `agents/reviewer.md`: a new checklist item with the craft checks and their severities (tautological / implementation-coupled / horizontal slicing / a regression test that passes without the fix = MAJOR; a seam neither agreed nor declared, a pass-through module = MINOR), naming `module-design` as the vocabulary for a structural dispute — verifies: `grep -q 'tautological' agents/reviewer.md && grep -q 'module-design' agents/reviewer.md`
- [x] 3.4 `agents/reviewer.md`: extend the Definition of Done with the craft checks beside the DDD domain contract — verifies: `grep -qi 'craft' agents/reviewer.md`
- [x] 3.5 `workflows/implement-change.md` and `workflows/review-change.md` name the two new methods where they already name the stage's personas/method — verifies: `grep -q 'build-craft' workflows/implement-change.md && grep -q 'bug-diagnosis' workflows/implement-change.md && grep -q 'module-design' workflows/review-change.md`

## 4. The public surfaces and the attribution

- [x] 4.1 `README.md`: the badges and the catalog heading count the real tree after the change — verifies: `test "$(./bin/skill-registry --root skills 2>/dev/null | grep -c '^SKILL.md\|^PATH:')" = "68"` and the numbers in `README.md` equal it
- [x] 4.2 `README.md`: the three skills are listed in the process-skills table with the description their own frontmatter carries, and the operating-rules table says what `testing.md` now states — verifies: `grep -q 'build-craft' README.md && grep -q 'bug-diagnosis' README.md && grep -q 'module-design' README.md`
- [x] 4.3 `INSTALL.md`: the badge and the TL;DR row count the real tree — verifies: `grep -q 'skills: 68' INSTALL.md && grep -q '68 skills' INSTALL.md`
- [x] 4.4 `docs/sdd-feature-lifecycle.md`: the build stage reflects the craft and the diagnosis loop — verifies: `grep -q 'build-craft' docs/sdd-feature-lifecycle.md && grep -qi 'diagnos' docs/sdd-feature-lifecycle.md`
- [x] 4.5 `CHANGELOG.md` `[Unreleased]` `### Added`: the three skills, the rules that carry the craft, and the adaptation note for the new upstream source (`mattpocock/skills`, MIT) with the clause stating what was **not** taken — verifies: `grep -q 'build-craft' CHANGELOG.md && grep -q 'mattpocock/skills' CHANGELOG.md && grep -q 'Not\*\* taken' CHANGELOG.md && grep -q 'no host runtime' CHANGELOG.md`

## 5. Verification of this change

- [x] 5.1 The change validates with no failure — verifies: `test "$(openspec validate build-craft-discipline --type change --json | jq -r '.summary.totals.failed')" = "0"`
- [x] 5.2 The `ℹ [INFO]` lines are read, not ignored: no `Archive would refuse this delta` for either delta — verifies: `openspec validate build-craft-discipline --type change --json | jq -r '[.items[].issues[]?.message] | map(select(test("Archive would refuse"))) | length'` prints `0`
- [x] 5.3 The main specs stay valid after the deltas are written — verifies: `openspec validate --specs --json | jq -r '.summary.totals.failed'` prints `0`
- [x] 5.4 The repo's own known trap is checked: no main spec starts with a delta header — verifies: `grep -rl '^## ADDED Requirements' openspec/specs/*/spec.md | wc -l | tr -d ' '` prints `0`
- [x] 5.5 Every new skill is registered and routable, and the registry flags nothing — verifies: `./bin/skill-registry --root skills 2>/dev/null | grep -A5 '^NAME: build-craft$' | grep -q '^FLAG: ok' && ./bin/skill-registry --root skills 2>/dev/null | grep -A5 '^NAME: bug-diagnosis$' | grep -q '^FLAG: ok' && ./bin/skill-registry --root skills 2>/dev/null | grep -A5 '^NAME: module-design$' | grep -q '^FLAG: ok'`
- [x] 5.6 The registry and the public counts agree — verifies: `test "$(./bin/skill-registry --root skills 2>&1 >/dev/null | grep -o '[0-9]* skills inventoried' | awk '{print $1}')" = "68"`
- [x] 5.7 The installer passes its own prerequisite check and carries the new skills — this repo's `install.sh` requires `hermes` on PATH, so the check is run against a stub `hermes` on PATH (the installer only uses the binary for that guard) — verifies: `stub="$(mktemp -d)" && printf '#!/bin/sh\n' > "$stub/hermes" && chmod +x "$stub/hermes" && tmp="$(mktemp -d)" && PATH="$stub:$PATH" bash install.sh --prefix "$tmp" --yes >/dev/null 2>&1 && test -f "$tmp/skills/build-craft/SKILL.md" && test -f "$tmp/skills/bug-diagnosis/SKILL.md" && test -f "$tmp/skills/module-design/SKILL.md" && echo 0`
- [x] 5.7b Without the stub the installer's guard is what stops it (the guard is real, not bypassed by this test) — verifies: `tmp="$(mktemp -d)" && bash install.sh --prefix "$tmp" --yes >/dev/null 2>&1; echo $?` prints `1` and the message names `hermes`
- [x] 5.8 The declared diff matches the touched files (the declared diff rule) — verifies: `git add -A && git diff --cached --name-only main | sort` equals the declared list below, which is the same set sorted:

  ```
  CHANGELOG.md
  INSTALL.md
  README.md
  agents/builder.md
  agents/reviewer.md
  docs/sdd-feature-lifecycle.md
  openspec/changes/build-craft-discipline/
  rules/quality.md
  rules/testing.md
  skills/build-craft/SKILL.md
  skills/bug-diagnosis/SKILL.md
  skills/module-design/SKILL.md
  workflows/implement-change.md
  workflows/review-change.md
  ```
- [x] 5.9 The authored-lines budget is measured and the delivery strategy recorded against the measurement (design.md, "Delivery strategy") — verifies: `git add -A && test "$(git diff --cached --numstat main | awk '{s+=$1+$2} END{print s}')" = "1093" && test "$(git diff --cached --numstat main -- . ':(exclude)openspec/changes/build-craft-discipline' | awk '{s+=$1+$2} END{print s}')" = "520"` and the two figures recorded in `design.md` agree with those prints (over the 400 advisory ⇒ the chosen strategy is `single-pr` with the two rejected ones named)

## 6. Archive and sync (separate follow-up PR — left unticked)

- [ ] 6.1 Sync the main spec for `methodology/build-craft` and archive the change once the feature PR is merged — verifies: `openspec list --json | jq -r '.changes | length'` prints the count of active changes minus one, and `openspec validate --archived --json | jq -r '.summary.totals.failed'` prints `0`
