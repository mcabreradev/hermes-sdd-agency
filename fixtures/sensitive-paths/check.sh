#!/usr/bin/env bash
# Fixture check for the sensitive-path deny list (rules/project-boundaries.md).
# Exercises the exact grep documented in rules/quality.md against fixed path lists and
# asserts the verdict: the deny-listed path matches, the ordinary paths do not.
#
# Read-only. Exit 0 = the check behaves as specified.
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)

# The command as documented in rules/quality.md ("Sensitive-path check (reviewer)").
DENY_RE='(^|/)(\.ssh/|\.env)|\.(pem|key|p12|pfx)$|/secrets/|\.aws/credentials|\.credentials/|gh/hosts\.yml|Library/Keychains/'

fail=0
checked=0

run_case() {
  # $1 = file name, $2 = expected "match" | "clean"
  local file="$HERE/$1" expected="$2" out
  out=$(grep -nE "$DENY_RE" "$file" || true)
  checked=$((checked + 1))
  if [ "$expected" = "match" ]; then
    if [ -n "$out" ]; then
      printf 'MATCH  %s\n' "$1"
    else
      printf 'FAIL   %s — expected a MATCH, grep returned nothing\n' "$1"
      fail=1
    fi
  else
    if [ -z "$out" ]; then
      printf 'CLEAN  %s\n' "$1"
    else
      printf 'FAIL   %s — expected CLEAN, grep returned:\n%s\n' "$1" "$out"
      fail=1
    fi
  fi
}

run_case "deny-list-match.txt" match
run_case "ordinary-paths.txt" clean

printf '\nchecked=%s failures=%s\n' "$checked" "$fail"
exit "$fail"
