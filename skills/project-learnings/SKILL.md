---
name: project-learnings
description: "Persistent per-project learnings, versioned with the code, not global."
---
<!-- hermes-add-skill: pattern adapted from gstack /learn (garrytan/gstack, MIT). -->

# Project learnings

Keep a durable, per-project record of what the project has learned, versioned **in the
repo** so it travels with the code and the PR — complementing (never duplicating) the
agent's global memory and the vault. What is specific to this project belongs here; what
is global stays in global memory.

## Storage

`.context/learnings.jsonl` in the project root — one JSON object per line.

Each entry:

```json
{"ts": "…", "kind": "lesson|pitfall|decision|pattern", "area": "<module/subsystem>", "summary": "<one line>", "detail": "<why — the 'because' that survives the session>"}
```

`kind` keeps them filterable; `area` ties them to code. The `detail` is the non-obvious
**why** (a gotcha, a workaround, an invariant) — the thing a future session would re-learn
the hard way.

## When to write

- A solution to a bug that took >1 attempt (record the root cause, not the symptom).
- A non-obvious project invariant or constraint that code doesn't show.
- A tooling / environment gotcha specific to this project.
- A decision that would otherwise be re-litigated.

## Managing

- **Review / search:** read the file, filter by `kind` / `area`, or search text.
- **Prune:** drop entries that are stale or superseded; keep the signal.
- **Export:** dump the current set where the user needs it.

## Rules

- **Never commit a secret**, a path with credentials, or live data into a learning.
- Learnings are committed as part of the change they belong to (they go in the PR), so they
  are peer-reviewed with the code.
- Keep entries atomic and one-line-summarized; the file is a signal ledger, not a log.
