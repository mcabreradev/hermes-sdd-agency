## Why

The public surfaces drifted behind the process they ship. The homepage
(`index.html`, GitHub Pages from `main`), `README.md` and `INSTALL.md` still claim:

- **5 evidence bins** — the repo ships **7** (`run-trace` and `change-collision`
  arrived in phase 3; `docs/evidence-bins.md` documents only 5 of them).
- **60 skills** — the tree has **65** (the 5 mirrored agency process skills in
  `skills/software-development/` + `skills/autonomous-ai-agents/`).
- **26 PRs merged** / **92 pinned test cases** — the repo is at **39 merged PRs** and
  **108 pinned cases** (16+7+11+27+9+25+13).
- The homepage loop ordering is stale: it shows `pr-review` as step 8 before
  `release`, while the canonical loop (`docs/sdd-feature-lifecycle.md`,
  `workflows/`) runs `release-change` → `pr-review` (post-open).

Per `rules/orchestration.md`, the fix is a docs change: **no behavior-bearing code
touches the loop** — the diff is prose, numbers, and one HTML loop step reorder.
