#!/usr/bin/env bash
# Fixture check for bin/skill-registry.
#
# Asserts ONE expected FLAG per fixture, plus the description text for the legal
# folded scalar — so a detector that mis-routes a folded/block scalar is a failing
# case, not a silent gap. Runs the real command over BOTH fixture roots.
#
# Read-only. Exit 0 = every fixture is inventoried as expected.
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
BIN="${SKILL_REGISTRY_BIN:-$HERE/../../bin/skill-registry}"
ROOT="$HERE/roots"

fail=0
checked=0

[ -x "$BIN" ] || { printf 'skill-registry suite: bin not executable: %s\n' "$BIN" >&2; exit 3; }
[ -d "$ROOT/valid" ] && [ -d "$ROOT/defective" ] || { printf 'skill-registry suite: fixture roots missing under %s\n' "$ROOT" >&2; exit 3; }

# run_case <fixture-dir-name> <expected-flag> [expected-desc-substring]
run_case() {
  local name="$1" expected_flag="$2" expected_desc="${3:-}" out flag desc
  out=$("$BIN" --root "$ROOT" 2>/dev/null | awk -v n="$name" '$0 ~ ("PATH: .*/" n "/SKILL.md$") { show=1 } show { print } /^FLAG:/ && show { show=0 }')
  flag=$(printf '%s\n' "$out" | sed -n 's/^FLAG: //p')
  desc=$(printf '%s\n' "$out" | sed -n 's/^DESC: //p')
  checked=$((checked + 1))
  if [ "$flag" = "$expected_flag" ]; then
    if [ -n "$expected_desc" ] && [ -n "$desc" ] && [ "$desc" != "-" ] && ! printf '%s' "$desc" | grep -qF "$expected_desc"; then
      printf 'FAIL   %-30s FLAG ok but DESC "%s" lacks "%s"\n' "$name" "$desc" "$expected_desc"
      fail=$((fail + 1))
    else
      printf 'OK     %-30s FLAG: %s\n' "$name" "$flag"
    fi
  else
    printf 'FAIL   %-30s expected FLAG %s, got: %s\n' "$name" "$expected_flag" "$flag"
    fail=$((fail + 1))
  fi
}

# valid/ — healthy skills must inventory as ok
run_case fixture-valid-tagged     ok
run_case fixture-valid-quoted     ok
run_case fixture-tags-quoted       ok
run_case fixture-crlf              ok
# legal folded scalar, multi-line body: DESC must be the first line + "…" (a preview).
# This pins the truncation contract: a detector printing only the first line (no "…"),
# the bare indicator, or a wrong first line, fails here.
run_case fixture-folded-legal      ok   "A folded scalar with a real body — legal YAML whose description is this text, exactly…"

# defective/ — each shape must be flagged with its marker
run_case fixture-block-scalar        BLOCK-SCALAR
run_case fixture-block-indicator     BLOCK-SCALAR
run_case fixture-block-trailing-comment BLOCK-SCALAR
run_case fixture-missing-description MISSING-DESCRIPTION
run_case fixture-multiline-continuation MULTILINE-SCALAR
run_case fixture-plain-continuation  MULTILINE-SCALAR
run_case fixture-no-frontmatter      NO-FRONTMATTER
run_case fixture-unclosed-frontmatter UNCLOSED-FRONTMATTER

printf 'skill-registry: %d cases, %d failures\n' "$checked" "$fail"
[ "$fail" -eq 0 ] && [ "$checked" -gt 0 ]
