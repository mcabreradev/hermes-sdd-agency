#!/usr/bin/env bash
# Fixture check for the sensitive-path deny list (rules/project-boundaries.md).
#
# Asserts ONE case per row of the deny-list table — so a table row whose pattern does not
# match is a failing case, not a silent gap — plus near-miss paths that must stay clean.
#
# Read-only. Exit 0 = every row of the table is matched by the documented pattern.
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)

# The pattern as documented in rules/quality.md ("Sensitive-path check (reviewer)").
# Kept in sync with the table in rules/project-boundaries.md row by row.
DENY_RE='(^|/)\.ssh/|(^|/)\.env[^/]*$|(^|/)secrets/|\.(pem|key|p12|pfx)$|(^|/)\.aws/credentials|(^|/)\.credentials/|(^|/)\.config/gh/hosts\.yml|(^|/)Library/Keychains/'

fail=0
checked=0

# run_case <table-row-label> <path> <match|clean>
run_case() {
  local label="$1" path="$2" expected="$3" out
  out=$(printf '%s\n' "$path" | grep -nE "$DENY_RE" || true)
  checked=$((checked + 1))
  if [ "$expected" = "match" ]; then
    if [ -n "$out" ]; then
      printf 'MATCH  %-30s %s\n' "$label" "$path"
    else
      printf 'FAIL   %-30s %s — expected MATCH, pattern did not match\n' "$label" "$path"
      fail=$((fail + 1))
    fi
  else
    if [ -z "$out" ]; then
      printf 'CLEAN  %-30s %s\n' "$label" "$path"
    else
      printf 'FAIL   %-30s %s — expected CLEAN, got: %s\n' "$label" "$path" "$out"
      fail=$((fail + 1))
    fi
  fi
}

# --- one case per row of rules/project-boundaries.md (the table is the contract) ---
run_case '~/.ssh/*'              '.ssh/id_rsa'                          match
run_case '~/.ssh/* (deep)'       'home/u/.ssh/id_ed25519'               match
run_case '**/*.pem'              'certs/server.pem'                     match
run_case '**/*.key'              'certs/server.key'                     match
run_case '**/*.p12'              'private/keystore.p12'                 match
run_case '**/*.pfx'              'private/bundle.pfx'                   match
run_case '**/.env*'              'config/.env'                          match
run_case '**/.env* (root)'       '.env'                                 match
run_case '**/.env* (local)'      'config/.env.local'                    match
run_case '**/.env* (rc)'         'config/.envrc'                        match
run_case '**/.env* (rc root)'    '.envrc.prod'                          match
run_case '**/.env* (suffix)'     'app/.env.production'                  match
run_case '**/secrets/*'          'secrets/oauth.json'                   match
run_case '**/secrets/* (nested)' 'secrets/nested/deep.json'            match
run_case '**/secrets/* (deep)'   'app/secrets/oauth.json'               match
run_case '~/.credentials/*'      '.credentials/gcloud.json'             match
run_case '~/.aws/credentials'    '.aws/credentials'                     match
run_case '~/.config/gh/hosts.yml' '.config/gh/hosts.yml'                match
run_case '~/Library/Keychains/*' 'Library/Keychains/login.keychain-db' match

# --- near misses that must NOT match (guards against an over-broad pattern) ---
run_case '(ordinary) src/app.ts'           'src/app.ts'            clean
run_case '(ordinary) rules/environment.md' 'rules/environment.md'  clean
run_case '(ordinary) src/env.ts'           'src/env.ts'            clean
run_case '(ordinary) src/secretary/api.ts' 'src/secretary/api.ts'  clean
run_case '(ordinary) docs/keys.md'         'docs/keys.md'          clean
run_case '(ordinary) openspec/specs/x/spec.md' 'openspec/specs/x/spec.md' clean

printf '\nchecked=%s failures=%s\n' "$checked" "$fail"
exit "$fail"
