# Hermes SDD Agency — install guide

> Get the whole agency running on another Hermes in minutes — one command, guarded against accidental overwrites, idempotent.

![install: 1 command](https://img.shields.io/badge/install-1%20command-success) ![bundles: 15](https://img.shields.io/badge/bundles-15-blueviolet.svg) ![skills: 65](https://img.shields.io/badge/skills-65-brightgreen.svg) ![OpenSpec: 1.13+](https://img.shields.io/badge/OpenSpec-1.13+-blue)

## ⚡ TL;DR

| | |
|---|---|
| **One command** | `bash <(curl -fsSL …/install.sh)` → process tree, 65 skills, 15 bundles into `~/.hermes` |
| **Guarded** | never overwrites existing config without an explicit **Yes**; idempotent — safe to re-run |
| **Interactive** | arrow-key menu in a terminal; **piped/CI runs skip the menu** and use defaults |
| **`/feature` ready?** | install the 4 discovery skills once (`superpowers:brainstorming` + mattpocock's 3) |
| **Prove it** | `hermes bundles list` · `ls ~/.hermes/skills/agents \| wc -l` (expect 23) · run `/agency` |

## Path A — install into a Hermes home (the normal way)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mcabreradev/hermes-sdd-agency/main/install.sh)
```

Interactive (terminal): arrow-key menu — select bundles with **space**, move with **↑↓**, type to
filter, **Enter** to confirm, **Esc**/**Ctrl+C** to cancel. Nothing writes until you confirm the
summary. On the final **Yes/No** confirm, **↑/←** picks Yes, **↓/→** picks No (or type **y**/**n**)
— it defaults to **No**, so an overwrite can never ride a stray Enter.

Piped/CI (stdin not a TTY): skips the menu entirely, uses the defaults, never waits for input.

Flags:

```bash
-p, --prefix DIR     Target Hermes home   (default: $HERMES_HOME or ~/.hermes)
    --bundles a,b,c  Only install the named bundles   (default: all 15)
    --no-bundles     Process tree + skills only, skip bundles
    --dry-run        Print what would happen; write nothing
-y, --yes            Skip the overwrite confirmation (non-interactive)
```

Or from a clone (no re-download):

```bash
git clone https://github.com/mcabreradev/hermes-sdd-agency.git
cd hermes-sdd-agency
./install.sh
```

### What it does, in order

```
┌─────────────── install.sh ──────────────────────────────────┐
│ 1  agents/ workflows/ rules/ templates/ docs/ bin/  → home  │
│    (merge — never wipes existing config)                     │
│ 2  skills/  → <home>/skills/  (personas + process skills)    │
│ 3  skill-bundles/*.yaml → <home>/skill-bundles/              │
│    placing the .yaml registers it — no extra install step    │
└──────────────────────────────────────────────────────────────┘
```

The overwrite guard: an existing home with other data stops and asks (interactive) or aborts
(non-interactive, unless `--yes`). Reinstalling into an existing agency prints an update warning.

### The 7 bins that ship with it (`bin/` → `<home>/bin/`)

```bash
no-smoke-worktree                      # content fingerprint of the working tree
skill-registry                         # inventory: SKILL.md path + description + flags
review-snapshot --base main            # freeze the candidate before the review
review-snapshot --compare <path>       # at delivery: MATCH or MISMATCH
review-tier --base main                # low | medium | high, with the rules that fired
agency-next                            # the next step, read from files
run-trace --file reports/<runId>.jsonl # the run's stages/statuses/blockers, for resume + audit
change-collision --base main --a <a> --b <b>  # parallelizable | collision | cannot assess
```

- `no-smoke-worktree` — binds reviewer/QA/release evidence to the exact tree they validated
  (`rules/quality.md`); changes when any source changes, survives rebase/amend.
- `skill-registry` — per skill: exact `SKILL.md` path, name, description, tags; flags the
  frontmatter defects that make a skill load but mis-route (`BLOCK-SCALAR`,
  `MISSING-DESCRIPTION`, `NO-FRONTMATTER`, `UNCLOSED-FRONTMATTER`). Write-only? No — read-only.
- `review-snapshot` — freezes the candidate (base, HEAD, fingerprint, diff hash) **before** the
  reviewer/QA read anything; `--compare` at delivery exits non-zero on a moved tree.
- `review-tier` — depth from the diff's shape; **informational, never a gate**.
- `agency-next` — `working` / `checking` / `ready` / `needs-decision` + the single next
  transition + the command; a missing input **narrows** the answer, never optimistic.

Consumer precondition for `review-snapshot --out <in-repo-path>`: the in-repo target is refused
unless the project already gitignores it (that's by design — evidence lives outside the diff):

```bash
echo 'reports/review-snapshot*.json' >> .gitignore
```

Then: restart the session, cd into a project, run `/agency` (or `/feature`, `/bugfix`, `/fix`).

## 🧩 `/feature` discovery dependency (one-time)

`/feature` is a **discovery-first** loop: `superpowers:brainstorming`, `grill-with-docs`,
`grilling` and `domain-modeling` load before any planning or code (HARD-GATE). This repo does
**not** ship them — install once on the target:

```bash
hermes plugins install obra/superpowers --enable            # brainstorming
npx skills@latest add mattpocock/skills                     # the other three (whole set)
# or just the three:
#   npx skills@latest add mattpocock/skills -a hermes-agent \
#     --skill grilling --skill grill-with-docs --skill domain-modeling
# (13 openspec-* + 37 process skills come from this repo — no extra step)
```

Without them, `/feature` still runs the SDD loop; only its discovery step can't resolve its
skills. `/agency` and the other stage bundles are unaffected.

## 🤖 `/do` and `/continue` — zero extra steps

- **`/do`** — full loop end-to-end, ends in a PR (draft) for your review. **Self-contained**:
  no discovery skills needed. Confidence gate: routine decisions run with conservative defaults
  (recorded as ADRs flagged `ASSUMED`); non-trivial ones (contract/API, data model, real
  security, costly-to-revert) **stop and wait for you**. Never publishes, tags or merges itself.
- **`/continue`** — picks up a change that already has a validated OpenSpec change, runs the
  pending stages (code → review → QA → archive+sync), updates the **existing** PR draft. Detects
  state from files, never re-runs what's done, never opens a second PR. Same confidence gate.

## Path B — a full isolated profile

```bash
hermes profile new sdd          # creates ~/.hermes/profiles/sdd/
# then install Path A content into that profile's $HERMES_HOME
```

## ✅ Verify the install

The install proves the files landed, not that the model sees them (skills load fresh per
conversation). Sanity check:

```bash
hermes bundles list | grep -E 'agency|feature|bugfix|fix'
ls ~/.hermes/skills/agents | wc -l      # expect 23 personas
ls ~/.hermes/skills | grep openspec     # expect 13 openspec-* skills
bin/skill-registry --root ~/.hermes/skills   # inventory + zero defects
```

Layout note: the repo stores `skills/` flat (the SDD-relevant subset of `~/.hermes/skills/`,
with the two orchestration skills under `skills/software-development/`). The install copies the
whole tree, so internal `file_path` references resolve identically — only the directory nesting
differs from a full profile copy.

## 🚫 What must NOT go into a project

`rules/`, `agents/`, `workflows/`, `templates/`, `docs/` are **global process** — they belong
under `~/.hermes/`, never inside a project repo (`rules/project-boundaries.md`). The only
project-level entry is OpenSpec's own `openspec/`, created by `workflows/initialize-project.md`.

## 🔄 Keeping the export in sync

`rules/`, `agents/`, `workflows/`, `templates/`, `docs/`, `bin/`, `skill-bundles/` and the
SDD-relevant `skills/` are copied from `~/.hermes/`. When you change a rule, add a bundle or
edit a persona locally, re-copy that directory here and commit so the public export stays
current — and run `skill-registry` to confirm the tree inventoried clean.

## Requirements

- [Hermes Agent](https://hermes-agent.nousresearch.com/) (any provider)
- [OpenSpec CLI](https://github.com/Fission-AI/OpenSpec) ≥ 1.13.0 (`~/.local/bin/openspec`)
