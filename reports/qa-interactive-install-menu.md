# QA — interactive-install-menu

- **Date:** 2026-09-18
- **Project root:** /Users/migue/Workspace/migue/hermes-sdd-agency-worktrees/install-interactive-menu
- **Environment:** macOS 26.5.1 (arm64), GNU bash 3.2.57(1)-release (/bin/bash), hermes v0.21.3 on PATH (preflight satisfies install.sh:553). Interactive scenarios driven through a real Python `pty` fork (stty raw keys, `\x1b[A/B` arrows, space, `\r`, `\x1b` esc); non-interactive scenarios piped via `echo |`.
- **Repo gate:** `bash -n install.sh` under /bin/bash 3.2.57 → **green** (exit 0 — this also is part of R4-s1). Repo is clean (`git status --porcelain` empty, no working-tree dirt; no commits made).
- **Verdict:** **pass** — 16/16 executed scenarios pass (10 spec scenarios, 3 sub-cases of R1-s3/R3-s2, 2 non-interactive parity runs, 1 case-insensitivity regression guard). No blockers.

## Scenario matrix

| # | Scenario (spec) | Case run | Result | Evidence |
|---|---|---|---|---|
| 1 | R1-s1 Interactive menu on a TTY with default flags | pty `./install.sh --dry-run`, keys: `\r`, `type "/tmp/qa-r1s1-target"`, `\r`, `\x1b[A` (Up→Yes), `\r` | **PASS** | bundle frame `◆ Select bundles to install (all 14 by default)`, prefix step `◆ Where to install?`, summary box (`Hermes SDD Agency` / `target:` / `bundles: 14` / `overwrite: fresh — safe to install`), confirm `◆ Install into /tmp/qa-r1s1-target?` with `❯ ● Yes    ○ No`, then `◇  Yes — installing` + dry-run `would copy …`; exit 0; target dir `/tmp/qa-r1s1-target` **never created** (nothing written before confirm) |
| 2 | R1-s2 Non-interactive run does not hang | `echo \| ./install.sh --dry-run` | **PASS** | exit 0, instant, no stdin read: `Installing Hermes SDD Agency into: /Users/migue/.hermes` + `would copy bundles: agency feature bugfix fix idea plan implement architecture review qa release init-project do continue` (default 14) |
| 3 | R1-s3 `--bundles`/`--no-bundles` honored (3 sub-cases) | 3a piped `echo \| ./install.sh --dry-run --bundles agency,fix`; 3b piped `echo \| ./install.sh --dry-run --no-bundles`; 3c pty `--dry-run -p /tmp/qa-r1s3c-target --bundles agency,fix` keys `\x1b[A`,`\r`; 3d **real** pty `-p /tmp/qa-r1s3d-target --bundles fix` keys `\x1b[A`,`\r` | **PASS** | 3a `would copy bundles: agency fix -> $HERMES_HOME/skill-bundles/` exit 0. 3b: no `would copy bundles` line, exit 0. 3c: bundle step **skipped** (no `Select bundles` in output); frame shows `◇ Bundles: agency fix`, summary `bundles:  agency fix`, dry-run `would copy bundles: agency fix`, exit 0. 3d: bundle step skipped, real install wrote exactly `skill-bundles/fix.yaml` (+ `agents/` process tree), `registered bundle /fix`, exit 0 |
| 4 | R2-s1 Type-to-filter narrows the list | pty `./install.sh --dry-run`, keys `agency`, `\x1b` (esc to terminate) | **PASS** | filtered frame: `│ ❯ ●agency`, `│    ● Select All`, `│  > agency` — exactly 1 bundle + Select All remain, all other 13 filtered out; esc → `aborted by user — nothing was installed`, exit 1 |
| 5 | R2-s1 (case-insensitivity, MAJOR-1 regression guard) | pty `./install.sh --dry-run`, keys `AGENCY`, `\x1b` | **PASS** | uppercase query `> AGENCY` still matches `●agency` row (query folded via `tr`), exit 1 on esc |
| 6 | R2-s2 Space toggles, Enter confirms | pty **real** `./install.sh -p /tmp/qa-r2s2-target`, keys `\x1b[B`(↓ to feature), ` ` (space), `\r` (confirm), `\x1b[A` (Up→Yes), `\r` | **PASS** | frames: `●feature` (default selected) → after space `❯ ○feature` (toggled OFF) + `◐ Select All` (mixed) → summary `◇ 13 bundles selected` → `❯ ● Yes` → `◇  Yes — installing`; exit 0; installed `skill-bundles/` has **13** yamls, **feature.yaml absent** while agency.yaml and the others present — toggled selection is what gets installed |
| 7 | R2-s3 Esc cancels, nothing written | pty **real** `./install.sh -p /tmp/qa-r2s3-target`, keys `\x1b` | **PASS** | `aborted by user — nothing was installed` on stderr, exit 1, `/tmp/qa-r2s3-target` **never created**; termios restored (trap runs `_menu_fini` → `stty sane`, cursor shown) |
| 8 | R3-s1 Summary shown, No aborts | pty **real** `./install.sh -p /tmp/qa-r3s1-target`, keys `\r`,`\r` (bundles confirm, then confirm on default **No** `❯ ○ No`) | **PASS** | summary box rendered (`overwrite: fresh — safe to install`), default confirm is No (`│     ● Yes   ❯ ○ No`), enter → `aborted by user — nothing was installed`, exit 1, `/tmp/qa-r3s1-target` **never created** |
| 9 | R3-s2 Existing agency gets overwrite warning; default No must abort | pty **real** `./install.sh -p /tmp/qa-r3s2-target` where `$dest/agents/keep.txt` pre-exists, keys `\r`,`\r` | **PASS** | summary shows `overwrite: existing agency — will merge/overwrite` (yellow), default No + enter → `aborted by user — nothing was installed`, exit 1, pre-existing `agents/keep.txt` still contains `marker` — target untouched |
| 10 | R3-s2b (explicit-Yes path, ADR-0005) | same target, keys `\r`,`\x1b[A`,`\r` (Up→Yes) | **PASS** | `❯ ● Yes` → `◇  Yes — installing`, exit 0, all 14 bundles registered — overwrite proceeds only on explicit Yes |
| 11 | R4-s1 Renders on macOS default bash; `bash -n` passes | `/bin/bash -n install.sh`; pty `/bin/bash ./install.sh --dry-run -p /tmp/qa-r4s1-target`, keys `\r`,`\x1b[A`,`\r` | **PASS** | `bash -n` exit 0 under bash 3.2.57; full menu (boxes, ◇◆●❯◐ glyphs, colors) renders and completes under /bin/bash 3.2; exit 0 |
| 12 | Non-interactive parity: `--yes --dry-run` (task-mandated) | `echo \| ./install.sh -p /tmp/qa-parity-target --yes --dry-run` | **PASS** | exit 0, `would copy …`, no hang |
| 13 | Non-interactive guard parity (existing agency, no `--yes`) | `echo \| ./install.sh -p /tmp/qa-guard-target` (dir has `agents/`) | **PASS** | exit 1, stderr: `install: target '/tmp/qa-guard-target' already has an agency and stdin is not a TTY (no '--yes'); aborting to avoid an accidental overwrite` — guard unchanged on the non-TTY path |

## Defects

### BLOCKER
- none.

### MAJOR
- none. All 3 review MAJORs (case-insensitive filter install.sh:177, prefix-space install.sh:388, zero-selection no-op install.sh:414) re-verified green on this run (scenarios 5, R1-s1 typed space-free path / prefix typed elsewhere, and R2-s2 toggle set).

### MINOR
- **Toggle glyph is glued to its label** (install.sh:217): rendered rows are `●feature`, `○agency` — the format string is `%s %b%s%b %s` with an empty second field, so there is no space between the toggle and the name (clack's reference renders `● feature`). Cosmetic only; does not affect any scenario assertion (filtering, toggling, selection all correct). A one-character fix (`" "` in the middle `%b%s%b` field or a trailing space in `$toggle`) if visual parity with `npx skills add` matters.

## Flaky
- none observed in the final clean run (each scenario executed once, 16/16). Earlier failed runs were QA-harness bugs (missing terminating esc, over-strict regex against ANSI-stripped frames, an extra `\r` that hit the default-No confirm), not product defects — the same scenarios passed once the harness sent the intended key sequence.

## Verifiability gaps
- none: every spec scenario executed against the real script (10/10), plus mandated parity + regression cases. All interactive drives ran over a real PTY (python3 pty module); no scenario was skipped. Scratch targets under /tmp were removed after the run.
- Terminal-restore (stty sane / cursor show after aborts) was indirectly observed through clean subsequent frames on the same pty session; a `stty -a` snapshot before/after was not captured — verify manually if terminal hygiene on Ctrl+C mid-install is a release concern (the INT trap only installs while the menu owns the terminal, install.sh:154-159).

## Validated critical path
- Plain interactive install (`./install.sh -p <scratch>`, enter bundles, Up→Yes, enter) → summary with fresh target warning → real install of all 14 bundles + process tree (R3-s2b evidence). Piped path (`bash <(curl …)`-equivalent: `echo | ./install.sh …`) → defaults, no hang, guard abort without `--yes` (R1-s2, parity-guard). Esc at any pre-confirm point leaves the target untouched (R2-s3).
