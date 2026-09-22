## Why

Three guardrails the agency currently enforces by prose and judgment are worth making
mechanical. "Do not read secrets" is a rule an agent can rationalize past; nobody has a
verifiable inventory of the installed skills; and the build stage can accumulate a whole
change into one diff too large to review honestly. Gentle-AI (Gentleman-Programming, MIT)
ships all three as host-agnostic ideas — an explicit sensitive-path deny list, a skill
registry, and work-unit commits with chained PR slicing. None of them needs its Go binary or
its runtimes, and none of them duplicates what this agency already has.

## What Changes

- `rules/project-boundaries.md` gains a **sensitive-path deny list**: the named path classes
  no agent, bin or workflow may read, print or copy into a report, plus the rule that binds
  the reviewer to grep a declared diff against it.
- New **`bin/skill-registry`** — a read-only bash tool that discovers every `SKILL.md` under
  the configured skill roots and prints the verifiable inventory (exact path, description,
  tags), flagging defective frontmatter instead of hiding it.
- `rules/coding.md` and `workflows/implement-change.md` gain **work-unit commits**: one
  coherent unit per commit with its tests and docs, and a declared authored-lines budget that
  switches a growing change to chained/stacked PRs instead of one unreviewable diff.

## Capabilities

### New Capabilities

- `sensitive-paths`: the deny list of paths never read, printed or committed by the agency,
  and how it is enforced on evidence.
- `skill-registry`: the read-only command that produces the verifiable inventory of installed
  skills, including detection of defective frontmatter.
- `methodology/work-unit-commits`: commit granularity at the build stage, the authored-lines
  budget as a planning heuristic, and chained/stacked PR delivery when a change exceeds it.

### Modified Capabilities

None — this change introduces new requirements only. No existing capability's behavior
changes.

## Impact

- **Files modified:** `rules/project-boundaries.md`, `rules/quality.md`, `rules/coding.md`,
  `workflows/implement-change.md`, `workflows/review-change.md`, `workflows/release-change.md`,
  `agents/reviewer.md`, `templates/final-report.md`, `README.md`, `INSTALL.md`, `CHANGELOG.md`.
- **New files:** `bin/skill-registry`; `fixtures/sensitive-paths/` (`check.sh`,
  `deny-list-match.txt`, `ordinary-paths.txt`); `fixtures/skill-registry/roots/valid/`
  (`fixture-valid-tagged`, `fixture-valid-quoted`, `fixture-tags-quoted`, `fixture-crlf`) and
  `fixtures/skill-registry/roots/defective/` (`fixture-block-scalar`,
  `fixture-block-indicator`, `fixture-missing-description`, `fixture-multiline-continuation`,
  `fixture-plain-continuation`, `fixture-no-frontmatter`, `fixture-unclosed-frontmatter`), each
  holding a `SKILL.md`.
- **No runtime dependency added** — bash 3.2 + `find`/`grep`/`sed`/`awk` only, per the project's
  "no runtime beyond Bash + OpenSpec CLI" architecture principle. `install.sh` needs no
  change: it already copies `bin/` wholesale (verified in QA by a temp-prefix install).
- **Concepts adapted from** [Gentleman-Programming/gentle-ai](https://github.com/Gentleman-Programming/gentle-ai)
  (MIT), same attribution pattern the repo already uses for `garrytan/gstack`. Ideas only —
  no code, no binary, no runtime ported.
