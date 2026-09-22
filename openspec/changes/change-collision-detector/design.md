# Design — change collision detector

## Context

The parallelization rule lives in `rules/orchestration.md` ("Parallelization and worktree
ownership"): overlapping file sets run sequentially. Today Hermes decides by reading the
diffs by hand. This change makes the decision derived from git, with the same honesty
rules as the repo's other read-only bins: a missing input narrows, never optimizes; an
empty diff is `cannot assess`, never `parallelizable`.

## Goals / Non-Goals

**Goals:**
- A read-only bin that prints `parallelizable` / `collision` / `cannot assess` (with
  paths and reasons) for two refs against a base.
- High-risk families force `collision` even without literal path overlap.
- The workflow rule calls the bin before dispatching two changes concurrently.

**Non-Goals:**
- Deciding *order* of the sequential run, or approving anything (the gate stays
  reviewer/QA; the bin is informational about *ordering*).
- Any write: the bin never touches the tree.

## Decisions

### Decision: Literal overlap AND high-risk families

- **Literal:** the intersection of the two path sets is non-empty → `collision`, naming
  the paths.
- **Family:** declare high-risk families — `schema/migrations` (`schema.prisma`, `db/`,
  `migrate(s)?/`, `*.sql`), `openspec/`, `contracts/auth` (`auth`, `permissions`,
  openapi/contracts), `dependency manifests` (`package.json`, `bun.lockb`, etc). If each
  change touches the same family (any path in it), `collision` naming the family — even
  when the exact paths differ. Two concurrent worktrees both regenerating code from the
  same schema, or both editing the lockfile, corrupt each other's intermediate state.
- A schema change and an unrelated `src/ui` change do NOT collide: the family test is
  per-family overlap, not "any high-risk path collides with everything".

### Decision: `cannot assess` is a distinct non-zero verdict

Reuses the repo's honesty pattern: no base ref, a ref that does not resolve, or an empty
diff ⇒ `cannot assess` + reason + exit 2. An unmeasurable diff is never the optimistic
verdict.

### Decision: The bin stays read-only bash + jq; the fixture uses throwaway repos

Same bin/ pattern as `review-tier`/`run-trace`. For a realistic fixture, build two
throwaway git repos under `$TMPDIR` (a shared base commit, then branch A and branch B
with scripted file sets) and assert the three verdicts — that exercises the real
`git diff --name-only` path instead of mocking.

## Risks / Trade-offs

- **Risk:** the family list drifts from the rules. **Mitigation:** the same families are
  declared in the spec (source of truth); the bin prints the family that fired.
- **Risk:** the fixture repos rot. **Mitigation:** the suite builds them each run under
  `$TMPDIR`, like `fixtures/agency-next` already does.
- **Trade-off accepted:** per-family collision (not "any high-risk path collides with
  everything") may miss a rare cross-family race — accepted: over-blocking would silently
  serialize everything, which defeats the purpose of the parallel model.

## Delivery strategy

Measured after implementation; expect ~200-250 authored lines (bin ~110, fixture ~120,
rule edit + docs). Under the advisory budget; `single-pr`.
