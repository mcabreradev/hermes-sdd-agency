## Purpose

Freezing the review candidate before anything reads it, so a finding always belongs to one
exact content state, and detecting at delivery when that content moved under the evidence.

## ADDED Requirements

### Requirement: Freeze the candidate before the review

Before a review begins, the agency MUST freeze the review candidate and record it: the base ref,
the resolved `HEAD`, the working-tree content fingerprint (`bin/no-smoke-worktree`) and the hash
of the diff between base and `HEAD`. The frozen record MUST be produced by
`bin/review-snapshot`, which is read-only and MUST NOT modify the tree, the index or the
repository state.

#### Scenario: A review starts

- **WHEN** the `review-change` stage is about to dispatch its reviewer
- **THEN** a snapshot was taken first, and the reviewer's brief carries the snapshot's fingerprint
  so the findings are known to describe that exact content

#### Scenario: The snapshot is taken and the tree does not change

- **WHEN** `bin/review-snapshot` runs twice over an unchanged tree
- **THEN** both runs report the same fingerprint and diff hash, and neither run alters
  `git status --porcelain`

### Requirement: Delivery detects that the content moved

At delivery the snapshot MUST be re-computed and compared with the one the review was performed
on. The comparison MUST cover **the working-tree fingerprint and the diff hash**, and MUST
re-verify the snapshot's own recorded base; a record whose base no longer resolves, or whose
diff hash does not reproduce, MUST NOT be accepted as a match. A mismatch MUST be reported as a
blocker of the same class as the fingerprint mismatch `rules/quality.md` already defines — the
review describes content that is not what is being delivered — and MUST NOT be silently accepted.

The snapshot MUST NOT be written into the tracked working tree: a target inside the repository is
refused unless it is verifiably ignored, because the snapshot would otherwise become part of the
very content it fingerprints and turn every later comparison into a false mismatch.

#### Scenario: The tree changed after the review

- **WHEN** the working tree's fingerprint or diff hash at delivery differs from the frozen
  snapshot's
- **THEN** the mismatch is reported as a blocker naming both values and which field diverged, and
  the work is re-reviewed rather than delivered on the stale evidence

#### Scenario: The record does not reproduce

- **WHEN** the snapshot's recorded base no longer resolves, or its diff hash does not reproduce
  from that base
- **THEN** the comparison reports that it could not assess (or a mismatch naming the diff hash)
  — it never reports a match for a record that cannot be re-derived

#### Scenario: The snapshot would land inside the worktree

- **WHEN** the snapshot's output path is inside the repository and is not gitignored
- **THEN** the command refuses to write it, names the missing ignore entry, and exits non-zero,
  instead of recording a snapshot that corrupts the fingerprint it is meant to bind

#### Scenario: The content is identical but the history moved

- **WHEN** the exact same content was committed, rebased, amended or squashed after the review
- **THEN** the comparison still matches (the fingerprint is over content, not over commit
  identity) and the delivery is not blocked for that reason
