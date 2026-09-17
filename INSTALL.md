# Hermes SDD Agency — installation guide

Two install paths, depending on scope.

## Path A — one Hermes instance (self or a machine)

```bash
git clone https://github.com/mcabreradev/hermes-sdd-agency.git
cd hermes-sdd-agency

# 1. Process tree (rules, agents, workflows, templates, docs) into Hermes' home
cp -R agents workflows rules templates docs ~/.hermes/

# 2. Entire skills tree (personas, orchestration, openspec-*, process skills)
cp -R skills ~/.hermes/

# 3. Bundle installs — pick the ones you want
#    (each is a slash command: /agency /feature /bugfix /fix /idea /plan /implement
#     /architecture /review /qa /release /init-project)
hermes skills install skill-bundles/agency.yaml
hermes skills install skill-bundles/feature.yaml
hermes skills install skill-bundles/bugfix.yaml
hermes skills install skill-bundles/fix.yaml
# ... repeat for any other stage bundle

# 4. Restart the session, then in any project:
cd <your-project>
/agency          # or /feature for a feature, /bugfix for a minimal fix, /fix for cosmetic
```

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
