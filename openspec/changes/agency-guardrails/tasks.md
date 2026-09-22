## 1. Sensitive-path deny list

- [ ] 1.1 Add the `## Sensitive paths (deny list)` section to `rules/project-boundaries.md`, enumerating the literal patterns (`~/.ssh/*`, `**/.env*`, `**/*.pem`, `**/*.key`, `**/*.p12`, `**/*.pfx`, `**/secrets/*`, `~/.aws/credentials`, `~/.credentials/*`, `~/.config/gh/hosts.yml`, `~/Library/Keychains/*`) and the prohibition: no agent, bin or workflow reads, prints, copies into a report or commits them. Verifies: `grep -q 'Sensitive paths' rules/project-boundaries.md && grep -c '~/.ssh/\*' rules/project-boundaries.md`
- [ ] 1.2 State in the same section that the list is enumerated (never inferred), Hermes-owned, and that an agent may not narrow it. Verifies: `grep -qi 'never inferred\|enumerated' rules/project-boundaries.md`
- [ ] 1.3 Add the enforcement rule to `rules/quality.md` (reviewer greps the declared diff's paths against the deny list; a match is a `BLOCKER` recorded with `path:line`, an empty result is recorded as the evidence line). Verifies: `grep -qi 'deny list' rules/quality.md && grep -qi 'BLOCKER' rules/quality.md`
- [ ] 1.4 Add the deny-list grep as an explicit step of the reviewer brief in `workflows/review-change.md` and to the `reviewer` agent's Done criterion in `agents/reviewer.md`. Verifies: `grep -qi 'deny list' workflows/review-change.md && grep -qi 'deny list' agents/reviewer.md`
- [ ] 1.5 Regression check with real paths: run the deny-list grep over a fixture list containing a matching and a non-matching path and confirm it reports the match and not the other. Verifies: `fixtures/sensitive-paths/check.sh` exits 0 and prints exactly one `MATCH` line for the deny-listed fixture path

## 2. `bin/skill-registry`

- [ ] 2.1 Add `bin/skill-registry` (bash 3.2, read-only): accepts one or more `--root <dir>` (default `~/.hermes/skills`), walks each root for `SKILL.md`, prints a stable record per skill with the exact absolute `SKILL.md` path, `name`, `description` and tags. Verifies: `bash -n bin/skill-registry` and `bin/skill-registry --root fixtures/skill-registry/roots/valid` exits 0 printing each fixture's exact path
- [ ] 2.2 Implement the frontmatter defect detection (block-scalar `description: |`, missing/empty description, missing frontmatter block) as an explicit per-record marker instead of a plausible-looking description. Verifies: `bin/skill-registry --root fixtures/skill-registry/roots/defective` prints one record per defective fixture carrying its own marker (`BLOCK-SCALAR` / `MISSING-DESCRIPTION` / `NO-FRONTMATTER`)
- [ ] 2.3 Make multi-root invocation work with each record identifying its root, and keep output deterministic (sorted) across runs. Verifies: two runs with `--root valid --root defective` produce byte-identical output (`diff <(...) <(...)` empty) and both roots appear
- [ ] 2.4 Add the fixtures: `fixtures/skill-registry/roots/valid/<skill>/SKILL.md` (2+ well-formed skills with tags and one without tags) and `fixtures/skill-registry/roots/defective/<skill>/SKILL.md` (one per defect class). Verifies: `find fixtures/skill-registry -name SKILL.md | wc -l` matches the declared count
- [ ] 2.5 Document the command in `README.md` (a `bin/` entry) and in `INSTALL.md` where the `bin/` directory is described. Verifies: `grep -q 'skill-registry' README.md && grep -q 'skill-registry' INSTALL.md`

## 3. Work-unit commits and delivery strategy

- [ ] 3.1 Add the work-unit commit rule to `rules/coding.md`: each coherent work unit closes with its own Conventional Commit carrying its tests and docs; a single-unit change is not split artificially. Verifies: `grep -qi 'work unit' rules/coding.md`
- [ ] 3.2 State the advisory ~400 authored-lines heuristic in `rules/coding.md` (additions + deletions, generated excluded) with the explicit list of what it never justifies (cosmetic deletions, omitted/weakened tests, minification, gratuitous abstractions, artificial splits). Verifies: `grep -q '400' rules/coding.md && grep -qi 'advisory\|heuristic' rules/coding.md`
- [ ] 3.3 Add the delivery-strategy step to `workflows/implement-change.md`: choose and record `single-pr` / `chained-pr` / `split-change` before opening the next PR when the running authored-line count crosses the budget, and record slice boundaries. Verifies: `grep -q 'chained-pr' workflows/implement-change.md && grep -q 'split-change' workflows/implement-change.md`
- [ ] 3.4 Add the budget forecast + strategy line to the stage-closure checklist of `workflows/implement-change.md` and reference the rule from `workflows/release-change.md` where the delivered shape is closed. Verifies: `grep -qi 'authored' workflows/implement-change.md && grep -qi 'work unit\|chained' workflows/release-change.md`

## 4. Closure

- [ ] 4.1 `openspec validate "agency-guardrails" --type change --json` reports no ERROR and every `ℹ INFO` is read and reported. Verifies: the command's JSON with `summary.totals.failed == 0` quoted in the report
- [ ] 4.2 Run the repo's real checks on the touched shell: `bash -n` on every `bin/` script and the fixture script, plus `bin/no-smoke-worktree` still exits 0. Verifies: quoted exit codes and the fingerprint value
- [ ] 4.3 QA the installer still carries the new bin to a temp prefix (`install.sh` with a temp `--prefix`), confirming `skill-registry` lands executable. Verifies: `test -x <temp-prefix>/bin/skill-registry` and the installer's exit code
- [ ] 4.4 Update `CHANGELOG.md` `[Unreleased]` with one short entry per guardrail, and note the Gentle-AI (MIT) attribution alongside the existing gstack line. Verifies: `grep -q 'skill-registry' CHANGELOG.md && grep -q 'gentle-ai' CHANGELOG.md`
- [ ] 4.5 Tick every task only against its own verification command, then archive + sync the change (separate follow-up per the repo's standing rule). Verifies: `openspec instructions apply --change "agency-guardrails" --json` with `progress.remaining == 0`
