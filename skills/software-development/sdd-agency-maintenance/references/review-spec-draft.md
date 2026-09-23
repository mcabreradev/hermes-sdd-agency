# Reviewer checklist for an agency change's artifacts

Two review stages of an agency change, and the defect classes each one surfaces. In both,
`openspec validate` green is not a pass — the CLI judges structure, never whether the artifacts
say what the author meant.

- **Proposal stage** (proposal + spec + design + tasks, no code, no implemented `- [x]`): the
  reviewer reviews the artifacts *as an implementable specification*.
- **Post-implementation stage** (the diff exists): the reviewer checks that what was built, the
  spec, and the measurements recorded in the artifacts still agree with each other.

Each class below carries the check that catches it.

## 1. Spec ↔ design contradiction (BLOCKER)

A requirement demands something the design explicitly rejects as out of scope, or a schema
the design pins down omits a field the requirement names. A builder with two contradictory
instructions cannot implement. After touching the spec, `grep` the whole change tree for
the contested token and confirm every residual mention is an exclusion (Non-Goals /
discarded alternative), **never** a requirement or a task.

## 2. Phantom capability (MAJOR)

`proposal.md` lists a capability under New Capabilities but the delta specs only cover a
subset. Archive then never materializes the promised capability. Cross-check each New
Capabilities entry against a real `specs/<cap>/spec.md` in the change; a new capability
must have its own delta with a `## Purpose`.

## 3. Behavior with no owning workflow (MAJOR)

A scenario promises behavior but no task wires it into the workflow that actually performs
it. The trap: the workflow that does the job already exists under a different name than
the change assumed (e.g. resume lives in `continue-change.md`, not `autonomous-change.md`).
READ the real workflow the change claims to touch before declaring wiring complete; the
Impact list and the tasks must both name it.

**Stage-bound variant:** when the requirement is bound to a *moment* ("at delivery", "before
closing", "on release"), the wiring must exist in the workflow that runs at that moment —
otherwise the mandate is unimplementable exactly where it matters. A delivery-time comparison
declared in the rule and wired into the review stage instead of `release-change` /`qa-change`
satisfies every grep a task's `verifies:` could run while no stage ever performs it. Grep each
named stage's own file for the step, and treat "declared in the rule, absent from the stage" as
the finding — the alternative fix is dropping the clause from the spec, not moving the rule.

## 4. Orphaned design consequence (MAJOR)

`design.md` says a `Consequences`/decision requires "X must be minted/threaded/updated" but
no task implements it and the supporting rule (e.g. the envelope in
`rules/orchestration.md`) is not in the task set. Every design consequence must map to a
task. A consequence that adds a field to the mandatory envelope needs a task that edits
that rule file, or the builder has no source for the field.

## 5. Verify that does not verify behavior (MAJOR)

A task whose `verifies:` is `grep -q "<token>" <file>` passes on a prose mention with no
behavior existing — the builder can tick `- [x]` without implementing, against the
evidence-first rule. For wiring tasks, require a verifies that *exercises the artifact* on
a fixture (append to it, confirm the resulting entry parses with `jq`), not a grep. For a
task that touches several docs, the verify must `grep` each doc, not only the first.

## 6. Mutable file inside the release fingerprint (MAJOR)

A log/file that grows during a run and lives in the working tree (untracked, un-ignored)
breaks `no-smoke-worktree` — it fingerprints via `git add -A`, which includes untracked
files, so the hash differs between reviewer and release and `rules/quality.md` treats that
diff as a release BLOCKER. Fix: gitignore the path and add a task that edits `.gitignore`;
document the interaction in the design Risks.

## Post-implementation classes (the diff exists)

Seven more that only surface once code is on the branch. All seven were found by one reviewer
dispatch against a change whose specs were green and whose fixtures passed.

### 7. A requirement names an actor who may not perform it (MAJOR)

A requirement reads "the `<role>` MUST `<action>`" while that role's own file forbids the
action, and points at a record ("the change's progress evidence") that no template, field or
artifact defines. The requirement is then unimplementable *and* unverifiable: the reviewer has
to mark its scenario uncovered even though the outcome was achieved by someone else.

**Check:** for every requirement naming a role, read that role's file and the workflow that
invokes it; for every artifact a requirement mentions, `grep -rn '<the phrase>'` the repo and
require a real home (a template field, a report section, a rule). Fix by naming the actor who
owns the action and giving the record a concrete home.

### 8. A declared table whose machine form cannot match a row (MAJOR)

An enumerated table in a rule file and the regex/command implementing it disagree, so one row
is unmatchable and the check silently passes. The rule in the maintenance SKILL.md ("When a rule
is stated as a table, its machine form must agree row by row") is the fix; in the review it
appears as a row-by-row audit — walk the table and show each row matching.

### 9. A declared file list that is not the real diff (MINOR)

The proposal's Impact section names some touched files and omits others, so the repo's own
declared-diff check fires on the change. **Check:**
`for f in $(git diff --name-only main...HEAD | grep -v '^openspec/'); do grep -q "$f" proposal.md || echo "UNDECLARED: $f"; done`
and make the list equal the diff minus the change's own artifacts.

### 10. Recorded measurements that do not reproduce (MINOR, but it undermines a decision)

`design.md` cites numbers (line counts, ratios) measured *before* the artifact that carries
them was final, so they are stale. Under an evidence-over-claim rule this invites re-litigating
the decision they justified. **Check:** re-run the exact command named and compare; the durable
fix is to quote the command beside the numbers so they cannot go stale silently.

### 11. A detector that covers some forms of a defect and not others (MAJOR)

A frontmatter/format linter that flags `description: |` but not `|2-`, or that truncates a
multi-line scalar instead of flagging it, reports a confident verdict on input it never parsed.
**Check:** build hostile fixtures for every legal spelling of the shape (indentation
indicators, chomping indicators, folded vs literal, CRLF, quoted flow collections) and assert a
verdict per spelling — not one happy-path case.

### 12. Parsing that ignores an input dimension entirely (MINOR)

CRLF line endings corrupting a field, quoted collection elements printed with their quotes,
records with no attribution to their source root, repeated/nested inputs double-counted. These
are the shapes a hand-rolled parser misses when only LF, unquoted, single-root inputs were
fixtured. **Check:** one fixture per input dimension the tool's own `--help` claims to accept.

### 13. Implementation surface that traces to no requirement (MINOR)

An extra marker, an extra exit status, a summary line on stderr — real behavior with no
requirement behind it, in a repo whose `project.md` says every implementation must trace back to
one. It also makes coverage undecidable: a scenario's THEN names one marker while the code emits
another. **Check:** enumerate what the tool actually emits and confirm each is named in the
delta spec; extend the spec or drop the surface.

## Minor hygiene

- Pin a single format (NDJSON vs JSON array vs lines) — an either/or lets writer and reader
drift.
- Keep the spec's field set equal to what the schema/rule pins (what a requirement
enumerates must match what `rules/` declares).
- Enumerate the full envelope status vocabulary in a scenario that lists statuses — listing
only some drops the blocking ones (`approved`, `changes-requested`, `pass`, `fail`).

## Re-review after the repair

Dispatch the reviewer again and require each prior finding CONFIRMED closed with a fresh
grep/run, not a self-reported "fixed" — brief it with the numbered prior findings and ask for a
verdict plus the observed output per finding. Also brief it to attack the *fix*: a repair is new
code, and the surface it touched is where a regression lands (a corrected pattern that now
over-matches is the classic). Fold any remaining MINOR/NIT (e.g. "which of several logs is the
active one") into the design as a stated rule before the change is implementable.
