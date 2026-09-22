#!/usr/bin/env bash
# Fixture check for bin/run-trace: asserts the reader against a sample log with a done,
# a blocked and a parked entry, and against the honesty contract (missing file and
# unparsable line must be reported, never read as an empty run).
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
TRACE="$HERE/../../bin/run-trace"
SAMPLE="$HERE/sample.jsonl"
WS=$(mktemp -d "${TMPDIR:-/tmp}/run-trace-fixtures-XXXXXX") || exit 1
trap 'rm -rf "$WS"' EXIT

fail=0
checked=0

out=$(bash "$TRACE" --file "$SAMPLE" 2>&1); rc=$?
checked=$((checked + 1))
if [ "$rc" -eq 0 ] \
   && printf '%s' "$out" | grep -q '^run: run-20260919T051200Z' \
   && printf '%s' "$out" | grep -q '^change: add-authentication' \
   && printf '%s' "$out" | grep -q '^entries: 3'; then
  printf 'OK     %-40s run/change/entries header\n' "sample log summarized"
else
  printf 'FAIL   %-40s rc=%s out=%s\n' "sample log summarized" "$rc" "$(printf '%s' "$out" | head -n 3 | tr '\n' '|')"
  fail=$((fail + 1))
fi

# each of the three kinds is reported with its status
checked=$((checked + 1))
if printf '%s' "$out" | grep -q 'kind=closed' && printf '%s' "$out" | grep -q 'status=done' \
   && printf '%s' "$out" | grep -q 'status=blocked' && printf '%s' "$out" | grep -q 'kind=parked.*status=needs-context'; then
  printf 'OK     %-40s done/blocked/parked all present\n' "three entry kinds"
else
  printf 'FAIL   %-40s out=%s\n' "three entry kinds" "$(printf '%s' "$out" | grep -E 'kind=|last:' | tr '\n' '|')"
  fail=$((fail + 1))
fi

# blockers and decisions surface (the audit payload)
checked=$((checked + 1))
if printf '%s' "$out" | grep -q 'token_expires_at'; then
  printf 'OK     %-40s decision/blocker surfaced\n' "parked decision surfaced"
else
  printf 'FAIL   %-40s out=%s\n' "parked decision surfaced" "$(printf '%s' "$out" | tail -n 4 | tr '\n' '|')"
  fail=$((fail + 1))
fi

# last entry is the resume point (parked)
checked=$((checked + 1))
if printf '%s' "$out" | grep -q 'stage: autonomous-change  kind: parked  status: needs-context'; then
  printf 'OK     %-40s last entry is the parked resume point\n' "resume point reported"
else
  printf 'FAIL   %-40s out=%s\n' "resume point reported" "$(printf '%s' "$out" | grep '^  stage:' | tr '\n' '|')"
  fail=$((fail + 1))
fi

# class and trust surface per entry (the blocker-classification + trust payload)
checked=$((checked + 1))
if printf '%s' "$out" | grep -q 'trust=verified' && printf '%s' "$out" | grep -q 'trust=blocked' \
   && printf '%s' "$out" | grep -q '"class":"decision"'; then
  printf 'OK     %-40s trust + blocker class surfaced\n' "class/trust surfaced"
else
  printf 'FAIL   %-40s out=%s\n' "class/trust surfaced" "$(printf '%s' "$out" | grep -E 'trust=|class=' | tr '\n' '|')"
  fail=$((fail + 1))
fi

# determinism
checked=$((checked + 1))
if diff <(bash "$TRACE" --file "$SAMPLE" 2>&1) <(bash "$TRACE" --file "$SAMPLE" 2>&1) >/dev/null; then
  printf 'OK     %-40s byte-identical across runs\n' "deterministic"
else
  printf 'FAIL   %-40s two runs differ\n' "deterministic"
  fail=$((fail + 1))
fi

# honesty: a missing log is a missing input, not an empty run
checked=$((checked + 1))
out=$(bash "$TRACE" --file "$WS/none.jsonl" 2>&1); rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -qi 'no such run log'; then
  printf 'OK     %-40s missing file named, exit non-zero\n' "missing log is a missing input"
else
  printf 'FAIL   %-40s rc=%s out=%s\n' "missing log is a missing input" "$rc" "$(printf '%s' "$out" | head -n 2 | tr '\n' '|')"
  fail=$((fail + 1))
fi

# honesty: a broken line voids the summary, never a silent skip
printf '{"runId":"run-x","stage":"a","kind":"closed"}\nNOT-JSON\n' > "$WS/broken.jsonl"
checked=$((checked + 1))
out=$(bash "$TRACE" --file "$WS/broken.jsonl" 2>&1); rc=$?
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -qi 'not valid JSON\|refusing to summarize'; then
  printf 'OK     %-40s broken line named, summary refused\n' "unparsable line voids the summary"
else
  printf 'FAIL   %-40s rc=%s out=%s\n' "unparsable line voids the summary" "$rc" "$(printf '%s' "$out" | tail -n 2 | tr '\n' '|')"
  fail=$((fail + 1))
fi

# honesty: no --file
checked=$((checked + 1))
out=$(bash "$TRACE" 2>&1); rc=$?
if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -qi 'requires a path\|--file is required'; then
  printf 'OK     %-40s exits 2 with usage\n' "no --file"
else
  printf 'FAIL   %-40s rc=%s out=%s\n' "no --file" "$rc" "$(printf '%s' "$out" | head -n 2 | tr '\n' '|')"
  fail=$((fail + 1))
fi

printf '\nchecked=%s failures=%s\n' "$checked" "$fail"
exit "$fail"
