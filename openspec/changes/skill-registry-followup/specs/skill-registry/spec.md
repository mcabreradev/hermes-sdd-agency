## MODIFIED Requirements

### Requirement: Defective frontmatter is flagged, never hidden

The command MUST detect and mark, with an explicit marker on the record, the frontmatter
defects that make a skill load but mis-route: a **block scalar whose indicator is followed by no
content** (the literal `|`/`>`/`>-`/`|2-`/`>2-` would become the description); a **multi-line
scalar** (a value continued on indented lines, or a quote opened and never closed); a **missing
or empty description** with no continuation; and a **missing frontmatter block** or one that
opens with `---` and never closes. A block or folded indicator **with an indented body** is legal
YAML: the skill is healthy and the description is that body. A defective skill MUST be reported
as such rather than printed with a plausible-looking description.

#### Scenario: A skill carries a block scalar description

- **WHEN** a `SKILL.md` declares its description as a YAML block scalar, including one with an
  explicit indentation indicator, and **no content follows the indicator**
- **THEN** the registry marks that record with its block-scalar marker and never presents the
  literal indicator (for example `|` or `|2-`) as the skill's description

#### Scenario: A skill carries a block or folded scalar with a body

- **WHEN** a `SKILL.md` declares `description: >-` (or `|`, `|2-`, `>-`, `>2-`, …) and indented
  text follows it as the scalar's content
- **THEN** the registry reports the record as healthy, with a description drawn from that text —
  the indicator alone is never treated as a defect

#### Scenario: A skill's description continues on indented lines

- **WHEN** a `SKILL.md` declares `description:` and continues the value on following indented
  lines, or opens a quote it never closes
- **THEN** the registry marks the record as a multi-line scalar instead of printing a truncated
  value or reporting the description as missing

#### Scenario: A skill has no frontmatter

- **WHEN** a `SKILL.md` starts without a frontmatter block
- **THEN** the registry reports the record with the `NO-FRONTMATTER` marker and the skill's exact
  path, so it can be fixed

#### Scenario: A skill's frontmatter never closes

- **WHEN** a `SKILL.md` opens a frontmatter block with `---` and never closes it before the body
- **THEN** the registry reports the record with the `UNCLOSED-FRONTMATTER` marker and the skill's
  exact path, distinct from `NO-FRONTMATTER`, so the two shapes are told apart

## ADDED Requirements

### Requirement: The inventory is exercised by a runnable suite

The registry MUST ship `fixtures/skill-registry/check.sh`, a runnable suite that executes
`bin/skill-registry` over the fixture roots and asserts the expected flag (and, for the legal
folded scalar, the expected description) of every fixture. A suite that cannot run MUST report
itself as a failure, never as a pass.

#### Scenario: The suite pins both sides of the block-scalar check

- **WHEN** `fixtures/skill-registry/check.sh` runs over the valid and defective fixture roots
- **THEN** it exits 0 only if every healthy fixture reports `ok` (with its expected description
  text) and every defective fixture reports its expected defect flag

#### Scenario: The suite cannot run

- **WHEN** the suite's inputs are missing or broken (no bin, no fixture root)
- **THEN** it exits non-zero with a reason naming what could not run — a skipped or broken suite
  is never reported as green
