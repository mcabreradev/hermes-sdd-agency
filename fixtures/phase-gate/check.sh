#!/usr/bin/env bash
# Fixture check for bin/phase-gate.
#
# Every case is a real root on disk (fixtures/phase-gate/roots/<name>) and asserts the verdict
# AND the exit code, one case per row of the exit-code table in the change's design.md:
#
#   0 pass · 1 refuse · 2 cannot assess (never a pass)
#
# The suite fails CLOSED at the top: if the bin under test cannot be executed, it exits 3 with a
# distinct message instead of reporting the green that "no case failed" would produce. A harness
# whose pass condition is "nothing failed" is green when everything failed to run.
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
BIN="$HERE/../../bin/phase-gate"
ROOTS="$HERE/roots"
WS=$(mktemp -d "${TMPDIR:-/tmp}/phase-gate-fixtures-XXXXXX") || exit 1
trap 'rm -rf "$WS"' EXIT

# The worktree case needs a REAL repository: a fixture nested inside this repo would be committed
# as a gitlink (an embedded repository), which is not the shape being tested. It is built here,
# outside the tree, and removed by the trap.
make_worktree_root() {
  local dir="$WS/worktrees-ignored"
  mkdir -p "$dir/openspec" "$dir/.worktrees/scratch/src" "$dir/docs"
  printf '# Project: worktrees-ignored\n\n## Phase\n\nphase: documentation\napplication-code: src/**\n' > "$dir/openspec/project.md"
  printf '# ignore\n.worktrees/\n' > "$dir/.gitignore"
  printf 'export const x = 1;\n' > "$dir/.worktrees/scratch/src/main.ts"
  printf 'readme\n' > "$dir/README.md"
  (
    cd "$dir" || exit 1
    git init -q -b main
    git config user.email "fixture@example.com"
    git config user.name "fixture"
    git add -A
    git commit -q -m "chore: baseline"
  ) >/dev/null 2>&1
  printf '%s' "$dir"
}

# run_case_abs <label> <absolute-root> <expected-exit> [<expected-substring>]
run_case_abs() {
  local label="$1" root="$2" want="$3" needle="${4:-}"
  checked=$((checked+1))
  local out rc
  out=$("$BIN" --root "$root" 2>&1)
  rc=$?
  if [ "$rc" -ne "$want" ]; then
    printf 'FAIL  %-34s exit=%s want=%s\n      %s\n' "$label" "$rc" "$want" "$(printf '%s' "$out" | tr '\n' '|')"
    fail=$((fail+1))
    return
  fi
  if [ -n "$needle" ] && ! printf '%s' "$out" | grep -q -- "$needle"; then
    printf 'FAIL  %-34s exit=%s ok but output lacks %s\n      %s\n' "$label" "$rc" "$needle" "$(printf '%s' "$out" | tr '\n' '|')"
    fail=$((fail+1))
    return
  fi
  printf 'ok    %-34s exit=%s\n' "$label" "$rc"
}

if [ ! -x "$BIN" ]; then
  printf 'phase-gate fixtures: SKIP — bin under test is missing or not executable: %s\n' "$BIN" >&2
  exit 3
fi

fail=0
checked=0

# run_case <label> <root> <expected-exit> [<expected-substring>]
run_case() {
  local label="$1" root="$2" want="$3" needle="${4:-}"
  checked=$((checked+1))
  local out rc
  out=$("$BIN" --root "$ROOTS/$root" 2>&1)
  rc=$?
  if [ "$rc" -ne "$want" ]; then
    printf 'FAIL  %-34s exit=%s want=%s\n      %s\n' "$label" "$rc" "$want" "$(printf '%s' "$out" | tr '\n' '|')"
    fail=$((fail+1))
    return
  fi
  if [ -n "$needle" ] && ! printf '%s' "$out" | grep -q -- "$needle"; then
    printf 'FAIL  %-34s exit=%s ok but output lacks %s\n      %s\n' "$label" "$rc" "$needle" "$(printf '%s' "$out" | tr '\n' '|')"
    fail=$((fail+1))
    return
  fi
  printf 'ok    %-34s exit=%s\n' "$label" "$rc"
}

# --- the table ------------------------------------------------------------------------------
run_case docs-clean          docs-clean         0 'verdict: pass'
run_case docs-violating      docs-violating     1 'verdict: refuse'
run_case docs-violating-names-src   docs-violating  1 'src/main.ts'
run_case docs-violating-names-test  docs-violating  1 'test/app.e2e-spec.ts'
run_case implementation      implementation     0 'phase: implementation'
run_case bare-dir-glob       bare-dir           1 'src/deep/main.ts'
run_case_abs worktrees-ignored "$(make_worktree_root)" 0 'verdict: pass'

# near-miss: behavior-bearing files OUTSIDE the declared globs must stay clean. A pattern
# widened for recall would swallow these and only this pair catches it.
run_case near-miss-clean     docs-clean-miss    0 'verdict: pass'

# cannot assess: never a pass, always exit 2
run_case no-declaration      no-declaration     2 'cannot assess'
run_case unknown-phase       unknown-phase      2 'cannot assess'
run_case no-paths            no-paths           2 'cannot assess'

# --- determinism ----------------------------------------------------------------------------
checked=$((checked+1))
if diff <("$BIN" --root "$ROOTS/docs-violating" 2>&1) <("$BIN" --root "$ROOTS/docs-violating" 2>&1) >/dev/null; then
  printf 'ok    %-34s\n' 'deterministic-across-runs'
else
  printf 'FAIL  %-34s two runs differ\n' 'deterministic-across-runs'
  fail=$((fail+1))
fi

printf '\nchecked=%s failed=%s\n' "$checked" "$fail"
[ "$fail" -eq 0 ] || exit 1
exit 0
