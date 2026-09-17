# Change-artifact validity traps that block the gate

`openspec validate "<change>" --type change` is necessary, not sufficient. It checks structure, not
whether the delta says what the author meant. Every trap below passes or half-passes the CLI.

## Delta vocabulary is a closed set

`ADDED` · `MODIFIED` · `REMOVED` · `RENAMED` — nothing else. An invented header such as
`## UNCHANGED Requirements` validates clean and is **skipped by everything**: the requirements under
it appear in no `validate`, `list` or `archive` output, so a change can look green while its central
invariant (usually "no breaking API changes") does not exist as a requirement at all.

```bash
# any line printed below is an inert delta
grep -rn '^## [A-Z]* Requirements' openspec/changes/*/specs/*/spec.md \
  | grep -vE 'ADDED|MODIFIED|REMOVED|RENAMED'
```

Fix: state the invariant as `## ADDED`, or carry the existing requirement into the delta as
`## MODIFIED`. Do not grep the installed CLI's `dist/` for the token list to prove the vocabulary —
the strings live in bundled chunks and finding nothing proves nothing.

## Every requirement needs a `#### Scenario:` with WHEN/THEN

A requirement stating an invariant, an internal-alias rule, or a rationale is not exempt: it fails
with `must include at least one scenario` (ERROR) and the change cannot archive. The same requirement
usually also carries a WARNING about missing RFC-2119 SHALL/MUST — read every `issues[]` entry, not
the first one or the exit code.

## `## MODIFIED` needs a target that exists in the main spec

The main spec is `openspec/specs/<cap>/spec.md`. A delta under `changes/<name>/specs/` is a *change*,
never a target. When `openspec/specs/` is empty (a package whose capabilities were never archived),
every requirement must be `## ADDED`: a `## MODIFIED` aimed at a capability that exists only as a
delta is not a modification, and archiving then materializes the whole delta as the new main spec.

The converse is the trap for rewrites and migrations. When the change's job is to *preserve* a
contract that already ships, write the existing capability first (`## Purpose` + `## Requirements`),
validate it, then carry it into the delta as `## MODIFIED`. Never invent a capability to satisfy the
token. `validate` does not verify MODIFIED targets — that surfaces only as an
`ℹ [INFO] ... Archive would refuse this delta` line.

## A valid change is not an implemented change

`validate` only says the artifact is well-formed. The gate for `implement-change` is
`openspec instructions apply --change "<name>" --json` returning `state: ready`, and the artifacts
have to be tracked by git: an untracked `openspec/changes/**` leaves the repo dirty and blocks
`release-change` regardless of how clean the change validates.
