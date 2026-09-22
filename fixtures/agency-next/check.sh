#!/usr/bin/env bash
# Fixture check for bin/agency-next: builds throwaway OpenSpec repos under $TMPDIR (never
# inside this repo) and asserts the public state, the precise state and the exit contract for
# each shape the machine must tell apart.
#
# The fixtures need the real `openspec` CLI (the command derives the artifact state from it).
# When it is absent the suite reports that plainly instead of passing vacuously.
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
NEXT="$HERE/../../bin/agency-next"
OPENSPEC=$(command -v openspec 2>/dev/null || true)
WS=$(mktemp -d "${TMPDIR:-/tmp}/agency-next-fixtures-XXXXXX") || exit 1
trap 'rm -rf "$WS"' EXIT

fail=0
checked=0

if [ -z "$OPENSPEC" ]; then
  printf 'SKIP  the openspec CLI is not on PATH — agency-next cannot be exercised here\n'
  printf '\nchecked=0 failures=0\n'
  exit 0
fi

# make_repo <name> — a git repo with a baseline commit.
# bash 3.2 declares every name in a multi-assignment `local` BEFORE assigning any of them, so
# `local name="$1" dir="$WS/$name"` reads an unset `name` (fatal under `set -u`). One per line.
make_repo() {
  local name="$1"
  local dir="$WS/$name"
  mkdir -p "$dir"
  (
    cd "$dir" || exit 1
    git init -q -b main
    git config user.email "fixture@example.com"
    git config user.name "fixture"
    printf 'baseline\n' > README.md
    git add -A
    git commit -q -m "chore: baseline"
  )
  printf '%s' "$dir"
}

# scaffold <dir> <change> — real CLI scaffold (never mkdir, per rules/openspec.md).
scaffold() {
  (cd "$1" && "$OPENSPEC" new change "$2" >/dev/null 2>&1) || return 1
}

# tick_all <dir> <change> — write a tasks.md whose boxes are all ticked, so the CLI reports
# progress complete (the state depends on the CLI's own count, not on our string matching).
tick_all() {
  local dir="$1"
  local change="$2"
  local f="$dir/openspec/changes/$change/tasks.md"
  [ -f "$f" ] || return 1
  sed -i.bak 's/^- \[ \]/- [x]/' "$f"
  rm -f "$f.bak"
}

# scaffold_planned <dir> <change> — a CLI-scaffolded change with complete planning artifacts.
# Every artifact the CLI counts toward `isPlanningComplete` must exist, or the machine (correctly)
# reports the planning-incomplete state instead of the apply-ready one.
scaffold_planned() {
  local dir="$1"
  local change="$2"
  local cd="$1/openspec/changes/$2"
  scaffold "$dir" "$change" || return 1
  printf '## Why\n\nfixture\n\n## What Changes\n\n- one thing\n\n## Capabilities\n\n### New Capabilities\n\n- `fixture-cap`: a fixture capability\n' > "$cd/proposal.md"
  mkdir -p "$cd/specs/fixture-cap"
  printf '## Purpose\n\nA fixture capability used to exercise the state machine.\n\n## ADDED Requirements\n\n### Requirement: Something observable\n\nThe system MUST do the observable thing.\n\n#### Scenario: It happens\n\n- **WHEN** the fixture runs\n- **THEN** the observable thing happens\n' > "$cd/specs/fixture-cap/spec.md"
  printf '## Context\n\nfixture\n\n## Goals / Non-Goals\n\n**Goals:**\n\n- fixture\n\n**Non-Goals:**\n\n- fixture\n\n## Decisions\n\n- fixture\n\n## Risks / Trade-offs\n\n- fixture\n' > "$cd/design.md"
  # Mirror the CLI's own template so the task count is real.
  printf '## 1. Work\n\n- [ ] 1.1 Do the first thing\n- [ ] 1.2 Do the second thing\n' > "$cd/tasks.md"
}

# assert_state <case> <dir> <expected-public> [expected-precise] [--change <name>]
assert_state() {
  local case="$1" dir="$2" expected="$3" precise="${4:-}" out rc got prec
  shift 4 2>/dev/null || shift 3
  out=$(cd "$dir" && "$NEXT" "$@" 2>&1); rc=$?
  checked=$((checked + 1))
  got=$(printf '%s\n' "$out" | sed -n 's/^state: *//p' | head -n 1)
  prec=$(printf '%s\n' "$out" | sed -n 's/^precise: *//p' | head -n 1)
  if [ "$got" = "$expected" ] && { [ -z "$precise" ] || [ "$prec" = "$precise" ]; }; then
    printf 'OK     %-40s state=%s precise=%s\n' "$case" "$got" "$prec"
  else
    printf 'FAIL   %-40s expected=%s/%s got=%s/%s\n' "$case" "$expected" "$precise" "$got" "$prec"
    printf '       output: %s\n' "$(printf '%s' "$out" | head -n 4 | tr '\n' '|')"
    fail=$((fail + 1))
  fi
}

# --- no active change -------------------------------------------------------------------
D=$(make_repo no-change)
( cd "$D" && "$OPENSPEC" init --tools hermes >/dev/null 2>&1 )
D=$(cd "$D" && pwd)
assert_state "no active change" "$D" "needs-decision" "NO_ACTIVE_CHANGE"

# --- ambiguity: two changes, no --change ------------------------------------------------
D=$(make_repo ambiguous)
( cd "$D" && "$OPENSPEC" init --tools hermes >/dev/null 2>&1 )
scaffold_planned "$D" "first-change" >/dev/null 2>&1
scaffold_planned "$D" "second-change" >/dev/null 2>&1
assert_state "ambiguous change list" "$D" "needs-decision" "AMBIGUOUS_CHANGE"

# --- planning incomplete ---------------------------------------------------------------
D=$(make_repo planning-incomplete)
( cd "$D" && "$OPENSPEC" init --tools hermes >/dev/null 2>&1 )
scaffold "$D" "half-planned" >/dev/null 2>&1
assert_state "planning incomplete" "$D" "working" "PLANNING_INCOMPLETE" --change "half-planned"

# --- ready to apply (planned, nothing ticked) ------------------------------------------
D=$(make_repo ready-apply)
( cd "$D" && "$OPENSPEC" init --tools hermes >/dev/null 2>&1 )
scaffold_planned "$D" "fresh-change" >/dev/null 2>&1
assert_state "planned, no task done" "$D" "working" "READY_TO_APPLY" --change "fresh-change"

# --- implementing (some tasks ticked) ---------------------------------------------------
D=$(make_repo implementing)
( cd "$D" && "$OPENSPEC" init --tools hermes >/dev/null 2>&1 )
scaffold_planned "$D" "partial-change" >/dev/null 2>&1
( cd "$D/openspec/changes/partial-change" && sed -i.bak 's/^- \[ \] 1.1/- [x] 1.1/' tasks.md && rm -f tasks.md.bak )
assert_state "partially implemented" "$D" "working" "IMPLEMENTING" --change "partial-change"

# --- all tasks done, no review evidence -------------------------------------------------
D=$(make_repo done-no-evidence)
( cd "$D" && "$OPENSPEC" init --tools hermes >/dev/null 2>&1 )
scaffold_planned "$D" "done-change" >/dev/null 2>&1
tick_all "$D" "done-change"
assert_state "all done, no snapshot" "$D" "checking" "READY_TO_REVIEW" --change "done-change"

# --- stale review evidence outranks "tasks done" ----------------------------------------
D=$(make_repo stale-evidence)
( cd "$D" && "$OPENSPEC" init --tools hermes >/dev/null 2>&1 )
scaffold_planned "$D" "stale-change" >/dev/null 2>&1
tick_all "$D" "stale-change"
( cd "$D" && printf 'reports/\n' > .gitignore && git add -A && git commit -q -m "chore: ignore reports" )
( cd "$D" && "$HERE/../../bin/review-snapshot" --base main --out reports/review-snapshot.json >/dev/null 2>&1 )
( cd "$D" && printf 'changed after the snapshot\n' >> README.md )
assert_state "stale review evidence" "$D" "checking" "STALE_EVIDENCE" --change "stale-change"

# --- current evidence, no PR → archive pending (the user's call) -------------------------
D=$(make_repo archive-pending)
( cd "$D" && "$OPENSPEC" init --tools hermes >/dev/null 2>&1 )
scaffold_planned "$D" "complete-change" >/dev/null 2>&1
tick_all "$D" "complete-change"
( cd "$D" && printf 'reports/\n' > .gitignore && printf 'more content\n' > feature.txt && git add -A && git commit -q -m "feat: work" )
( cd "$D" && "$HERE/../../bin/review-snapshot" --base main --out reports/review-snapshot.json >/dev/null 2>&1 )
out=$(cd "$D" && "$NEXT" --change "complete-change" 2>&1)
checked=$((checked + 1))
if printf '%s' "$out" | grep -q '^state: *ready' && printf '%s' "$out" | grep -q "user's call\|USER"; then
  printf 'OK     %-40s ready, decision is the user\x27s\n' "current evidence, no PR"
else
  printf 'FAIL   %-40s expected ready with a human decision: %s\n' "current evidence, no PR" "$(printf '%s' "$out" | head -n 3 | tr '\n' '|')"
  fail=$((fail + 1))
fi

# --- an in-repo default snapshot path + a remote + gh present, with NO PR open -------------
# This is the shape that made an EMPTY precision array reachable (bash 3.2 turns `"${arr[@]}"`
# on an empty array under `set -u` into a fatal error), so it must assert exit 0 explicitly.
D=$(make_repo ready-no-pr)
( cd "$D" && "$OPENSPEC" init --tools hermes >/dev/null 2>&1 )
scaffold_planned "$D" "solo-change" >/dev/null 2>&1
tick_all "$D" "solo-change"
( cd "$D" && printf 'reports/\n' > .gitignore && printf 'work\n' > feature.txt && git add -A && git commit -q -m "feat: work" )
( cd "$D" && "$HERE/../../bin/review-snapshot" --base main --out reports/review-snapshot.json >/dev/null 2>&1 )
out=$(cd "$D" && "$NEXT" --change "solo-change" 2>&1); rc=$?
checked=$((checked + 1))
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q '^state: *ready'; then
  printf 'OK     %-40s exit=0 with a determined ready state\n' "ready state exits 0 (no crash)"
else
  printf 'FAIL   %-40s exit=%s output=%s\n' "ready state exits 0 (no crash)" "$rc" "$(printf '%s' "$out" | tail -n 2 | tr '\n' '|')"
  fail=$((fail + 1))
fi
checked=$((checked + 1))
if printf '%s' "$out" | grep -qi 'informational'; then
  printf 'OK     %-40s the output says so\n' "state is declared informational"
else
  printf 'FAIL   %-40s no informational line in the output\n' "state is declared informational"
  fail=$((fail + 1))
fi

# --- a stale snapshot names BOTH fingerprints ----------------------------------------------
( cd "$D" && printf 'moved after the snapshot\n' >> feature.txt )
out=$(cd "$D" && "$NEXT" --change "solo-change" 2>&1)
checked=$((checked + 1))
if printf '%s' "$out" | grep -q '^precise: *STALE_EVIDENCE' && printf '%s' "$out" | grep -q 'snapshot fingerprint: [0-9a-f]'; then
  printf 'OK     %-40s names the recorded fingerprint too\n' "stale names both fingerprints"
else
  printf 'FAIL   %-40s output=%s\n' "stale names both fingerprints" "$(printf '%s' "$out" | grep -E 'fingerprint|precise' | tr '\n' '|')"
  fail=$((fail + 1))
fi

# --- gh present but unable to answer (PATH stripped of everything but a fake failing gh) ----
D=$(make_repo gh-broken)
( cd "$D" && "$OPENSPEC" init --tools hermes >/dev/null 2>&1 )
scaffold_planned "$D" "gh-change" >/dev/null 2>&1
tick_all "$D" "gh-change"
( cd "$D" && printf 'reports/\n' > .gitignore && printf 'w\n' > f.txt && git add -A && git commit -q -m "feat: w" )
# A remote must exist or the gh branch is never reached (the command declares "no remote" and
# stops): the case under test is gh PRESENT and FAILING, not gh absent.
( cd "$D" && git remote add origin git@github.com:mcabreradev/hermes-sdd-agency.git 2>/dev/null || true )
( cd "$D" && "$HERE/../../bin/review-snapshot" --base main --out reports/review-snapshot.json >/dev/null 2>&1 )
FAKEBIN="$WS/fakebin"
# A gh that exists but always fails, with every other tool the command needs still reachable.
# The real PATH dirs are appended (not replaced): `openspec` is a node wrapper, so stripping
# PATH to hide gh would also hide node and make the CLI fail — which is a different case.
(
  cd "$D" || exit 1
  mkdir -p "$WS/fakebin"
  printf '#!/bin/sh\nexit 1\n' > "$WS/fakebin/gh"
  chmod +x "$WS/fakebin/gh"
  mkdir -p "$WS/realtools"
  for tool in git openspec jq sed awk grep head tr dirname basename date shasum sort node; do
    real=$(command -v "$tool" 2>/dev/null || true)
    [ -n "$real" ] && ln -sf "$real" "$WS/realtools/$tool"
  done
)
out=$(cd "$D" && PATH="$WS/fakebin:$WS/realtools:/usr/bin:/bin" bash "$NEXT" --change "gh-change" 2>&1); rc=$?
# The failing gh must be the one found first.
found=$(cd "$D" && PATH="$WS/fakebin:$WS/realtools:/usr/bin:/bin" command -v gh)
rm -f "$WS/fakebin/gh.bak" 2>/dev/null || true
# A gh that exits non-zero must NOT make the command fall through to a determinate state.
if [ -n "$found" ] && PATH="$WS/fakebin:$WS/realtools:/usr/bin:/bin" "$found" pr list >/dev/null 2>&1; then
  rc=999
fi
checked=$((checked + 1))
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'PR_STATE_UNDETERMINED'; then
  printf 'OK     %-40s gh broken is declared, not read as no-PR\n' "gh present but failing"
else
  printf 'FAIL   %-40s exit=%s output=%s\n' "gh present but failing" "$rc" "$(printf '%s' "$out" | grep -E 'state|precise|cannot' | tr '\n' '|')"
  fail=$((fail + 1))
fi

# --- a state that cannot be determined ---------------------------------------------------
D="$WS/not-a-repo"
mkdir -p "$D"
out=$(cd "$D" && "$NEXT" 2>&1); rc=$?
checked=$((checked + 1))
if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -q 'cannot determine'; then
  printf 'OK     %-40s exit=2, names why\n' "not a repository"
else
  printf 'FAIL   %-40s expected exit 2 + reason, got rc=%s\n' "not a repository" "$rc"
  fail=$((fail + 1))
fi

# --- determinism -------------------------------------------------------------------------
D=$(make_repo deterministic)
( cd "$D" && "$OPENSPEC" init --tools hermes >/dev/null 2>&1 )
scaffold_planned "$D" "det-change" >/dev/null 2>&1
checked=$((checked + 1))
if diff <(cd "$D" && "$NEXT" --change det-change 2>&1 | grep -v '^  fingerprint:') \
        <(cd "$D" && "$NEXT" --change det-change 2>&1 | grep -v '^  fingerprint:') >/dev/null; then
  printf 'OK     %-40s byte-identical across runs\n' "deterministic"
else
  printf 'FAIL   %-40s two runs differ\n' "deterministic"
  fail=$((fail + 1))
fi

# --- read-only ---------------------------------------------------------------------------
before="$(cd "$D" && git status --porcelain | sort | shasum) $(cd "$D" && git rev-parse HEAD)"
(cd "$D" && "$NEXT" --change det-change >/dev/null 2>&1)
after="$(cd "$D" && git status --porcelain | sort | shasum) $(cd "$D" && git rev-parse HEAD)"
checked=$((checked + 1))
if [ "$before" = "$after" ]; then
  printf 'OK     %-40s tree and HEAD unchanged\n' "read-only"
else
  printf 'FAIL   %-40s something changed\n' "read-only"
  fail=$((fail + 1))
fi

printf '\nchecked=%s failures=%s\n' "$checked" "$fail"
# Fail CLOSED: a suite that built nothing must not report green. `exit "$fail"` alone exits 0
# when every case failed to build, which is how this harness hid a real crash for a whole pass.
if [ "$checked" -eq 0 ]; then
  printf 'FAIL   no case ran — the harness could not build its fixtures\n'
  exit 1
fi
exit "$fail"
