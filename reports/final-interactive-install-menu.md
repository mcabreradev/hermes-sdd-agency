# Final report — interactive-install-menu

- **Date:** 2026-09-18
- **Project:** /Users/migue/Workspace/migue/hermes-sdd-agency-worktrees/install-interactive-menu
- **Status:** completed

## What was done

| Stage | Agent | Result | Evidence |
|---|---|---|---|
| initialize-project | openspec | done | `openspec/project.md`, docs/{architecture,decisions}, reports/initialize-project.md |
| discovery+openspec | openspec | done | proposal.md, spec.md, design.md, tasks.md; `validate` pass |
| architect | architect | done | docs/decisions/0001-0006.md maps to design.md |
| planner | openspec | done | tasks.md 11/11 implemented |
| implement | builder | done | install.sh +390; tasks 11/11 ticked after verification |
| review | reviewer | changes-requested → approved (3 MAJOR fixed by Hermes) | reports/review-interactive-install-menu.md |
| qa | qa | pass 16/16 | reports/qa-interactive-install-menu.md |
| release | openspec | done | archived `2026-09-18-interactive-install-menu`; spec created |

## Artifacts

- `install.sh` — interactive `npx skills add`-style installer menu (arrow keys, multi-select, live search, prefix step, summary, confirm, cancel).
- `INSTALL.md`, `README.md` — interactive-flow docs.
- `openspec/changes/archive/2026-09-18-interactive-install-menu/`
- `openspec/specs/installer-interactive-menu/spec.md` (new capability, Purpose preserved)
- `docs/decisions/0001-0006.md`, `reports/{initialize-project,review,qa}-*.md`

## Verification

```bash
bash -n install.sh                                  # OK (GNU bash 3.2.57, macOS)
openspec validate --all --json                     # 0 failed
openspec validate --archived --json                # 0 failed
grep -rl "^## ADDED Requirements" openspec/specs    # none (no inert specs)
pty-driven QA: 16/16 scenarios pass                 # reports/qa-*.md
non-interactive parity vs HEAD: IDENTICAL           # review evidence
```

## OpenSpec status

- Change: `interactive-install-menu` — archived at `openspec/changes/archive/2026-09-18-interactive-install-menu`
- Tasks: 11/11 completed
- New capability: `installer-interactive-menu` (4 requirements)

## Defects, debt and gaps

- **MINOR (declared, not fixed):** toggle glyph glued to label (`●agency` vs `● agency`) — install.sh:217 cosmetic; QA flagged, no behavior impact.
- **NIT:** stale comment in `_menu_init` (VMIN/VTIME) and doc "all 12" vs `ALL_BUNDLES`=14 historical count.
- No open BLOCKER/MAJOR.

## Decisions made

- ADR-0001: menu only on TTY + when choice not pinned by flags.
- ADR-0002: bundle multi-select defaults to all (same set as before).
- ADR-0003: portable bash 3.2 raw-key loop, ANSI not tput.
- ADR-0004: zero-selection Enter is a no-op (with key-reset fix).
- ADR-0005: overwrite guard keeps strength; renders inside summary+confirm.
- ADR-0006: no runtime dependency (pure Bash).
- All in `docs/decisions/`.

## Next step

Human reviews and merges the PR (draft) — this change only; then delete the worktree. The installer can be validated live with `./install.sh --dry-run` on a terminal.

## Lessons for the global system

- The `npx skills add` interaction model is fully reproducible in portable bash 3.2 (pty-verified). Consider a reusable `references/interactive-bash-ui.md` in the orchestration skill for future installer/CLI work.
- Reviewer+QA both independently drove the interactive path via Python `pty` — standardize that harness as a QA helper for any future interactive-script change.
