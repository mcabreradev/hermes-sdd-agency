# Initialize Project — hermes-sdd-agency

## Verified project root

- Physical root: `/Users/migue/Workspace/migue/hermes-sdd-agency-worktrees/install-interactive-menu`
- `git rev-parse --show-toplevel`: same (worktree on branch `agent/interactive-install-menu`)
- `openspec context --json` → `root.path`: `/Users/migue/Workspace/migue/hermes-sdd-agency-worktrees/install-interactive-menu`

## Inputs received

- **Project name**: hermes-sdd-agency (verified: repo basename + remote `mcabreradev/hermes-sdd-agency`).
- **Product idea**: Spec-Driven Development orchestration system for Hermes Agent; ships process (rules, agents, workflows, templates, skill bundles, personas) and a single-command installer + landing page.
- **Target users**: developers using Hermes Agent who want spec-driven project management via `/agency` and stage slash commands.
- **Preferred stack**: Bash 3.2+ for `install.sh`; Markdown for process assets; GitHub Pages for the landing page. Real commands surveyed from the repo (README, install.sh).
- **Business rules / scope**: none beyond installer behavior declared by the code itself; the requested change (interactive menu like `npx skills add`) is the current task.

## Pending inputs

- None blocking. `Business Rules` reflects only what the existing code documents; product rules are the standing language contract (docs/code English, chat Spanish) and the "merges, never wipes, idempotent" installer invariant.

## State of openspec/

- Root created: `/Users/migue/Workspace/migue/hermes-sdd-agency-worktrees/install-interactive-menu/openspec` (`openspec init --tools hermes --no-animation`).
- Active changes: none yet.
- Capabilities (`openspec list --specs`): none yet — first capability comes with the first change.

## Repo real commands

```bash
build:      none required (static docs + bash script)
test:       none standardized; install.sh exercised via bash -n, --dry-run, temp --prefix install
lint:       none standardized
typecheck:  none (no code)
```

## Structure created

- `openspec/` (via CLI) + `openspec/project.md`
- `docs/architecture/`
- `docs/decisions/`
- `reports/`

## Not created (by design)

- No implementation code (installer changes come via the OpenSpec change).
- No Hermes agents/workflows copied into the repo (process stays global in `~/.hermes/`).
- Nothing written outside this project root.

## Next step

`idea-to-openspec` → scoped OpenSpec change for the interactive installer menu.
