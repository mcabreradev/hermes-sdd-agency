## Why

`bin/skill-registry` was built to catch the converted-persona defect where a `description: |`
with no content makes the loader present the literal indicator as the description. The detector
implemented that as "any line ending in a block/folded indicator is defective" — without checking
whether real content follows it. A legal YAML folded scalar (like `context-architecture`'s real
`description: >-` with an 821-char body) was therefore flagged `BLOCK-SCALAR`, and the flag was
believed: the skill was reported to the user as "routes badly" in a session before anyone verified
the claim with a real YAML parser.

Two follow-on gaps made it worse: the two fixtures that were supposed to pin the defect both carry
content under the indicator (so they are legal YAML, and the flagged behaviour was never actually
exercised), and there is no `check.sh` that runs the fixtures at all — the inventory suite simply
does not exist, which is why nothing caught the false positive.

## What Changes

- `bin/skill-registry` distinguishes a block/folded scalar **with content** (legal; the
  description is the indented text) from one **without content** (the real defect; the loader
  would present the literal indicator). Only the latter is flagged `BLOCK-SCALAR`.
- The defective fixture is rewritten to the actual defect shape (`description: |` followed
  directly by another key, so the description is empty), and a legal folded-scalar fixture is
  added so both sides of the detector are pinned.
- New `fixtures/skill-registry/check.sh` runs the inventory over the fixture roots and asserts
  every expected flag — the missing suite.

## Capabilities

### Modified Capabilities

- `skill-registry`: the block-scalar detection now keys on **content absence**, not on the
  indicator's presence, and the fixtures exercise both the defect and the legal folded form.

## Impact

- **Files modified:** `bin/skill-registry`, `fixtures/skill-registry/roots/defective/fixture-block-scalar/SKILL.md`.
- **New files:** `fixtures/skill-registry/check.sh`,
  `fixtures/skill-registry/roots/valid/fixture-folded-legal/SKILL.md`.
- No runtime dependency added — bash 3.2 with the tools the repo already assumes.
