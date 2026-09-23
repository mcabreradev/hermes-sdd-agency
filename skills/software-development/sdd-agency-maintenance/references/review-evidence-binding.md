# Review evidence binding (frozen candidate + review tier)

Depth notes for the two `bin/` tools that bind a review's findings to the content they describe
and set review depth from the diff's own shape. Load this when editing `rules/quality.md`'s
"Frozen review candidate" / "Review tier" sections, the two bins, or their fixtures — the rule
table and the implementation are one artifact in two places and must move together.

## `bin/review-snapshot` — the frozen candidate

Writes a manifest **before** the review starts, so a reviewer cannot be handed a moving tree:

| Field | Meaning |
|---|---|
| `base` | the ref the diff is measured against |
| `head` | `HEAD` at snapshot time — **context only, never a verdict input** |
| `fingerprint` | working-tree content fingerprint (same instrument as `no-smoke-worktree`) |
| `diffHash` | hash of the diff content |

`--compare <manifest>` re-computes the content fingerprint **and** the diff hash, re-verifies the
manifest's own recorded base, and prints `MATCH` (exit 0) or `MISMATCH` (exit 1) naming which field
diverged and both values. A `MISMATCH` means the findings describe content that no longer exists →
the review is invalid and must be re-run against the new content. **Re-verify every field the record
carries, never just the fingerprint**: a single-field check returns `MATCH` for a hand-edited
manifest whose base/diff hash are forged — a verdict on a record that never described this range.

Design constraints that are the whole point of the tool:

- **Content-based comparison, not commit-based.** A rebase, amend or squash that preserves
  content must still `MATCH`. Comparing shas would block exactly the legitimate rewrites the
existing fingerprint rule avoids, and a check that fires on correct practice gets disabled.
- **Never mutates the repo.** No index writes, no refs, no stash. The proof is
  `git status --porcelain` unchanged after a run, and that belongs in the fixture as its own case.
- **The write must be checked, because exit 0 is the contract.** `cat > "$OUT"` fails inside an
  `if !` / bare redirect whose status is discarded when the target is a directory: the tool still
  prints the full `snapshot: … fingerprint: …` summary and exits 0, so a caller checking `rc=0`
  records a frozen candidate that does not exist and only finds out at the delivery compare. Refuse
  it explicitly ("is it a directory") and exit non-zero. The same applies to `mkdir -p` of the
  parent and to any post-write step: every step after the fingerprint is computed can still void
  the artifact, so its failure cannot be silent.
- **Refuse to write the manifest inside the worktree unless it is verifiably ignored.** A snapshot
  landing in the tracked tree changes the very fingerprint it records, so `--compare` then reports a
  false `MISMATCH` — including in any consuming project whose `.gitignore` the installer never
  carried. Test the target with `git check-ignore` and exit non-zero naming the missing entry; do not
  rely on this repo's own `.gitignore` covering other repos. **The refusal message is the only
  remediation the consumer gets**, so the entry it suggests must be paste-safe: a basename→`*`
  derivation suggests `*` for a root-level target and ignores the whole repository — fall back to the
  concrete default path whenever the derived form is not a real file pattern. And because
  `install.sh` carries no `.gitignore`, the consumer-side precondition ("add this entry before the
  first snapshot") belongs in INSTALL/README next to the command, not left inferable from a
  rule-file sentence that is true only of this repo.
- **Resolve both sides of the path comparison physically** (`pwd -P`). On macOS
  `git rev-parse --show-toplevel` returns the physical `/private/var/...` while `$PWD` is the
  symlinked `/var/...`, so a string-prefix guard silently misses and writes into the tree anyway.
  Resolve through the nearest *existing* ancestor too: a fresh `reports/` does not exist yet, so a
  `cd`-based resolver aimed at the target's own directory fails and leaves the path unnormalised.
- **A missing/malformed manifest is cannot-assess, not MATCH.** Exit non-zero with a reason.

## `bin/review-tier` — depth from shape

Declared table (mirror it row for row when you edit either side; a row with no matching pattern,
or a pattern with no declared row, is a reviewer finding):

| Tier | When |
|---|---|
| `low` | only documentation/process paths; no behavior-bearing path touched |
| `medium` | behavior-bearing, no high-consequence class, within the size bound |
| `high` | any high-consequence path **or** over the size bound (one such path forces `high` however few lines) |

High-consequence classes: `schema-migration`, `auth`, `security-config`, `dependency-manifest`.
The size bound is the same advisory ~400 authored lines as `rules/coding.md` — declared in
`rules/quality.md` and stated as the exact tier boundary (at or under the bound is `medium`, over it
is `high`). **No env override**: a knob that can silently lower a tier is the same optimistic-default
defect as cannot-assess collapsing to `low`. Output: the tier, the reason in one clause, every rule
that fired, the path count and the authored line count.

Properties to preserve when touching it:

- **It prints the rules that fired** so a reviewer can contradict the tier *by pointing at a
  rule* rather than arguing about judgment. Removing that output turns the tool into an oracle.
- **Cannot-assess is a first-class outcome** (unknown base, not a repo, git missing, nothing
  measurable) with a non-zero exit. An unassessable diff must never fall through to `low` — a
  silently optimistic default is the worst failure this tool can have.
- **An empty diff is cannot-assess, never `low`.** A base that resolves but equals `HEAD` (the work
  was committed onto the base branch, the ref is wrong, the tree is clean) yields zero paths and zero
  lines, which the docs-only branch reads as "documentation only" and so returns the shallowest tier
  on a large behavior change. An empty diff is evidence the *base* is wrong, not evidence about the
  change — refuse it and say so. **Name uncommitted work in that reason alongside the base**: the
  diff measures committed content only, so a clean tree is at least as often untracked edits as a
  wrong ref, and a diagnosis that names only the base sends the reader to the wrong fix.
- **Anchor a declared row's pattern to whole path segments.** A docs-directory row written as a loose
  substring (`doc` matching `document`) classifies `src/document.ts` as documentation and hands a
  behavior module the shallowest review with no way to promote it. A row whose pattern cannot match
  its own row's semantics is the drift surface above; test both directions.
- **Informational only.** It never blocks, closes, authorizes a merge, or substitutes for the QA
gate; it selects depth. Document that in every place it is wired (workflow, agent brief, README).
- **Determinism**: two runs are byte-identical. Assert it in the fixture, do not eyeball it.

## Fixture shape that actually proves the tool

- One case per **declared row** of the tier table, each asserted individually — a whole-file grep
  stays green while a row is dead.
- Below-bound and exactly-at-bound cases, plus a docs-only `low` and a rename/delete-only diff.
- A path that is **both** high-consequence and docs-like, which is where a naive glob over-matches.
- For the snapshot: MATCH → content change → MISMATCH → commit the changed content → still
  MISMATCH → **restore identical content after commits → MATCH again** (that last one is what
  proves the comparison is content-based) → missing manifest → cannot assess → repo untouched.
- **One case per field the record carries**: a manifest with a correct fingerprint but a forged diff
  hash, and one whose recorded base does not resolve, each asserted as a non-MATCH. A suite with only
  the fingerprint case stays green over a single-field comparison.
- **The empty diff, explicitly**: base == `HEAD`, and a change committed onto the base branch (a
  900-line migration plus an auth rewrite), both asserted as cannot-assess with a non-zero exit — the
  case a docs-only `low` expectation would otherwise paper over.
- **The in-repo `--out` refusal**, run in a repo with no `.gitignore` entry (expect refusal naming the
  entry), then with the entry present (expect success), and once in a repo created under `$TMPDIR` —
  the `/var` → `/private/var` symlinked path is where a physical-resolution guard is proven rather
  than assumed. Assert the suggested `.gitignore` entry on a **root-level** target too, and assert
  that `--out` naming a **directory** exits non-zero instead of reporting a write that never
  happened.
- **The docs-like near-miss**: `src/document.ts` (and a hyphen/underscore spelling of a
  high-consequence class) beside a true `docs/guide.md`, asserted individually.
- **The uncommitted case**: untracked behavior files on top of `base == HEAD`, asserted as
  cannot-assess naming uncommitted work — the shape an implement-change flow produces most often.
- Fixture repos must commit on a `work` branch off `main`: a fixture that commits onto `main`
  itself makes `<base>...HEAD` empty and the suite passes or fails for the wrong reason.
- **Run the fixture suite immediately after every edit to a bin, and read a red case as evidence
  about the EDIT first.** `bash -n` passes on a script that dies at runtime: under `set -u` an unbound
  variable inside a `$( )` argument (a compound expression packed into a `printf` argument) is an
  error the parser never sees, and the tool then exits through the wrong path — here the previously
  passing refusal case silently became `exit=1` with an unrelated message. A suite that was green
  before your change tells you nothing about the run after it.
