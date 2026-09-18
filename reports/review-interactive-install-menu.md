# Review — interactive-install-menu

- **Date:** 2026-09-18
- **Project root:** /Users/migue/Workspace/migue/hermes-sdd-agency-worktrees/install-interactive-menu
- **Diff base:** HEAD (cb6fd25)
- **Scope:** install.sh (+395), INSTALL.md, README.md, openspec/changes/interactive-install-menu/tasks.md
- **Verdict:** approved (after 3 MAJOR findings fixed by Hermes and re-verified in a real pty)

## Evidence

```
$ bash -n install.sh && echo OK
OK
$ echo | ./install.sh --dry-run          # non-interactive, parity vs HEAD: IDENTICAL
$ echo | ./install.sh --dry-run --bundles agency,fix   # parity: IDENTICAL
$ echo | ./install.sh -p <existing-agency>             # guard abort, parity: IDENTICAL (exit 1)
pty: ESC → "aborted by user — nothing was installed", exit 1, termios restored
pty: uppercase filter 'AGENCY' → matches agency row (was broken)   [MAJOR-1 fixed]
pty: '/tmp/my home' → preserved space in prefix            (was broken)   [MAJOR-2 fixed]
pty: filter→Select All→space(deselect all)→Enter×2 → stays in bundles phase (no advance) [MAJOR-3 fixed]
pty: full flow confirm Yes → installs agents + 14 bundles into scratch target (exit 0)
pty: full flow confirm default No → abort, nothing written, exit 1
```

## Spec compliance

| Requirement / Scenario | Status | Evidence |
|---|---|---|
| R1 Interactive only on TTY + flags pinned | covered | `install.sh:551` `[[ -t 0 ]]`; pinned `-p`+`--bundles` skip to confirm; non-TTY branch byte-identical |
| R2 Multi-select: search / toggle / confirm / cancel | covered | `_menu_vis` filter; space/enter/esc in `_menu_key` (ptytest: MAJOR-1/2/3) |
| R3 Summary + confirm before any write | covered | `_menu_box` + `◆ Install into`; default No aborts (smoke) |
| R4 Bash 3.2 portability | covered | `bash -n` on 3.2.57; no assoc arrays, no `${x,,}`, ANSI not tput, trap restores stty |

## Findings

### BLOCKER
- none.

### MAJOR
All three were found by the reviewer agent, fixed by Hermes, and re-verified:

- **install.sh:177** (fixed) — case-insensitive filter matched unfolded query. Fix folds the query (`folded_query`) before comparing. Verified: typing `AGENCY` now matches.
- **install.sh:388** (fixed) — space in the prefix phase was consumed by the toggle case and never typed. Fix: prefix-phase space appends a literal space. Verified: `/tmp/my home` preserved.
- **install.sh:414** (fixed) — zero-selection no-op kept the stale `key=enter` so a repeat/held Enter advanced anyway. Fix: reset `key=""` in the no-op branch. Verified: deselect-all then double Enter stays on the bundles frame.

### MINOR
- overwrite classification for "existing home data" (non-agency) uses the standard confirm, slightly weaker than ADR-0005's wording for the agency case; the summary always defaults to No so the strongest-confirm intent holds. No code change required; recommend ADR-0005 wording update.

### NIT
- Stale comment in `_menu_init` mentions `VMIN=0,VTIME=1` (code uses `-t 1`); harmless.
- Doc/code "all 12" vs `ALL_BUNDLES`=14 (historical count; unchanged default).

## Undeclared scope
- `--help` usage text gained prose about the menu; flags unchanged and semantics preserved (flag parity verified). Flag in PR if byte-parity of help was desired.

## Declared debt (can be left)
- MAJOR-1/2/3 fixes land with the change (not deferred). MINOR/NIT above left as-is (non-blocking).

## Spec questions
- none.
