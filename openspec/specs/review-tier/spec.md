# review-tier Specification

## Purpose
Deriving how deep a review must go from the diff's own shape — its size and the paths it touches
— instead of from the reviewer's or the orchestrator's judgment, and keeping that depth
informational so it never gains authority over delivery.

## Requirements

### Requirement: Deterministic review tier

`bin/review-tier` MUST derive a tier — `low`, `medium` or `high` — from declared rules over the
diff, and MUST be deterministic: the same diff always yields the same tier. The assessed
dimensions MUST be at least the authored changed lines and the paths the diff touches. The tier
MUST be reported together with the reason it was chosen, never as a bare label.

#### Scenario: A docs-only diff

- **WHEN** the diff touches only documentation, prose or process files and contains no
  behavior-bearing path
- **THEN** the tier is `low` and the reason names the paths that justified it

#### Scenario: A diff touches a high-consequence path

- **WHEN** the diff touches a path in the declared high-consequence set (for example schema or
  migration files, authentication or authorization code, security-sensitive configuration, or
  dependency manifests and lockfiles)
- **THEN** the tier is `high` and the reason names the path class that forced it, regardless of
  how few lines the diff has

#### Scenario: An ordinary behavior change

- **WHEN** the diff carries behavior but touches no high-consequence path and stays under the
  declared size bound
- **THEN** the tier is `medium` and the reason states the dimension that decided it

### Requirement: The tier selects depth, and nothing else

The tier MUST select only the depth of the review performed inside `review-change` — which
personas and which checks are required — and MUST NOT block a stage, close a change, authorize a
merge, or replace the formal QA gate that `workflows/pr-review.md` mandates. An unavailable or
failed assessment MUST NOT be read as `low`.

#### Scenario: A high tier is assessed

- **WHEN** the tier is `high`
- **THEN** the review runs with the deeper persona set and the additional checks the tier table
  declares, and the tier by itself neither blocks delivery nor substitutes for QA

#### Scenario: The assessment cannot be performed

- **WHEN** the diff cannot be measured (no base, an unreadable repository state, a missing tool)
  **or the diff is empty** because the base equals `HEAD`
- **THEN** the command reports that it could not assess instead of returning `low`, and the
  review proceeds at the higher depth or reports a blocker — never on an optimistic default

#### Scenario: A base that does not fork the change

- **WHEN** the base resolves but the diff against it is empty (the work was committed onto the
  base branch, or the ref already contains `HEAD`)
- **THEN** no tier is printed: an empty diff is reported as "cannot assess", because it is
  evidence that the base is wrong, not evidence that the change is documentation-only

### Requirement: The rules are declared and inspectable

The path classes and size bounds that produce a tier MUST be written in `rules/quality.md` as a
declared table, and the command MUST expose the rules it applied for the diff it assessed, so a
reviewer can check the tier against the rule rather than trusting the label.

#### Scenario: A reviewer checks the assessment

- **WHEN** a reviewer inspects a tier result
- **THEN** the output names each rule that fired (or states that none did), so the tier can be
  contradicted by pointing at a rule instead of arguing about judgment
