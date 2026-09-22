## Why

The public repo mirrors `hermes-sdd-orchestration` but the copy drifted behind the live
`~/.hermes` skill: 180 lines vs 334 (live carries the accumulated pitfalls from real
sessions), three `references/` are missing, and — the sharpest gap — the mirrored skill
still teaches the pre-`change-collision` parallelization method ("union of touched paths
→ any overlap means sequential") while the rule it orchestrates already runs
`bin/change-collision` with `parallelizable | collision | cannot assess`. A skill that
teaches the old method and a rule that enforces the new one are the exact drift pattern
this repo exists to kill: the orchestrator may decide from the skill while the rule
lives in a file it is not guaranteed to load.

The mirror is a strict subset of live (verified: repo ⊃ live = 0 lines; live ⊃ repo =
the 154-line difference), so the baseline is a safe one-way copy, then teaching content
is added on top, and the result flows back to `~/.hermes` after merge.
