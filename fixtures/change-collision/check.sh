#!/usr/bin/env bash
# Fixture check for bin/change-collision: builds throwaway git repos under $TMPDIR
# (never inside this repo) and asserts the verdict + exit contract for each shape the
# detector must tell apart.
#
# Each case is a real repo: a baseline commit, then branch A and branch B with scripted
# file sets — so the bin exercises the real `git diff --name-only` path, not a mock.
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
BIN="$HERE/../../bin/change-collision"
WS=$(mktemp -d "${TMPDIR:-/tmp}/change-collision-fixtures-XXXXXX") || exit 1
trap 'rm -rf "$WS"' EXIT

fail=0
checked=0

# make_repo <name> — a git repo with a baseline commit on main.
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

# branch_commit <dir> <name> <files...> — create <name> off main and commit the listed
# files (each with a distinct line) onto it.
branch_commit() {
  local dir="$1" name="$2"
  shift 2
  (
    cd "$dir" || exit 1
    git checkout -q -b "$name" main
    local f
    for f in "$@"; do
      mkdir -p "$(dirname "$f")"
      printf '%s content\n' "$f" >> "$f"
    done
    git add -A
    git commit -q -m "work: $name"
  )
}

assert_verdict() {
  local case="$1" dir="$2" expected="$3" out rc ok_rc
  out=$(cd "$dir" && "$BIN" --base main --a a --b b 2>&1); rc=$?
  checked=$((checked + 1))
  # Precedence trap: in bash, `A && B || C && D` chains as `((A&&B)||C)&&D`, not
  # `(A&&B)||(C&&D)` — the trailing `&& [ rc -eq 0 ]` eats the cannot-assess case.
  if [ "$expected" = "cannot assess" ]; then
    if [ "$rc" -ne 0 ]; then ok_rc=1; else ok_rc=0; fi
  else
    if [ "$rc" -eq 0 ]; then ok_rc=1; else ok_rc=0; fi
  fi
  if printf '%s' "$out" | grep -q "verdict: $expected" && [ "$ok_rc" -eq 1 ]; then
    printf 'OK     %-44s verdict=%s rc=%s\n' "$case" "$expected" "$rc"
  else
    printf 'FAIL   %-44s expected=%s rc=%s out=%s\n' "$case" "$expected" "$rc" "$(printf '%s' "$out" | head -n 3 | tr '\n' '|')"
    fail=$((fail + 1))
  fi
}

# --- disjoint file sets → parallelizable -----------------------------------------
D=$(make_repo disjoint)
branch_commit "$D" a src/auth/login.ts
branch_commit "$D" b src/events/notify.ts
assert_verdict "disjoint file sets" "$D" "parallelizable"

# --- shared path → collision -----------------------------------------------------
D=$(make_repo shared-path)
branch_commit "$D" a src/shared/service.ts
branch_commit "$D" b src/shared/service.ts
assert_verdict "shared path" "$D" "collision"

# --- schema vs migrations, no literal overlap → collision (family) ---------------
D=$(make_repo family)
branch_commit "$D" a prisma/schema.prisma
branch_commit "$D" b prisma/migrations/0002_x/up.sql
assert_verdict "schema vs migrations (family)" "$D" "collision"

# --- empty diff on B → cannot assess, non-zero ------------------------------------
D=$(make_repo empty-b)
branch_commit "$D" a src/auth/login.ts
# b is created but carries nothing beyond main's baseline? No — create it anyway:
( cd "$D" && git checkout -q -b b main )
assert_verdict "empty diff (b == base)" "$D" "cannot assess"

# --- unknown base ref → cannot assess ----------------------------------------------
D=$(make_repo bad-base)
branch_commit "$D" a src/x.ts
branch_commit "$D" b src/y.ts
out=$(cd "$D" && "$BIN" --base nosuchref --a a --b b 2>&1); rc=$?
checked=$((checked + 1))
if printf '%s' "$out" | grep -qi 'unknown base ref' && [ "$rc" -eq 2 ]; then
  printf 'OK     %-44s ref named, exit 2\n' "unknown base ref"
else
  printf 'FAIL   %-44s rc=%s out=%s\n' "unknown base ref" "$rc" "$(printf '%s' "$out" | head -n 2 | tr '\n' '|')"
  fail=$((fail + 1))
fi

# --- determinism -------------------------------------------------------------------
D=$(make_repo deterministic)
branch_commit "$D" a src/a1.ts
branch_commit "$D" b src/b1.ts
checked=$((checked + 1))
if diff <(cd "$D" && "$BIN" --base main --a a --b b 2>&1) \
        <(cd "$D" && "$BIN" --base main --a a --b b 2>&1) >/dev/null; then
  printf 'OK     %-44s byte-identical across runs\n' "deterministic"
else
  printf 'FAIL   %-44s two runs differ\n' "deterministic"
  fail=$((fail + 1))
fi

# --- read-only ---------------------------------------------------------------------
before="$(cd "$D" && git status --porcelain | sort | shasum) $(cd "$D" && git rev-parse HEAD)"
(cd "$D" && "$BIN" --base main --a a --b b >/dev/null 2>&1)
after="$(cd "$D" && git status --porcelain | sort | shasum) $(cd "$D" && git rev-parse HEAD)"
checked=$((checked + 1))
if [ "$before" = "$after" ]; then
  printf 'OK     %-44s tree and HEAD unchanged\n' "read-only"
else
  printf 'FAIL   %-44s something changed\n' "read-only"
  fail=$((fail + 1))
fi

printf '\nchecked=%s failures=%s\n' "$checked" "$fail"
exit "$fail"
