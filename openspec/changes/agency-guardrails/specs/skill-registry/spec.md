## Purpose

A read-only command that produces the verifiable inventory of the skills installed on this
machine — the exact `SKILL.md` path, description and tags of each one — so the set the agency
resolves can be audited instead of assumed, and defective frontmatter surfaces instead of
silently mis-routing a skill.

## ADDED Requirements

### Requirement: Skill inventory

`bin/skill-registry` MUST be a read-only command that discovers the `SKILL.md` files under the
given skill roots and prints, for each skill, at least: the **exact absolute path** of its
`SKILL.md`, its `name`, its `description` and its tags where present. It MUST accept one or more
`--root <dir>` arguments and MUST default to `~/.hermes/skills` when given none. It MUST
identify, on each record, **which root** the skill came from. It MUST NOT write, create or
modify any file.

#### Scenario: Run against a populated skills root

- **WHEN** `bin/skill-registry --root <dir>` runs over a tree containing `SKILL.md` files
- **THEN** it exits 0 and prints one record per skill carrying that skill's exact `SKILL.md`
  path together with its description, in a stable order

#### Scenario: Multiple roots

- **WHEN** the command is invoked with more than one `--root`
- **THEN** it inventories every root given and each printed record names the root it came from,
  so a record stays attributable even when the roots are nested or overlapping

#### Scenario: A root is repeated or nested

- **WHEN** the same directory is passed twice, or two roots overlap so one contains the other
- **THEN** each skill is reported once (deduplicated by resolved absolute path) and the summary
  does not count the same file twice

### Requirement: Defective frontmatter is flagged, never hidden

The command MUST detect and mark, with an explicit marker on the record, the frontmatter
defects that make a skill load but mis-route: a **block scalar** in any legal form
(`description: |`, `|-`, `|+`, `>-`, and the forms carrying an explicit indentation indicator
such as `|2-` or `>2-`); a **multi-line scalar** (a value continued on indented lines, or a
quote opened and never closed); a **missing or empty description** with no continuation; and a
**missing frontmatter block** or one that opens with `---` and never closes. A defective skill
MUST be reported as such rather than printed with a plausible-looking description.

#### Scenario: A skill carries a block scalar description

- **WHEN** a `SKILL.md` declares its description as a YAML block scalar, including one with an
  explicit indentation indicator
- **THEN** the registry marks that record with its block-scalar marker and never presents the
  literal indicator (for example `|` or `|2-`) as the skill's description

#### Scenario: A skill's description continues on indented lines

- **WHEN** a `SKILL.md` declares `description:` and continues the value on following indented
  lines, or opens a quote it never closes
- **THEN** the registry marks the record as a multi-line scalar instead of printing a truncated
  value or reporting the description as missing

#### Scenario: A skill has no frontmatter

- **WHEN** a `SKILL.md` starts without a frontmatter block, or opens one with `---` and never
  closes it
- **THEN** the registry reports the record with the marker for that shape and the skill's exact
  path, so it can be fixed

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
