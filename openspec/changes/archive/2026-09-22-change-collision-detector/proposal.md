## Why

The agency already has the parallelism rule: two changes with overlapping file sets run
sequentially, never in parallel (`rules/orchestration.md`, "Parallelization and worktree
ownership"). But the collision decision is made **by re-reading the diff by hand** each
time Hermes is about to dispatch two changes — the same diff, read twice, can be
classified differently by context or mood, and the review has no reproducible artifact to
check against.

The ask: make parallelism a **derived decision** — a read-only bin that answers "do these
two changes collide?" from the file sets alone (`git diff --name-only` per branch), with
a declared high-risk class list that forces `collision`, and an honesty rule: a diff that
cannot be measured is `cannot assess`, never `parallelizable` by default.

## What Changes

- New `bin/change-collision` (bash 3.2 + `jq`, read-only): given two refs and a base,
  prints `parallelizable` / `collision` / `cannot assess` with the overlapping paths and
  the high-risk classes that forced the verdict.
- `rules/orchestration.md`: the parallelization section now requires Hermes to **run the
  bin** before dispatching two changes concurrently (the rule stays; the decision becomes
  reproducible). High-risk classes: schema/migration, auth/contracts, `openspec/`,
  dependency manifests — overlap there is `collision` even if the path sets differ.
- New OpenSpec capability `parallel-execution`; fixture suite
  `fixtures/change-collision/` with parallel / collision / cannot-assess cases.
- No runtime code beyond the bin; no new dependencies.

## Impact

- `bin/change-collision`, `fixtures/change-collision/check.sh`,
  `fixtures/change-collision/roots/` (two throwaway sibling repos with the collision
  shapes), `rules/orchestration.md`, `docs/sdd-feature-lifecycle.md` (mention),
  `CHANGELOG.md`.
- No change to the gate or blocking authority: the bin is informational — it decides
  *ordering*, never approval. A `collision` verdict means "run sequentially", not
  "blocked".
