# Workflow: release-change

Closes the change: release consistency, notes, OpenSpec archiving and final repo
state.

- **Agents:** `release`
- **Rules:** `rules/openspec.md`, `rules/quality.md`, `rules/orchestration.md`
- **Output:** project notes/changelog, archived change, main specs
- **Personas/method:** `git-workflow-manager` · `commit-smart` · `legacy-modernizer`/`technical-debt-manager` if the change is a refactor.
  synchronized, final report.

## 0. Preflight (Hermes)

```bash
cd <project-root>
test -f openspec/project.md || echo "MISSING project.md → initialize-project (blocking)"
openspec context --json                                  # root.path == <project-root>
openspec status --change "<name>" --json
openspec validate "<name>" --type change --json
openspec instructions apply --change "<name>" --json     # all tasks at - [x]
git log --oneline -20
```

- [ ] Review `approved` and QA `pass` (or findings accepted and recorded by Hermes).
- [ ] All tasks complete. If any `- [ ]` remains, it is not archived: it is decided between
      completing it or removing it from scope (new change).
- [ ] `validate` without `ERROR` and with the `ℹ INFO` read (would archive reject it?).

Confirm with the user in advance the authorized action level: only prepare the release,
commit/tag?, publish? Without explicit authorization, the agent does not publish or tag.

## 1. Release closure (`release` agent)

Brief: project root, change, repo versioning policy (if any), concrete
authorization, changelog/notes paths and the commit history as the source.

The agent: checks the diff ↔ notes consistency, applies the project's versioning (or asks
for a decision if it is not declared), writes the changelog in the format the repo already uses, and
—if authorized— archives the change.

### Docs follow what shipped (`document-diataxis` + drift check)

- Build a **Diataxis coverage map** for the change (tutorial / how-to / reference /
  explanation, per `skills/document-diataxis`). A new capability with uncovered quadrants is a
  **documentation debt** recorded in the report, not silently ignored.
- Cross-reference the diff: any doc (README / architecture / contributing / project doc)
  that contradicts what shipped is **drift** and is fixed here or recorded as debt.
- **Diagram drift**: if the change alters architecture, the system/architecture diagram must
  change to match — or the stale diagram is flagged explicitly (see `diagram-triplet`).
- Polish the changelog voice with a sell-test: each entry states what was added/fixed and why
  it matters, not a raw commit title dump.

### Bind the closed tree

- Record the **`no-smoke-worktree` fingerprint** of the tree being released, and compare it
  against the reviewer/QA fingerprints recorded in earlier stages. A mismatch against those
  stages is evidence the shipped tree was validated on different content → stop and
  re-review/re-test before closing (see `rules/quality.md`).
- **Compare the review snapshot** (`rules/quality.md`, "Frozen review candidate") on the tree
  being closed: `<agency-bin>/review-snapshot --compare <snapshot>` must report `MATCH`. A
  `MISMATCH` (or a "cannot assess" for a record that no longer reproduces) is the same blocker
  class as the fingerprint mismatch above — the review describes content that is not being
  released.
- Confirm the delivered shape matches the **recorded delivery strategy** (work units and the
  authored-lines budget, `rules/coding.md` / `workflows/implement-change.md`): a `chained-pr`
  change closes as its recorded chain of PRs, not as one merged blob, and an unrecorded
  strategy is reported as debt rather than inferred.

## 2. OpenSpec archiving (if applicable)

```bash
openspec archive "<name>" --yes
openspec validate --archived --json       # 0 failed
openspec list --specs --json
ls openspec/changes/archive/
```

- The main specs sync is inline; do not archive with a sync in flight.
- If the change CREATES a capability and its delta did not bring `## Purpose`, the new spec is left
  with a TBD Purpose: write it immediately (`templates/spec.md`).
- Verified in v1.13.0: with `## Purpose` in the delta, archiving preserves it.
- If `archive` aborts ("structurally invalid", "Aborted. No files were changed."), the destination
  spec is corrupt (delta header in `openspec/specs/`): it is reported to Hermes, it is not
  patched by hand inside the release.
- Verify the inert-spec trap in the touched capabilities:
  `grep -rl "^## ADDED Requirements" openspec/specs/*/spec.md`. If a file appears, it is
  reported to Hermes (the fix belongs to the main specs, outside the agent's scope).

## 3. Final repo state

```bash
git status --porcelain
git diff --stat
```

- Code, specs and notes coherent; no stray files or run temporaries.
- Commit/push/tag only if authorized, following the message style of the history.

## 3b. Trace closure (if the run is traced)

If the preflight minted a `runId` for this run, append the release stage's **trace
entry** to the run log (`rules/observability.md`, schema + append rules) before the
final report:

```bash
printf '%s\n' '{"timestamp":"<UTC ISO-8601>","runId":"<runId>","change":"<name>","stage":"release-change","kind":"closed","status":"done","filesCreated":[],"filesModified":[],"evidence":"openspec validate --archived --json: 0 failed; <fingerprint>","blockers":[],"decisions":[],"nextRecommendedStep":"pr-review-or-human-merge"}' >> reports/<runId>.jsonl
```

- The log is **gitignored** by design (`reports/run-*.jsonl`): the growing trace must
  never enter `bin/no-smoke-worktree`'s `git add -A` fingerprint — the fingerprint the
  release compares against earlier stages must be taken **before** the append, and the
  append must not be committed. A trace that changes the reviewer/release fingerprints
  is a blocking defect (`rules/observability.md`, `rules/quality.md`).
- Verify the append: `bin/run-trace --file reports/<runId>.jsonl` shows the release
  entry as `last:` (exit 0).

## Output

Final report (`templates/final-report.md`) with: what was released, version, notes and paths,
archived change (name and path in `changes/archive/`), new/updated capabilities,
declared debt, pending findings, lessons for the global system (rules/workflows to
improve) and the user's next step.

## Typical errors

- Archiving with incomplete tasks: a change is left "completed" that is not.
- Leaving the `Purpose` at TBD: the new spec is left unusable.
- Publishing without explicit authorization.
- Not recording the debt: the next change discovers it again.
