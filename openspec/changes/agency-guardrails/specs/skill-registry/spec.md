## Purpose

A read-only command that produces the verifiable inventory of the skills installed on this
machine — the exact `SKILL.md` path, description and tags of each one — so the set the agency
resolves can be audited instead of assumed, and defective frontmatter surfaces instead of
silently mis-routing a skill.

## ADDED Requirements

### Requirement: Skill inventory

`bin/skill-registry` MUST be a read-only command that discovers the `SKILL.md` files under the
given skill roots and prints, for each skill, at least: the **exact absolute path** of its
`SKILL.md`, its `name`, its `description` and its tags where present. It MUST accept one or
more `--root <dir>` arguments and MUST default to `~/.hermes/skills` when given none. It MUST
NOT write, create or modify any file.

#### Scenario: Run against a populated skills root

- **WHEN** `bin/skill-registry --root <dir>` runs over a tree containing `SKILL.md` files
- **THEN** it exits 0 and prints one record per skill carrying that skill's exact `SKILL.md`
  path together with its description, in a stable order

#### Scenario: Multiple roots

- **WHEN** the command is invoked with more than one `--root`
- **THEN** it inventories every root given and each printed path identifies which root the
  skill came from

### Requirement: Defective frontmatter is flagged, never hidden

The command MUST detect and mark the frontmatter defects that make a skill load but
mis-route — a block-scalar description (`description: |` followed by indented text), a missing
or empty description, and missing frontmatter entirely — so a defective skill is reported as
such rather than printed with a plausible-looking description.

#### Scenario: A skill carries a block-scalar description

- **WHEN** a `SKILL.md` declares its description as a YAML block scalar
- **THEN** the registry marks that record as defective and does not present the literal `|` as
  the skill's description

#### Scenario: A skill has no frontmatter

- **WHEN** a `SKILL.md` starts without a closing frontmatter block
- **THEN** the registry reports the record with an explicit missing-frontmatter marker and the
  skill's path, so it can be fixed

### Requirement: Portability and no new dependency

The command MUST run on macOS's default bash 3.2 with only the tools the repository already
assumes (`find`, `grep`, `sed`, `awk`); it MUST NOT require `jq`, `python`, `node` or any
package manager, and it MUST NOT need network access.

#### Scenario: Running on macOS default bash

- **WHEN** the command runs under bash 3.2 with no additional tooling installed
- **THEN** it completes successfully, without bash-4-only constructs and without invoking a
  package manager or the network

#### Scenario: Deterministic and side-effect free

- **WHEN** the command runs twice over the same tree
- **THEN** both runs produce identical output and the working tree is left unchanged
  (`git status --porcelain` clean)
