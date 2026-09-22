## Why

`rules/quality.md` already binds review evidence to a content fingerprint: reviewer and QA record
the working-tree hash they worked on, and a mismatch at release is a blocker. But the fingerprint
is taken *at closure* of each stage, by hand, from a rule the agent must remember to follow. Two
gaps remain:

- **Nothing freezes the candidate before the review starts.** A reviewer can be handed a moving
  tree; when its findings are written down, there is no record of *which* content they describe.
  A finding against content that changed mid-review is unfalsifiable.
- **Review depth is chosen by judgment.** Every work unit gets the same review, whether it is a
  docs typo or a migration that drops a column. Depth that does not follow risk is either
  expensive where it is not needed or thin where it matters.

## What Changes

- New **`bin/review-snapshot`** — freezes the review candidate *before* anything reads it: the
  base ref, `HEAD`, the working-tree content fingerprint and the diff hash, written to a
  manifest. Reviewers and QA report *against that snapshot*; at delivery the snapshot is
  re-computed and a mismatch means the evidence belongs to different content.
- New **`bin/review-tier`** — a deterministic risk assessment over the diff (authored lines plus
  the paths touched, from declared rules) that returns a tier: `low`, `medium` or `high`. The
  tier is **informational**: it selects how deep the review goes inside `review-change`, and it
  never blocks, closes, merges or replaces the formal QA gate of `pr-review`.
- `rules/quality.md` gains the snapshot-before-review rule and the tier table; the
  `review-change` brief and the `reviewer` agent reference them.

## Capabilities

### New Capabilities

- `review-evidence`: freezing the review candidate before it is read, reporting findings against
  that frozen snapshot, and detecting at delivery that the content moved.
- `review-tier`: the deterministic, declared mapping from a diff's shape (size and touched paths)
  to a review depth, and the rule that the tier is informational and human-owned.

### Modified Capabilities

None — new requirements only.

## Impact

- **Files:** `rules/quality.md`, `workflows/review-change.md`, `agents/reviewer.md`,
  `README.md`, `INSTALL.md`, `CHANGELOG.md`.
- **New:** `bin/review-snapshot`, `bin/review-tier`, `fixtures/review-tier/`, `fixtures/review-snapshot/`.
- **No runtime dependency added** — bash 3.2 with the tools the repo already assumes.
- **Concepts adapted from** [Gentleman-Programming/gentle-ai](https://github.com/Gentleman-Programming/gentle-ai)
  (MIT): the frozen review candidate and the risk-proportional depth. Ideas only — no binary, no
  runtime, no third-party state machine.
