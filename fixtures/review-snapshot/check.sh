#!/usr/bin/env bash
# Fixture check for bin/review-snapshot: takes a snapshot, proves a content change is
# reported as MISMATCH, and proves a content-PRESERVING commit still MATCHES (the property
# that keeps a legitimate rebase/amend/squash from being blocked).
#
# Builds a throwaway repository under $TMPDIR (never inside this repo). Read-only w.r.t.
# this repo.
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SNAP="$HERE/../../bin/review-snapshot"
WS=$(mktemp -d "${TMPDIR:-/tmp}/review-snapshot-fixtures-XXXXXX") || exit 1
trap 'rm -rf "$WS"' EXIT

fail=0
checked=0

D="$WS/repo"
mkdir -p "$D"
(
  cd "$D" || exit 1
  git init -q -b main
  git config user.email "fixture@example.com"
  git config user.name "fixture"
  printf 'baseline\n' > baseline.txt
  git add -A
  git commit -q -m "chore: baseline"
  git checkout -q -b work
  printf 'feature\n' > feature.txt
  git add -A
  git commit -q -m "feat: feature"
)

case_ok() {
  local case="$1" detail="$2"
  checked=$((checked + 1))
  printf 'OK     %-38s %s\n' "$case" "$detail"
}

case_fail() {
  local case="$1" detail="$2"
  checked=$((checked + 1))
  fail=$((fail + 1))
  printf 'FAIL   %-38s %s\n' "$case" "$detail"
}

# 1. snapshot writes a complete manifest
out=$(cd "$D" && "$SNAP" --base main --out "$WS/snap.json" 2>&1); rc=$?
if [ "$rc" -eq 0 ] && grep -q '"fingerprint"' "$WS/snap.json" && grep -q '"diffHash"' "$WS/snap.json" && grep -q '"base"' "$WS/snap.json"; then
  case_ok "snapshot written" "exit=0, keys present"
else
  case_fail "snapshot written" "exit=$rc, manifest: $(head -c 200 "$WS/snap.json" 2>/dev/null)"
fi

# 2. MATCH on the unchanged tree
out=$(cd "$D" && "$SNAP" --compare "$WS/snap.json" 2>&1); rc=$?
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q '^MATCH'; then
  case_ok "MATCH on unchanged tree" "exit=0"
else
  case_fail "MATCH on unchanged tree" "exit=$rc output=$(printf '%s' "$out" | head -n 2 | tr '\n' '|')"
fi

# 3. MISMATCH after a real content change, naming the fingerprint that diverged
printf 'changed content\n' >> "$D/feature.txt"
out=$(cd "$D" && "$SNAP" --compare "$WS/snap.json" 2>&1); rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q '^MISMATCH fingerprint'; then
  snapval=$(printf '%s' "$out" | sed -n 's/^MISMATCH fingerprint *snapshot=\([^ ]*\).*/\1/p')
  curval=$(printf '%s' "$out" | sed -n 's/.*current=\([^ ]*\).*/\1/p')
  if [ -n "$snapval" ] && [ -n "$curval" ] && [ "$snapval" != "$curval" ]; then
    case_ok "MISMATCH after content change" "both fingerprints named"
  else
    case_fail "MISMATCH after content change" "did not name both values"
  fi
else
  case_fail "MISMATCH after content change" "exit=$rc output=$(printf '%s' "$out" | head -n 2 | tr '\n' '|')"
fi

# 4. committing the changed content does not change the verdict: still MISMATCH
(
  cd "$D" || exit 1
  git add -A
  git commit -q -m "chore: commit the change (history moves, content differs)"
)
out=$(cd "$D" && "$SNAP" --compare "$WS/snap.json" 2>&1); rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q '^MISMATCH'; then
  case_ok "committing changed content stays MISMATCH" "history move did not flip the verdict"
else
  case_fail "committing changed content stays MISMATCH" "exit=$rc output=$(printf '%s' "$out" | head -n 2 | tr '\n' '|')"
fi

# 5. the real property: restore the content, commit it, and the snapshot MATCHES again —
# a legitimate history rewrite that preserves content must never be blocked.
printf 'feature\n' > "$D/feature.txt"
(cd "$D" && git add -A && git commit -q -m "revert: content back to the snapshotted state")
out=$(cd "$D" && "$SNAP" --compare "$WS/snap.json" 2>&1); rc=$?
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q '^MATCH'; then
  case_ok "identical content after commits MATCHES" "exit=0 across commits (content-preserving rewrite not blocked)"
else
  case_fail "identical content after commits MATCHES" "exit=$rc output=$(printf '%s' "$out" | head -n 2 | tr '\n' '|')"
fi

# 6. cannot assess on a missing snapshot, never a false MATCH
out=$(cd "$D" && "$SNAP" --compare "$WS/nope.json" 2>&1); rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'cannot assess'; then
  case_ok "missing snapshot cannot assess" "exit=$rc"
else
  case_fail "missing snapshot cannot assess" "exit=$rc output=$(printf '%s' "$out" | head -n 1)"
fi

# 6b. a FORGED manifest (correct fingerprint, wrong base + wrong diff hash) must NOT match:
# the two fields that say WHAT was reviewed are re-checked, not just the content hash.
(
  cd "$D" || exit 1
  git checkout -q -b forged-probe 2>/dev/null || true
)
REAL_FP=$(cd "$D" && "$SNAP" --base main --out "$WS/forged-real.json" >/dev/null 2>&1; sed -n 's/.*"fingerprint": "\([^"]*\)".*/\1/p' "$WS/forged-real.json")
printf '{"base":"main","head":"0000000000000000000000000000000000000000","fingerprint":"%s","diffHash":"ffffffffffffffffffffffffffffffffffffffff"}\n' "$REAL_FP" > "$WS/forged.json"
out=$(cd "$D" && "$SNAP" --compare "$WS/forged.json" 2>&1); rc=$?
if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'MISMATCH diffHash'; then
  case_ok "forged diffHash is rejected" "exit=1, names diffHash"
else
  case_fail "forged diffHash is rejected" "exit=$rc output=$(printf '%s' "$out" | head -n 2 | tr '\n' '|')"
fi

# 6c. a manifest whose recorded base is a DIFFERENT ref than the reviewed one must not MATCH:
# the base is re-verified and the diff hash is recomputed from it.
printf '{"base":"%s","head":"0000000000000000000000000000000000000000","fingerprint":"%s","diffHash":"%s"}\n' \
  "nosuchref" "$REAL_FP" "$(sed -n 's/.*"diffHash": "\([^"]*\)".*/\1/p' "$WS/forged-real.json")" > "$WS/wrong-base.json"
out=$(cd "$D" && "$SNAP" --compare "$WS/wrong-base.json" 2>&1); rc=$?
if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -q 'does not resolve'; then
  case_ok "an unresolvable base cannot assess" "exit=2 (never MATCH)"
else
  case_fail "an unresolvable base cannot assess" "exit=$rc output=$(printf '%s' "$out" | head -n 2 | tr '\n' '|')"
fi

# 6d. writing a snapshot inside the repo unignored must be refused, not silently break the
# fingerprint it records.
out=$(cd "$D" && "$SNAP" --base main --out "$D/reports/not-ignored.json" 2>&1); rc=$?
if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -q 'NOT gitignored'; then
  case_ok "unignored in-repo --out refused" "exit=2, names the missing entry"
else
  case_fail "unignored in-repo --out refused" "exit=$rc output=$(printf '%s' "$out" | head -n 1)"
fi

# 7. repository untouched by the tool
before="$(cd "$D" && git status --porcelain | sort | shasum) $(cd "$D" && git rev-parse HEAD)"
(cd "$D" && "$SNAP" --base main --out "$WS/snap2.json" >/dev/null 2>&1)
after="$(cd "$D" && git status --porcelain | sort | shasum) $(cd "$D" && git rev-parse HEAD)"
if [ "$before" = "$after" ]; then
  case_ok "repository untouched" "git status + HEAD unchanged"
else
  case_fail "repository untouched" "git status or HEAD changed"
fi

printf '\nchecked=%s failures=%s\n' "$checked" "$fail"
exit "$fail"
