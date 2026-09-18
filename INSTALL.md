# Hermes SDD Agency — installation guide

Two install paths, depending on scope.

## Path A — one Hermes instance (self or a machine)

**One command (preferred):** the installer merges the process tree, skills and
bundles into your Hermes home (default `~/.hermes`, overridable with `-p`).

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mcabreradev/hermes-sdd-agency/main/install.sh)
```

The installer asks for the target home when run interactively (Enter accepts the
default). Flags:

```
-p, --prefix DIR     Target Hermes home (default: $HERMES_HOME or ~/.hermes)
    --bundles a,b,c  Only install the named bundles (default: all 12)
    --no-bundles     Process tree + skills only, skip bundles
    --dry-run        Print what would happen; write nothing
-y, --yes            Skip the overwrite confirmation (non-interactive)
```

The installer is **guarded against accidental overwrites**: if the target home
already holds data it stops and asks for confirmation (interactive) or aborts
(non-interactive, unless `--yes`). Reinstalling into an existing agency prints
an update warning; an existing home with other data prints a stronger one.

Or install from a clone (no re-download):

```bash
git clone https://github.com/mcabreradev/hermes-sdd-agency.git
cd hermes-sdd-agency
./install.sh
```

What it does, in order:

1. `agents/ workflows/ rules/ templates/ docs/` → copied into the target home
   (merge; does not wipe existing config).
2. `skills/` → copied into `<home>/skills/` (personas + orchestration +
   openspec-* + process skills).
3. `skill-bundles/*.yaml` → copied into `<home>/skill-bundles/`. **Merely
   placing a bundle `.yaml` there registers it** — `hermes bundles list` reads
   the directory; you do NOT need `hermes skills install <path>` (which only
   works for catalog IDs or remote URLs, not local paths).

Then restart the session, and in any project run `/agency` (or `/feature`,
`/bugfix`, `/fix`).

### `/feature` discovery dependency

The `/feature` bundle is a **discovery-first** loop: `superpowers:brainstorming`,
`grill-with-docs`, `grilling` and `domain-modeling` are loaded before any
planning/code (HARD-GATE: no implementation until the design is approved). These
skills are **not** shipped by this repo; install them on the target once:

```bash
# brainstorming (one-command Hermes plugin)
hermes plugins install obra/superpowers --enable

# grill-with-docs, grilling, domain-modeling (entire 38-skill collection)
npx skills@latest add mattpocock/skills
```

`npx skills` detects the Hermes agent on its own and installs into your Hermes.
To install just the three needed (instead of all 38):

```bash
npx skills@latest add mattpocock/skills -a hermes-agent \
  --skill grilling --skill grill-with-docs --skill domain-modeling
```

Without them, `/feature` still runs the SDD loop but the discovery step cannot
resolve its skills. `/agency` and the other stage bundles are unaffected.

### `/do` — autonomous mode (no discovery-skills needed)

`/do` runs the full agency loop end-to-end with minimal human input and ends in a
PR (draft) for your review. It is **self-contained** — it does not load the
discovery skills that `/feature` needs, so it installs with zero extra steps. It
is governed by a confidence gate: routine decisions run with conservative
defaults (each recorded as an ADR and flagged `ASSUMED`), and non-trivial
decisions (contract/API, data model, real security risk, costly-to-revert
architecture) stop the stage and wait for you. It never publishes, tags or
merges. See `workflows/autonomous-change.md` and `templates/autonomous-report.md`.

### `/continue` — continue an existing change

`/continue` continues a change that already has a **validated OpenSpec change**
(proposal/spec/tasks, e.g. set up via `/feature`) and runs the pending stages to
termination — code, review, QA, archive + sync — ending with the **existing PR
draft updated**. It detects the current state (`openspec list`/`status`, git,
PR) instead of assuming it, and picks up from the first pending stage, so it
never re-runs discovery/spec that are already done and never opens a second PR.

Same confidence gate as `/do`: routine decisions run with conservative defaults
(each recorded as an ADR flagged `ASSUMED`), non-trivial ones
(contract/API, data model, real security risk, costly-to-revert) stop the stage
and wait. See `workflows/continue-change.md`.

## Path B — a full profile copy

If you want an entire isolated Hermes profile that includes this agency:

```bash
hermes profile new sdd            # creates ~/.hermes/profiles/sdd/
# then install Path A content into $HERMES_HOME of that profile
```

## Verify the install

The install proves the files landed, not that the model sees them (skills load fresh
per conversation). Sanity check:

```bash
hermes bundles list | grep -E 'agency|feature|bugfix|/fix'
ls ~/.hermes/skills/agents | wc -l             # expect 23 personas
ls ~/.hermes/skills | grep openspec            # expect 14 (openspec-sdd + 12 CLI + ...)
```

Note on layout: the repo stores `skills/` **flat** (a copy of the SDD-relevant subset of
your `~/.hermes/skills/`, under `skills/software-development/` for the two orchestration
skills). The install copies the whole tree, so internal `file_path` references resolve
identically; only the exact directory nesting differs from a full profile copy.

## What you must NOT copy into a project

`rules/`, `agents/`, `workflows/`, `templates/`, `docs/` are **global process**. They
belong under `~/.hermes/`, never inside a project repo (`rules/project-boundaries.md`).
The only project-level entry is OpenSpec's own `openspec/`, created by
`workflows/initialize-project.md`.

## Keeping the export in sync

`rules/`, `agents/`, `workflows/`, `templates/`, `docs/`, `skill-bundles/` and the
SDD-relevant skills under `skills/` are copied from `~/.hermes/`. When you change a rule,
add a bundle or edit a persona/process skill locally, re-copy that directory here and
commit so the public export stays current.

## Requirements

- [Hermes Agent](https://hermes-agent.nousresearch.com/) (any provider)
- [OpenSpec CLI](https://github.com/Fission-AI/OpenSpec) ≥ 1.13.0 (`~/.local/bin/openspec`)
