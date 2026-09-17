# Hermes SDD Agency — installation guide

Two install paths, depending on scope.

## Path A — one Hermes instance (self or a machine)

```bash
git clone https://github.com/mcabreradev/hermes-sdd-agency.git
cd hermes-sdd-agency

# 1. Process tree (rules, agents, workflows, templates, docs) into Hermes' home
cp -R agents workflows rules templates docs ~/.hermes/

# 2. Personas (expertise) into the skills dir
cp -R skills/agents ~/.hermes/skills/

# 3. Bundle installs — pick the ones you want
#    (each is a slash command: /agencia /feature /bugfix /fix /idea /plan /implementar
#     /arquitectura /review /qa /release /init-proyecto)
hermes skills install skill-bundles/agencia.yaml
hermes skills install skill-bundles/feature.yaml
hermes skills install skill-bundles/bugfix.yaml
hermes skills install skill-bundles/fix.yaml
# ... repeat for any other stage bundle

# 4. Restart the session, then in any project:
cd <your-project>
/agencia          # or /feature for a feature, /bugfix for a minimal fix, /fix for cosmetic
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
hermes bundles list | grep -E 'agencia|feature|bugfix|/fix'
ls ~/.hermes/skills/agents | wc -l      # expect 23 personas
```

## What you must NOT copy into a project

`rules/`, `agents/`, `workflows/`, `templates/`, `docs/` are **global process**. They
belong under `~/.hermes/`, never inside a project repo (`rules/project-boundaries.md`).
The only project-level entry is OpenSpec's own `openspec/`, created by
`workflows/initialize-project.md`.

## Keeping the export in sync

`rules/`, `agents/`, `workflows/`, `templates/`, `docs/`, `skill-bundles/` and
`skills/agents/` are copied from `~/.hermes/`. When you change a rule or add a bundle
locally, re-copy that directory here and commit so the public export stays current.

## Requirements

- [Hermes Agent](https://hermes-agent.nousresearch.com/) (any provider)
- [OpenSpec CLI](https://github.com/Fission-AI/OpenSpec) ≥ 1.13.0 (`~/.local/bin/openspec`)
