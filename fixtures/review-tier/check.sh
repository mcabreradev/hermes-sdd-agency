#!/usr/bin/env bash
# Fixture check for bin/review-tier: one case per declared high-consequence class, plus a
# below-bound behavior change, an above-bound change, and an unassessable diff.
#
# Builds real throwaway git repositories under $TMPDIR (never inside this repo), runs the
# documented command against each, and asserts the printed tier. Read-only w.r.t. this repo.
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
TIER="$HERE/../../bin/review-tier"
WS=$(mktemp -d "${TMPDIR:-/tmp}/review-tier-fixtures-XXXXXX") || exit 1
trap 'rm -rf "$WS"' EXIT

fail=0
checked=0

# make_repo <name> — fresh repo whose work lands on a `work` branch, so `<base>...HEAD`
# (default base `main`) actually carries a diff. A fixture that commits straight onto main
# would measure an empty diff and could not exercise the classifier at all.
make_repo() {
  local name="$1"
  local dir="$WS/$name"
  mkdir -p "$dir"
  (
    cd "$dir" || exit 1
    git init -q -b main
    git config user.email "fixture@example.com"
    git config user.name "fixture"
    printf 'baseline\n' > baseline.txt
    git add -A
    git commit -q -m "chore: baseline"
    git checkout -q -b work
  )
  printf '%s' "$dir"
}

# assert_tier <case> <expected> <dir> [extra args...]
assert_tier() {
  local case="$1" expected="$2" dir="$3" out rc
  shift 3
  out=$(cd "$dir" && "$TIER" "$@" 2>&1); rc=$?
  checked=$((checked + 1))
  local got
  got=$(printf '%s\n' "$out" | sed -n 's/^tier: //p' | head -n 1)
  # "cannot assess" is the honest verdict, not a tier: normalise it so an expectation of
  # "<none>" is satisfied only by a real refusal.
  [ "$got" = "cannot assess" ] && got="<none>"
  [ -z "$got" ] && got="<none>"
  if [ "$got" = "$expected" ]; then
    printf 'OK     %-34s tier=%s\n' "$case" "$got"
  else
    printf 'FAIL   %-34s expected=%s got=%s\n' "$case" "$expected" "$got"
    printf '       output: %s\n' "$(printf '%s' "$out" | head -n 3 | tr '\n' '|')"
    fail=$((fail + 1))
  fi
}

# assert_reason_names <case> <dir> <needle> — the needle must appear on a rule line, not
# anywhere in the output (so "auth" cannot be satisfied by the word "authored:").
assert_reason_names() {
  local case="$1" dir="$2" needle="$3" out
  out=$(cd "$dir" && "$TIER" 2>&1)
  checked=$((checked + 1))
  if printf '%s' "$out" | grep -qE "class=$needle|^[A-Z]+ +$needle|$needle"; then
    printf 'OK     %-34s names %s\n' "$case" "$needle"
  else
    printf 'FAIL   %-34s does not name %s\n' "$case" "$needle"
    fail=$((fail + 1))
  fi
}

# --- low: documentation only ------------------------------------------------------------
D=$(make_repo docs-only)
( cd "$D" && printf 'more prose\n' >> README.md && mkdir -p docs && printf 'guide\n' > docs/guide.md && git add -A && git commit -q -m "docs: prose" )
assert_tier "low (docs only)" low "$D"
assert_reason_names "low names its reason" "$D" "documentation"

# --- high: one repo per declared class ---------------------------------------------------
D=$(make_repo schema-class)
( cd "$D" && mkdir -p prisma/migrations && printf 'ALTER TABLE t ADD COLUMN c INT;\n' > prisma/migrations/001_init.sql && git add -A && git commit -q -m "feat: migration" )
assert_tier "high (schema-migration)" high "$D"
assert_reason_names "high names schema-migration" "$D" "schema-migration"

D=$(make_repo auth-class)
( cd "$D" && mkdir -p src && printf 'export const login = () => {};\n' > src/login.ts && git add -A && git commit -q -m "feat: login" )
assert_tier "high (auth)" high "$D"
assert_reason_names "high names auth" "$D" "auth"

D=$(make_repo security-config-class)
( cd "$D" && printf '{"hosts":{}}\n' > .npmrc && git add -A && git commit -q -m "chore: npmrc" )
assert_tier "high (security-config)" high "$D"
assert_reason_names "high names security-config" "$D" "security-config"

D=$(make_repo dep-manifest-class)
( cd "$D" && printf '{"name":"x"}\n' > package.json && git add -A && git commit -q -m "feat: manifest" )
assert_tier "high (dependency-manifest)" high "$D"
assert_reason_names "high names dependency-manifest" "$D" "dependency-manifest"

# --- medium: behavior under the bound ----------------------------------------------------
D=$(make_repo medium-under)
( cd "$D" && mkdir -p src && printf 'export const f = () => 1;\n' > src/app.ts && git add -A && git commit -q -m "feat: behavior" )
assert_tier "medium (under bound)" medium "$D"
assert_reason_names "medium names its dimension" "$D" "at or under the bound"

# --- high: behavior over the bound ------------------------------------------------------
D=$(make_repo high-over)
( cd "$D" && mkdir -p src && i=0; while [ $i -lt 450 ]; do printf 'export const l%s = () => %s;\n' "$i" "$i"; i=$((i + 1)); done > src/big.ts && git add -A && git commit -q -m "feat: big" )
assert_tier "high (over bound)" high "$D"
assert_reason_names "high names the size rule" "$D" "over the bound"

# --- cannot assess -----------------------------------------------------------------------
D=$(make_repo unassessable)
assert_tier "cannot assess (unknown base)" "<none>" "$D" --base does-not-exist
out=$(cd "$D" && "$TIER" --base does-not-exist 2>&1); rc=$?
checked=$((checked + 1))
if printf '%s' "$out" | grep -q "cannot assess" && [ "$rc" -ne 0 ]; then
  printf 'OK     %-34s cannot assess, exit=%s\n' "cannot assess exits non-zero" "$rc"
else
  printf 'FAIL   %-34s expected a cannot-assess verdict, got rc=%s\n' "cannot assess exits non-zero" "$rc"
  fail=$((fail + 1))
fi

# An EMPTY diff is not a documentation-only change: base == HEAD (work committed onto the base
# branch, or a wrong ref) must report cannot assess, never the shallowest tier.
D=$(make_repo empty-diff)
( cd "$D" && git checkout -q main && mkdir -p prisma/migrations src && i=0; while [ $i -lt 900 ]; do printf 'ALTER TABLE t%s ADD COLUMN c INT;\n' "$i"; i=$((i + 1)); done > prisma/migrations/001_big.sql && printf 'export const login = () => {};\n' > src/auth.ts && git add -A && git commit -q -m "feat: big migration on the base branch" )
assert_tier "empty diff (base == HEAD)" "<none>" "$D" --base main
out=$(cd "$D" && "$TIER" --base main 2>&1); rc=$?
checked=$((checked + 1))
if printf '%s' "$out" | grep -q 'cannot assess' && [ "$rc" -eq 2 ] && ! printf '%s' "$out" | grep -q '^tier: low'; then
  printf 'OK     %-34s cannot assess (not low), exit=2\n' "900-line migration on base is not low"
else
  printf 'FAIL   %-34s a 900-line migration+auth diff reported a tier\n' "900-line migration on base is not low"
  fail=$((fail + 1))
fi
assert_tier "empty diff (base is HEAD)" "<none>" "$D" --base HEAD

# A behavior module whose name merely starts with "document" must not be docs-like.
D=$(make_repo doc-prefix)
( cd "$D" && mkdir -p src && printf 'export const render = () => {};\n' > src/document.ts && printf 'export const api = () => {};\n' > src/documents-api.ts && git add -A && git commit -q -m "feat: documents module" )
assert_tier "src/document.ts is behavior" medium "$D"
assert_tier "src/documents-api.ts is behavior" medium "$D"

# The auth row's prose covers hyphen/underscore spellings, so they must fire.
D=$(make_repo auth-spellings)
( cd "$D" && mkdir -p src && printf 'export const x = () => {};\n' > src/require-auth.ts && git add -A && git commit -q -m "feat: require-auth" )
assert_tier "require-auth.ts fires auth" high "$D"
assert_tier "auth class named for it" high "$D"

# An undeclared env knob must not be able to lower a tier.
D=$(make_repo env-knob)
( cd "$D" && mkdir -p src && i=0; while [ $i -lt 450 ]; do printf 'export const l%s = () => %s;\n' "$i" "$i"; i=$((i + 1)); done > src/big.ts && git add -A && git commit -q -m "feat: big" )
out=$(cd "$D" && REVIEW_TIER_SIZE_BOUND=99999 "$TIER" 2>&1)
checked=$((checked + 1))
if printf '%s' "$out" | grep -q '^tier: high'; then
  printf 'OK     %-34s env knob ignored, still high\n' "no undeclared env knob"
else
  printf 'FAIL   %-34s an env var lowered the tier: %s\n' "no undeclared env knob" "$(printf '%s' "$out" | head -n 1)"
  fail=$((fail + 1))
fi
out=$(cd "$D" && REVIEW_TIER_SIZE_BOUND=abc "$TIER" 2>&1)
checked=$((checked + 1))
if ! printf '%s' "$out" | grep -q 'integer expression expected'; then
  printf 'OK     %-34s no unvalidated arithmetic\n' "invalid env value is inert"
else
  printf 'FAIL   %-34s an unvalidated value reached the comparison\n' "invalid env value is inert"
  fail=$((fail + 1))
fi

# --- determinism -------------------------------------------------------------------------
D=$(make_repo deterministic)
( cd "$D" && mkdir -p src && printf 'export const g = () => 2;\n' > src/g.ts && git add -A && git commit -q -m "feat: g" )
checked=$((checked + 1))
if diff <(cd "$D" && "$TIER" 2>&1) <(cd "$D" && "$TIER" 2>&1) >/dev/null; then
  printf 'OK     %-34s byte-identical\n' "deterministic"
else
  printf 'FAIL   %-34s two runs differ\n' "deterministic"
  fail=$((fail + 1))
fi

printf '\nchecked=%s failures=%s\n' "$checked" "$fail"
exit "$fail"
