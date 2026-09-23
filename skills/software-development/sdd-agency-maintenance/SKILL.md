---
name: sdd-agency-maintenance
description: "Use when maintaining Migue's SDD agency under ~/.hermes."
metadata:
  hermes:
    tags: [sdd, openspec, agency, bundles, personas, maintenance]
    related_skills: [hermes-sdd-orchestration, openspec-sdd]
---

# SDD agency maintenance

Migue (Spanish-speaking) runs a **custom SDD orchestration agency** under
`~/.hermes/{agents,workflows,rules,templates,skill-bundles}`: Hermes is the sole
orchestrator, the OpenSpec CLI is the gate, and each project owns its specs. This skill
is for *maintaining that instance* — extending it, auditing it, and keeping its levels
consistent. The bundled `hermes-sdd-orchestration` skill covers the protocol; this one
covers the sysadmin. Load it before editing anything under those `~/.hermes` dirs.

**Language contract (standing rule):** every agency doc, spec, commit, PR and report is
English. Only the *conversation with the user* is Spanish, without exception.

## The three task-size levels (decision table)

Classification is decided by **Hermes, never by the agent**. This gate lives in
`rules/openspec.md` ("Task size and fast path") and `rules/sdd.md`.

| Level | Scope | Path |
|---|---|---|
| Cosmetic | No observable behavior change (typo, indent, rename local) | Direct edit, **no OpenSpec change** |
| Minimal | Bounded behavior (bug fix, visible error message) | **OpenSpec change with `skip_specs: true`** + proposal + task + **regression test that fails without the fix** |
| Feature | Business rule / contract / architecture | **Full agency loop** (idea → … → release), delta spec, personas, formal QA |

Rules that hold the fast path honest:

- "It's small" never skips the OpenSpec change when behavior is involved — only the
  requirement deltas are omitted; the change is still validated, applied and archived.
- A one-line fix always carries its regression test (see `rules/testing.md`).
- If work at the cosmetic/minimal level discovers any observable behavior change, escalate
  to the next level — behavior never goes straight to the tree unclassified.

## Slash bundles: how to add a level or stage command

Bundles live in `~/.hermes/skill-bundles/<name>.yaml`. They **auto-register** — no reload
step needed — verify with `hermes bundles list` and grep the new name.

Each YAML has four keys:

- `name` — the bundle name (lowercase)
- `skills` — normally `[hermes-sdd-orchestration, openspec-sdd]`; cosmetic-level bundles load
  only `hermes-sdd-orchestration` (no OpenSpec mechanics needed)
- `description` — one line for the `bundles list` table
- `instruction` — a self-contained protocol the agent follows when invoked (resolve root,
  preflight, workflow/role files, personas, delegate, verify, close, and which level it is).
  State the level explicitly (COSMETIC / MINIMAL / FEATURE) and what escalates up.

Existing stage bundles: `/agency` (full), `/init-project`, `/idea`, `/architecture`,
`/plan`, `/implement`, `/review`, `/qa`, `/release`. Level bundles mirror the table above:
`/feature` (full loop), `/bugfix` (minimal fast-path), `/fix` (cosmetic).

### Skill-name resolution inside a bundle (pitfall)

The `skills:` list is resolved per-name with the same collision logic as `skill_view`.
A bare name that exists in MORE than one search dir (local `~/.hermes/skills`, and the
`skills.external_dirs` like `~/.agents/skills` / `~/.claude/skills`) is ambiguous → that
member is skipped with a note, silently — the bundle still loads the rest, so the failure
is easy to miss. Before adding a skill to a bundle, check names collide:

- `brainstorming` collides (3 copies: ~/.agents, ~/.claude, and the superpowers plugin).
  Reference the plugin copy as `superpowers:brainstorming` (unique, no collision).
- Unique names (grilling, domain-modeling, grill-with-docs live once in ~/.agents) load
  bare.
- A wrapper skill may delegate to others (`grill-with-docs` just says "call grilling and
  domain-modeling"); list the members too so they load as direct bundle members and don't
  depend on the wrapper making a second call.

Edit bundles with `patch` (write_file refuses: a sibling subagent may have touched the file
since last read). Verify an edit actually resolved — never trust "No changes" from
`hermes bundles reload`:

```bash
hermes bundles list                                   # skill count per bundle in the table
cd ~/.hermes/hermes-agent && PYTHONPATH=. ./venv/bin/python -c "\
from agent.skill_bundles import build_bundle_invocation_message\n\
msg, loaded, missing = build_bundle_invocation_message('/name')\n\
print('LOADED', loaded); print('MISSING', missing)\n"   # the venv is ./venv, not .venv
```

## Auditing installed personas

Personas live in **`~/.hermes/skills/agents/<slug>/SKILL.md`**, not in `~/.hermes/skills/`
root. Checking the wrong root reports every persona missing — always search `skills/agents/`.

```bash
cd ~/.hermes/skills/agents; for d in */; do d="${d%/}"; f="$d/SKILL.md"; \
  head -30 "$f" | awk -v n="$d" '/^description:/{print n" :: "NR\": \"$0; ok=1} \
  END{if(!ok) print n" :: NO-description (frontmatter missing?)"}'; done
```

Check the head of each role's SKILL.md (`awk 'NR<=8'`) to confirm the frontmatter closes.
Three silent-routing defects to catch (from the aitmpl conversion pipeline):

- **No frontmatter** — file starts at `#`; the skill loads but routes to nothing.
- **Block-scalar description** (`description: |` + indented text) — the literal `|` becomes
  the description.
- **Non-actionable description** — an agent-role phrasing like `"You need …"` instead of an
  action-verb trigger (`"Validates real behavior against the spec scenarios…"`). The skill
  loads but weakly routes into the stage's context.

Personas are **user-owned**, so `skill_manage` refuses to patch them; edit
`skills/agents/<slug>/SKILL.md` directly with `patch`. Fix the description in place, don't
append an update note. The fix must leave the trigger phrased as the action the stage
performs, not describe the persona itself.

## Build-stage method is fixed by the agency rules

The implement stage's method lives in the agency's own `rules/testing.md`,
`agents/builder.md`, `workflows/implement-change.md` — and for Migue the semantics are
**TDD as a hard rule for behavior-bearing code, not a "default with agent discretion"**.
He pushed back once when a change framed TDD as "default, skip with a justified exception
at the agent's judgment": for backends, business logic, API endpoints and bug fixes the
rule is unconditional test-first (RED→GREEN→REFACTOR). Only code with no behavior to prove
(config, generated code, glue, throwaway prototypes) is declared `not applicable` with a
reason — never a silently skipped default. DDD, by contrast, stays a technique the
architect applies only when the domain merits it (never forced on thin behavior). When
editing those agency files, preserve that hard-rule framing; wording that re-introduces
agent judgment on skipping backend TDD misrepresents the standing preference.

## Exporting / publishing the agency

The whole system is **process**, so it exports portably as a git repo: `agents/`,
`workflows/`, `rules/`, `templates/`, `docs/`, `bin/`, `skill-bundles/` and
`skills/agents/` copy cleanly. Exclude on purpose: `config.yaml` (machine settings), `memories/`
(user-only), `.env`/secrets, and any project contents. Ship a README (what's inside,
install path, the gate, first-run calibration) + INSTALL.md + LICENSE.

**Public-repo PII trap (verified):** process files that look clean still leak the user.
Before pushing anywhere public, grep the copied tree — a public push is near-irreversible
(revertable, never the other way):

- `rules/` carry real absolute example paths (`/Users/<name>/Workspace/...`) and, after a
  `rules/sdd.md` edit, the user's real name in the language contract. Replace with
  placeholders (`<project-root>`, drop the name).
- Every persona `SKILL.md` carries the aitmpl pipeline footer `Converted from
  <abs-path>/<name>.claude/agents/<slug>.md by hermes-add-agent` — that is the user's
  home path in every one of ~20 files. Rewrite to a relative `~/.claude/...` form.
- Validate the `skill-bundles/*.yaml` after copying (parse each), not before.
- **`bin/` ships too, and `install.sh` must list it in `PROCESS_DIRS`** (agents workflows
  rules templates docs **bin**) or the binaries never reach the target home. The README
  tree, INSTALL copy list, and INSTALL "keep in sync" list must all mention `bin/` as well
  — three separate places, all easy to forget when adding a first bin.

Run the sanitize check *after* the copy, on the export tree (not the live source), then
re-scan for the real name, home path, and any `Converted from` remains before committing.

### Documenting the agency (public docs and the landing page)

When Migue asks for marketing-style documentation ("explica paso a paso lo que tenemos, casos
de uso, ejemplos, bien marketinero y profesional"):

- **Run the bins and paste their REAL output** — a step-by-step guide must show actual command
  output (`no-smoke-worktree`, `review-snapshot --base …`, `review-tier`, `agency-next`,
  `skill-registry --root …`), never invented or prettified transcripts. Real numbers (bundle
  count, skill count, tiers) come from `ls | wc -l` and live runs, not from memory.
- **A parked draft is not a shipped feature — never document it as live.** The public README,
  FAQ, lifecycle and landing once described `run-trace` / `rules/observability.md` /
  `reports/run-<id>.jsonl` (a parked telemetry draft, never merged) as if they existed; a
  site visitor sees promises that fail on first use. Before writing or updating any agency doc,
  grep the cited bins/rules/workflows/templates for actual existence in the repo and keep only
  what merges really delivered. Landing page, README and FAQ drift independently — every count
  ("all 12/13 bundles" vs the real 15) and every Advanced-card claim must be re-verified
  against the tree whenever a feature lands.
- **Read BOTH public surfaces in full before writing — the README and the landing
  (`index.html`) have different structures and drift apart in coverage; the same benefit
  written on both surfaces reads as filler.** The landing is an icon-card grid (each benefit a
  `.use` card with an inline SVG + one `<p>`), the README is prose sections — write what each
  surface lacks instead of duplicating. When the landing already carried six benefits cards,
  ship only the angles it had not (nine roles without salaries, discipline that doesn't depend
  on mood, the company that stops living in your head) as cards 7–9, and give the README its
  own `What it buys you` section rather than a copy of the cards.
- **Frame benefits against the operator's pains, not the process abstractions.** The framing
  Migue praised and asked to ship mapped each benefit to a concrete failure the solo developer
  running a one-person company feels: amnesia → state in files, self-reporting → evidence as
  hashes, mood-dependent discipline → "the process doesn't take a day off because you ran out
  of focus", one-man company → nine roles with no salaries and a repo that outlives your head.
  That personal-copy framing is the content to ship; the honest limit ("the loop has not run
  end-to-end yet") stays in the conversation, never in the public artifact.
- **Verify a landing edit structurally, no browser.** The repo has no CI and no HTML linter,
  so after editing `index.html` run a one-liner that counts `<section>` vs `</section>`
  (equal, and their total unchanged), `<div` vs `</div>` (balanced) and the `.use` cards
  within the edited section's slice, then `git diff --stat` to confirm the touched lines match
  the intent — that is the whole gate for static HTML.

### Commits and the PR body (publishing the agency)

- Commit messages follow the repo's `type(scope): msg` history style, one theme per commit;
  group the change into coherent commits (one per concern) and `git mv` for renames so the
  exec bit survives.
- **Don't pass a PR body through a shell heredoc** — backticks inside the body are
  command-substituted and the body corrupts silently while the PR still opens. Write the
  body to a temp file first, then `gh pr create --body-file <tmp>` (and `gh pr edit` on fixups).
- **The same substitution trap applies to `git commit -m`.** A backtick-quoted word in the
  message is eaten by the shell and the commit lands with a hole in its subject, silently.
  Write every message to a file and commit with `git commit -F <tmpfile>`. The message is part
  of the artifact under review; a mangled subject is a defect, not a cosmetic slip.
- **Slicing a change into work units: stage explicit paths, never `git add -A`.** After a
  `git reset --soft` the whole tree is staged, so a later `git add -A` sweeps every unit into
  one commit and the intended structure is gone. Stage the unit and commit it in the same
  command, naming both: `git add <unit paths> && git commit -F <msg> -- <unit paths>`.
  Verify the result with `git log --oneline <base>..HEAD` + `git show --stat` per commit before
  moving on; a collapsed unit is cheapest to fix immediately, not after the review.
- When the PR touches `~/.hermes` bundles, the *live* skill-bundle copy diverges from the
  repo copy — only the repo copy is versioned, so edits to a bundle are two writes (live
  `~/.hermes/skill-bundles/` and repo `skill-bundles/`).

## Merging a PR does NOT update the live agency (repo → live sync)

The git repo (`~/Workspace/migue/hermes-sdd-agency`, the public export) and
`~/.hermes/` (the instance that actually orchestrates sessions) are **two
separate states**. Merging a PR updates the repo only — until you sync, `~/.hermes`
silently keeps running the OLD rules/skills/bins, so `no-smoke-worktree`, Diataxis,
report-only QA, etc. don't exist for your real projects. The user's INSTALL.md says
"re-copy to ~/.hermes when you change a rule" — read that direction as maintenance, not
just install.

Use the `git-worktree-isolation` skill to cut PR branches; it is user-owned (edit its rules via `hermes curator adopt`). One trap here: `git worktree add -b agent/<slug>` fails "branch already exists" when you probed the change in the main tree first with `git checkout -b agent/<slug>` and then restored `main` — the branch survives the checkout-back, so recover with `git worktree add <path> agent/<slug>` against the existing branch instead of re-adding `-b`.

After merging an agency PR, complete the loop:

```bash
# in the repo, after `gh pr merge`
git pull --ff-only origin main                       # get the merge onto the main tree
# sync ONLY what the PR changed into ~/.hermes — merge, never wipe
cp -R skills/<new-skill> ~/.hermes/skills/            # each new SKILL.md dir
cp rules/quality.md ~/.hermes/rules/                 # or per-file that the PR touched
cp workflows/<edited>.md ~/.hermes/workflows/
cp bin/<tool> ~/.hermes/bin/ && chmod +x ...          # bins must be executable
cp install.sh ~/.hermes/
```

**Before any `cp` into `~/.hermes`, check the line counts of the source and target** — the repo copy of a skill and the live copy can be radically different in size. The public repo export of `hermes-sdd-orchestration` is the THIN upstream version (~169 lines, no pitfalls), while the live `~/.hermes` copy is the RICH curated one (300+ lines carrying all the hard-won pitfalls). `cp` from the repo (or a worktree cut from it) blindly overwrites the live file and wipes the curated pitfalls — exactly what happened when syncing via the worktree. For such a skill, do NOT copy the file: re-apply only your one change to the live copy directly (patch), or compare line counts first and keep the richer copy. The `diff -q` check below only proves the copies match; if they are *supposed* to diverge, `cp` is the wrong tool.

Verify the line count **both before AND after** the sync — the damage shows only as the target shrinking (e.g. 300+ → ~170). A `cp` from a worktree cut off an *older* repo (or the thin repo export) wipes the curated pitfalls even when the worktree itself carries your one intended change; the wipe and the edit are in the same `cp`, so a diff that shows "only your change" is exactly wrong. Restore the curated copy from backup and re-apply just the edit; keep `/tmp` backups of any live file before overwriting it.

- `diff -q <repo>/$f ~/.hermes/$f` — the edited files are identical to repo main.
- Run each new bin from outside a repo (exit 1 = sane) and inside the repo: its hash
  equals `git write-tree` of the main tree (the content fingerprint binds to real content).
- `skill_view('<new>')` resolves without collision (`ok`), and
  `build_bundle_invocation_message('/<bundle>')` shows the expected skill count, 0 missing
  (the venv is `./venv`, not `.venv`).
- `git status --short` in the main tree is clean both before and after.

When an incident/lesson surfaces (a guard that cost time, a recovery pattern), the user wants it recorded in BOTH places, never just one: a dated note in the vault's `0-raw/YYYY-MM-DD.md` (the permanent capture rule) AND an English entry in the repo's `CHANGELOG.md` `[Unreleased]` (`### Fixed` for the guard, `### Added/Changed` for new behavior), done as its own worktree+PR — edit the changelog with `patch`, never commit it straight from `main` (that repeats the main-tree-edit trap).

Then clean up: the merged worktree is removed and the merged `agent/<slug>` branch is
deleted local + remote (with `--delete-branch=false` on merge, delete them yourself).
Distinguish this sync from the bundle two-write note above: bundles diverge per-file and
need a second write at edit time; a PR merge needs a whole-tree `cp -R` of changed files.

### Every completed change ends with archive + sync — never left on main

Migue's standing rule: **a finished OpenSpec change is archived and its specs synced
before the loop is considered closed — always, no skipping.** When a feature PR is
squash-merged, the archive is NOT carried along: the change dir rides the squash but the
`openspec archive` step did not run (the feature branch only held the active change). The
result is a change that reads `complete` in `openspec list` and still sits under
`openspec/changes/` on main — an unfinished tail.

Close it as a **separate follow-up PR on its own worktree**, never by folding the archive
into the already-merged feature PR:

```bash
# cut a fresh worktree from main (which now holds the complete change)
git worktree add ../<repo>-worktrees/archive-<slug> -b agent/archive-<slug>
# 1) sync first, agent-driven: create/maintain the main spec so it carries the delta in
#    Main-Spec Format (a single ## Requirements section — NO ## ADDED / MODIFIED headers)
# 2) verify the synced main spec:  openspec validate --specs --json       # 0 failed
# 3) archive:  openspec archive "<change>" --yes    # "Specs already in sync" = good
# 4) verify:   openspec list --json (active []) + openspec validate --archived --json
# 5) PR, squash-merge, remove the worktree, delete the branch, pull --ff-only
```

Sync before archive, never the reverse: `openspec archive` on an already-synced spec is a
no-op ("Specs already in sync; no files changed") and just moves the change dir — do the
agent-driven main-spec write first, then archive moves it. A `git add -A openspec/` after
archive shows clean renames (change → `archive/YYYY-MM-DD-<change>/`) plus the created
main spec; validate `--archived` covers the new archive dir.

## Extending the agency from an external inspiration repo

When the user wants ideas/skills/commands from another agent repo (e.g. a Claude-Code skill
kit) distilled into the agency, don't clone wholesale — **port only host-agnostic concepts,
strip the runtime**:

- A host-specific skill is often 90% preamble/boilerplate (a `gstack-skill-start`-style
  preamble, plan-mode guards, AskUserQuestion routing) around 10% real idea. Extract the
  idea, discard the preamble; the runtime is not portable to Hermes anyway.
- Skills tied to another host's browser/design/IDE (Pretext, an Aside/Chromium bridge, a
  gbrain/PGLite brain) are not portable — keep only the *concept* (e.g. "fingerprint the
  working tree to bind evidence to content" becomes a standalone bash bin; a Diataxis doc
  framework becomes a plain skill).
- A bin that is pure shell with a permissive license (MIT/BSD) can be copied verbatim and
  renamed; preserve the license attribution in a comment header and adjust file-scoped
  names/references.
- Don't duplicate what the agency already covers (`autoplan` ≈ the loop, `investigate` ≈
  systematic-debugging, `freeze`/`guard` ≈ worktree isolation, `ship` ≈ release). Call
  those out to the user rather than shipping a copy.
- When the user names a set of skills "I like these", push back with a curation pass
  (duplicate / host-bound / no-prod-yet) and get explicit sign-off on the filtered set —
  don't silently ship all of it.

### The curation pass IS the deliverable before any design

Present every candidate up front as a three-way table and get scope sign-off from it, before
writing a spec or touching a file. The user decides from the table, not from prose:

- **port** — host-agnostic concept that fills a real agency gap (a mechanical deny list, a
  read-only inventory command, a commit-granularity rule).
- **already covered** — name the existing agency asset it duplicates, so the user sees you are
  not selling them their own system back: their adversarial parallel review ≈
  `multi-perspective-code-review`, their SDD phases ≈ the OpenSpec loop. Their marketing site
  structure usually has one genuinely new block (e.g. problem → components → presets) worth
  noting separately from the process material.
- **discard** — their runtime: a memory MCP, a provider switcher, a host-specific shell, a TUI
  installer, a telemetry collector, an uninstall flow. Say *why* in one clause each.

Also check whether an existing agency change already builds the same thing. A parked change's
design may already be the input your "new" idea needs; state the dependency and let the user
choose order (build against it, wait for it, or degrade gracefully declaring lower precision).

### Never install the upstream binary or its state machine

Re-implement the *concept* as this repo's own `bin/`. Their transition engine is wired to
*their* artifact layout, so porting the binary forks the state logic away from OpenSpec; a
self-contained read-only bash bin over `openspec`/`git`/`gh` state keeps one source of truth.
The repo's `bin/` pattern (bash 3.2, zero new deps, prints and never writes) is the natural
host. "It is free software, let's copy it" authorizes the *idea*, not the dependency.

### Record the new source's attribution where the repo already credits its other sources

Add the license + attribution to the CHANGELOG's existing adaptation note (`gstack`-style),
with a clause stating what was **not** taken (no binary, no runtime, no third-party state
machine). A ported rule whose provenance is unrecorded reads as an original rule and gets
quietly overwritten later. When a bin's shell body IS copied verbatim from a permissive
license, keep the attribution in its comment header.



## Guardrails the agency already carries (do not re-invent them)

These ship in the repo and are the answer to suggestions that arrive as "you should add…":

| Guardrail | Lives in |
|---|---|
| Enumerated sensitive-path **deny list** + reviewer grep over the declared diff (match = `BLOCKER`) | `rules/project-boundaries.md`, `rules/quality.md`, `workflows/review-change.md`, `agents/reviewer.md` |
| **`bin/skill-registry`** — read-only inventory of installed skills, flags `BLOCK-SCALAR` / `MULTILINE-SCALAR` / `MISSING-DESCRIPTION` / `NO-FRONTMATTER` / `UNCLOSED-FRONTMATTER`; every record names its `ROOT`, paths are deduped | `bin/` |
| **Work-unit commits** + *advisory* ~400 authored-line budget; crossing it forces a **recorded** delivery strategy (`single-pr` / `chained-pr` / `split-change`) | `rules/coding.md`, `workflows/implement-change.md`, `workflows/release-change.md` |
| **`bin/review-snapshot`** — freezes the review candidate (base, `HEAD`, content fingerprint, diff hash) before anything reads it; `--compare` re-verifies **every recorded field** (fingerprint + diff hash + that the recorded base still resolves) and reports `MISMATCH` naming which field diverged; refuses an un-ignored in-repo `--out` | `bin/`, `rules/quality.md` ("Frozen review candidate") |
| **`bin/review-tier`** — derives review depth (`low`/`medium`/`high`) from the diff's declared shape (auth, schema/migration, security config, dependency manifest, size bound), printing every rule that fired | `bin/`, `rules/quality.md` ("Review tier") |
| **`bin/agency-next`** — derives the workflow state (`working`/`checking`/`ready`/`needs-decision`) plus the precise state underneath and the **single valid next transition**, from the OpenSpec CLI's JSON, git, the working-tree fingerprint and the review snapshot; a declared `precision` section lists every transition it could not determine | `bin/`, `rules/orchestration.md` ("State and transition") |

- **A tier/assessment is never a gate.** It selects *depth* and nothing else: it must not block,
  close, authorize a merge, or stand in for the QA gate. Delivery stays human-owned. When you
  document or wire such a tool, state that explicitly — an assessment that reads as an approval
  authority is a process defect.
- **Compare content, never commits.** The snapshot must match a rebase/amend/squash that
  preserves content, or it blocks exactly the legitimate rewrites the fingerprint rule exists to
  allow. A verdict tied to a commit sha is the wrong instrument.
- **Compare every field the record carries, not the one that is convenient.** A `--compare` that
  checks only the fingerprint returns a confident `MATCH` for a hand-edited manifest: the verdict
  is about a record that never described this range. Same defect class as an optimistic default —
  a check that cannot fail on the interesting input is decoration.
- **Resolve paths physically before comparing or guarding them.** `git rev-parse --show-toplevel`
  returns the physical path while `$PWD` keeps the symlink (`/private/var/...` vs `/var/...` on
  macOS), so a prefix guard silently misses and the write it was meant to block proceeds. Use
  `pwd -P` on both sides, and resolve through the nearest *existing* ancestor when the target's own
  directory does not exist yet. Any bin that decides "is this inside the repo?" needs this.
- **A tool whose exit code is its contract must check that its write landed.** `cat > "$OUT"`
  fails when the target is a directory and the redirect's status is discarded, so the tool prints a
  full, plausible summary and exits 0 for a record that does not exist — the caller checks `rc=0`,
  believes a frozen record exists, and only discovers the absence at the delivery compare. Wrap the
  write and exit non-zero naming the cause. Same class as cannot-assess collapsing into a tier: a
  success reported for work that did not happen.
- **A generated remediation hint must be safe to apply verbatim.** A refusal that says "add this to
  `.gitignore`" is a command the reader will paste; deriving it by replacing the basename with `*`
  makes a root-level target suggest `*`, which ignores the entire repository. Fall back to the
  concrete path the tool actually uses whenever the derived form is not a real file pattern.
- **Document the consumer-side precondition, not just this repo's default.** The installer carries
  no `.gitignore`, so a consuming project's first snapshot against the documented in-repo path is
  refused with no doc-directed remedy. State the `echo >> .gitignore` step in INSTALL/README next to
  the command, and keep "the default path is gitignored" scoped to this repo where it is true.
- **An assessment over committed content must name uncommitted work when it finds nothing.**
  `base...HEAD` ignores the working tree, so a clean-looking empty diff is most often untracked
  edits rather than a wrong base; a reason that only blames the base sends the reader to the wrong
  fix. Say what the measurement cannot see.
- **Fold the fixes for a review pass's findings back through the same gate.** A re-verification that
  returns `approved` can still carry new findings; close them and re-run the full fixture set before
  the commit — an `approved` verdict is about the content the verifier read, not about the fixes you
  applied after it.
- **Read a CLI's JSON with `jq`, never with line tools.** `sed`/`grep` return *empty* for a nested
  object, and an empty extraction that falls through to a shell default reports the opposite of the
  truth — task counts read as 0/0, so a brand-new change gets announced as fully implemented. The
  repo declares `jq` as its JSON tool (`rules/openspec.md`, `rules/project-boundaries.md`,
  `rules/quality.md` all pipe openspec/git JSON through it). A field that cannot be parsed is
  declared undetermined, never defaulted.
- **Resolve the agency's own bins by search order, and let "not found" stay unverified.** The bins
  ship with the agency (its `bin/` in the Hermes home), not with the project under work, so a
  sibling-bin lookup against the project's cwd finds nothing — and a lookup failure that reads as
  the favourable verdict ("the review evidence is current") is the same optimistic-default defect as
  a cannot-assess collapsing to a tier. Search next to the script, then the project's `bin/`, then
  the agency home; when nothing resolves, report the transition as undetermined. Capture the
  **resolved path** and execute it — assigning a resolver's return value to the same variable prints
  the path where the hash belongs.
- **Emit the ambiguity instead of picking a default.** Several active changes (or several candidate
  targets) without an explicit selector is reported as an ambiguous state plus the list, never
  resolved by choosing one. Same rule as flag-it-never-guess: a tool that picks silently is wrong on
  exactly the input where a human would have noticed.
- **A linear bash bin must define its helpers before their first use.** Shell reads top to bottom, so
  a helper called above its definition is `command not found` at runtime while a syntax check stays
  green; when moving a helper, move its call sites' order too.

Two framing rules that keep these honest when you edit or cite them:

- The budget is **advisory by requirement**. Never re-describe it as a cap, an automatic stop
  or an acceptance criterion: a mechanical cap incentivizes deleting comments, weakening tests
  and splitting units artificially to fit the number.
- **A detector must cover every form of the defect it names, or flag what it cannot read.** A
  linter that catches `description: |` but not `|2-` is worse than none: it reports a confident
  `ok` on a form it never parsed. When a line-wise parser cannot read a shape faithfully (a
  value continued on indented lines, an unclosed quote), emit its own explicit marker —
  **flag it, never guess**: a truncated value is a wrong value, and a healthy skill reported as
  defective is a false finding. When a read-only inventory must present a value it cannot fully
  carry (a multi-line scalar body), elide honestly — first line plus an explicit `…` marker — never
  silently truncate to a plausible-looking line; and pin the FULL preview (the line *with* the
  marker) in the suite, because a substring assert the truncated output already satisfies cannot
  detect the truncation.
- **A block/folded indicator with a body is legal YAML — the defect is the content-less indicator, and a lint flag is a lead, not a verdict.** `description: >-` followed by indented text is a valid folded scalar; only an indicator with NO body makes the loader present the literal `|`/`>-` as the description (the converted-persona defect). A detector that flags the indicator's presence instead of the missing body is a false-positive factory — the agency's own `skill-registry` once flagged a real skill's legal `>-` as defect, and the flag was believed and reported before a real YAML parser was run. When a tool flags a real-world artifact, verify the claim against the artifact's actual semantics before propagating it as fact. The content-less form includes an indicator with a trailing YAML comment (`>- # text`): the comment is legal YAML, the indicator still has no body, and a detector whose indicator-regex demands the pure indicator at end-of-line misses it and prints the literal `>- # …` as the description — strip the trailing comment before deciding. Ground-truth the verdict with a real parser before believing either the tool or the fix: macOS ships Ruby, so `ruby -ryaml -e '…'` is a zero-install check that settled this exact class of argument twice.
- **"Cannot assess" must never collapse into the cheapest default.** The same honesty rule
  applies to any assessment: an unmeasurable diff is not `low`, an unreadable skill is not `ok`.
  Emit an explicit cannot-assess state with a non-zero exit, and bind a fixture case to it — a
  failed assessment silently degrading to the optimistic value is the highest-severity class of
  bug for a tool whose whole value is telling depth from shape.
- "Nothing bounded the diff size" is a *fixed* complaint — the guardrail exists; check the repo
  before proposing it again.

## When a rule is stated as a table, its machine form must agree row by row

Any place the agency states a rule twice — an enumerated table in a rule file and the
regex/flag/command that implements it — is a drift surface. A row whose machine form cannot
match it fails *silently*: the check returns nothing, and that empty result is then recorded as
its evidence line, indistinguishable from a genuine pass.

- **Bind one fixture case per row of the table, each asserted individually.** A fixture that
greps a whole file for "matches at least once" stays green while a row is unmatchable. One
`run_case <row-label> <path> <match|clean>` per row turns a dead row into a failing case.
- **Pair every must-match case with near-miss must-stay-clean cases.** A pattern written for
recall is easy to widen into over-matching, and only the clean cases catch it. A deny-list
attempt that anchored a bare extension match swallowed every extensioned path in the diff; the
per-row fixture failed loudly *before* the commit. Re-run the fixture in the same breath as any
pattern edit — the fixture is what proves the fix, not rereading the regex.
- **State in the rule that the table and the pattern move together.** A row added without the
pattern (or the reverse) is a defect the reviewer raises; saying so in the rule text is what
tells the next editor to update both.

## Verifying a change to this repo (there is no CI workflow)

Read the repo for a CI workflow first; if there is none, the gate is entirely local. Run all of
it and quote real output — the repo's own `rules/quality.md` treats a claim without a command
as a failure:

```bash
openspec validate "<change>" --type change --json   # summary.totals.failed == 0; READ every issue
openspec instructions apply --change "<change>" --json   # state + progress
for f in bin/* fixtures/*/*.sh; do bash -n "$f"; done   # syntax, incl. fixture scripts
bin/<new-bin> --root fixtures/<new-bin>/roots/valid      # happy path
bin/<new-bin> --root fixtures/<new-bin>/roots/defective  # every defect class
bin/<new-bin>                                       # ALSO run against a real tree (~/.hermes/skills)
git status --porcelain                              # read-only proof after running it
bash install.sh --prefix "$(mktemp -d)" --yes       # installer exit 0
# then: test -x <tmp>/bin/<new-bin>   ← install.sh already copies bin/ wholesale
```

- **Fixtures alone do not prove a parser survives real input.** Run a new bin against the live
  tree too (real frontmatter, real nesting); that is where an awk/sed parser breaks.
- **Prove determinism by diffing two runs** (`diff <(bin x) <(bin x)` — identical), not by
  eyeballing a sorted-looking list.
- **Tick a task only against its own `verifies:` command**, and leave the archive/close task
  unticked — the archive is a separate follow-up PR under the standing rule above.
- **Tick tasks through the OpenSpec task tools, not by hand-editing `tasks.md`.**
  `openspec_task_list` returns ids/status/counts and `openspec_task_set_status` marks ids
  `done` (pass the project/worktree as `workdir`); the command re-reads the file and reports
  fresh counts, so the tick lands with verifiable numbers instead of a silently drifted
  checkbox state after a branch rebuild or cherry-pick.
- **A `verifies:` that names no expected value is not a verification.** "`find … | wc -l`
  matches the declared count" is unrunnable — the reviewer cannot tell pass from fail. Write the
  literal expectation (`test "$(find … | wc -l | tr -d ' ')" = "10"`) and state the arithmetic
  behind it (4 valid + 6 defective).
- **Run every `verifies:` command for real before ticking its box, and keep it executable by bash
  3.2.** A command can read as obviously correct and still never run: process substitution
  (`<(...)`, `>(...)`) is a bash-4 feature, so on macOS the shell rejects the line outright and the
  tick rests on a command whose output was never produced — a fabricated evidence line, not a typo.
  Ticking from a command's plausibility instead of its exit status is the same defect as ticking
  from a summary you did not read. When a tick turns out to have been unsupported, say so plainly;
  silently re-running it and leaving the box ticked hides that the pass was bogus.
- **Never pipe a verification command through `tail`/`head`.** `cmd | tail -8; echo $?` prints the
  pager's status, so a suite that exits 1 reports `EXIT=0` — the failure is invisible in exactly
  the place you went to look for it. Capture the status directly (`cmd > out 2>&1; rc=$?`), or rely
  on `set -o pipefail` when a pipe is unavoidable. Re-read every "all green" you concluded through a
  pipe.
- **A test harness must fail closed — and the guard has to sit where it can actually fire.** A
  harness whose pass condition is "no case failed" reports success when every case failed to build:
  `exit $fail` is 0 when `fail` is 0 because nothing ran, so a real crash hides behind a green suite
  for as long as the scaffolding is broken. But a **tail** guard (`if [ "$checked" -eq 0 ]` above
  `exit "$fail"`) is dead code: the earliest cases need no scaffolding, so `checked` is already
  non-zero and the condition is unreachable — while the one path that genuinely yields zero (the tool
  under test missing from `PATH`) exits 0 from the SKIP branch *above* it, printing the identical
  false green the guard was written to stop. Fail closed **at the top**: when the suite cannot run,
  exit non-zero with a distinct code (e.g. 3) and a message saying so — never `exit 0` from a skip.
  An unwired guard is worse than no guard, because it reads as protection. Assert such a branch by
  exercising it, never by its existence in the file. When a fixture goes red right after a fix,
  suspect the fix first — but when a fixture has been green all along, suspect the harness.
- **A fixtures directory with no runner is coverage that does not exist.** The repo's convention is
  `fixtures/<bin>/check.sh`; a `fixtures/<bin>/` directory full of cases and no `check.sh` reads as a
  suite in the tree listing and executes nothing — no gate, no regression signal, and the cases rot
  against a bin that drifts away from them. When adding fixtures, confirm each directory carries its
  `check.sh` and that running it prints a case count (the same count the fail-closed guard keys on).
  A fixture nobody runs is worse than no fixture: it reads as coverage in every later audit.
  When the suite is finally written, check every fixture actually contains the shape it names — a
  "defective" block-scalar fixture that carries content under the indicator is legal YAML, so the
  suite goes green while the detector mis-flags the wrong shape. Pin both sides: the genuine defect
  (content-less indicator) AND the legal folded/block scalar that used to be mis-flagged.
- **Dogfood the budget you just wrote**: measure `git diff --numstat main...HEAD`, and when the
  change crosses it, record the strategy *with the reason the others were rejected* in
  `design.md` (survives the merge; a PR description does not). Re-measure before the final
  commit and quote the command next to the numbers — a figure measured mid-flight goes stale and
  an artifact that records a decision on non-reproducing numbers invites re-litigating the
  decision.
- **Read the returned diff after every `patch` on a rule file.** Keep the matched prose
  byte-identical inside `new_string`: a stray list marker silently turns body prose into a
  bullet, which in a rules file changes what the rule appears to say.
- **Re-run the whole gate after applying a review's findings, before the commit.** The fix is new
  code in the same file the review just attacked, so it is the likeliest thing to break — and
  `bash -n` passes on a script that dies at runtime, because an unbound variable under `set -u` (a
  compound expression packed into a `$( )` argument) is a runtime error the parser never sees. `bash -n` is also blind to a non-ASCII literal glued onto
  an identifier (`$body_first…` — a patch-serialized ellipsis absorbed into the variable name), which
  dies at runtime with `unbound variable` on a variable that plainly exists; on that symptom, inspect
  the raw bytes of the line (`od -c`) and keep code ASCII-only — the ellipsis belongs after the
  closing brace (`${body_first}…`), inside the string literal, never in the name. Run
  the bin and the fixture suite; a green run from before your edit says nothing about the run after
  it. When a fixture turns red right after a fix, suspect the fix first, then the fixture.
- **A fixture repo must do its work on a branch, or it measures an empty diff.** A fixture that
  commits straight onto `main` makes `<base>...HEAD` empty, so every case exercises the shallow
  default path and the suite is green or red for the wrong reason. Have the fixture create a
  baseline commit on `main`, then a `work` branch for the change under test — that is the only
  shape where `main...HEAD` carries the diff the tool is supposed to read.
- **When a fixture case fails, reproduce it by hand before "fixing" the tool.** A self-authored
  assertion string is as likely to be wrong as the artifact: a clean-tree check that greps for
  the wrong shape, or a grep for a literal name where the file describes the thing in prose,
  both report a failure on a correct artifact. Fix the fixture and say plainly that the tool was
  right — do not patch working code to satisfy a bad test.
- **On a chained branch, run the tools with `--base <parent-branch>`.** Pointing a size/risk
  assessment at `main` on a chained branch counts the parent's lines and reports a tier for work
  that is not in this change.

## Cutting the worktree when other agency PRs are in flight

Several agency changes can be open at once. Before creating a worktree, list what already
exists — existing worktrees, `agent/*` branches and open PRs — and compare the touched-file
sets. Two agency changes collide most often on `CHANGELOG.md`, `openspec/` and the process rule
files (`rules/quality.md`, `workflows/review-change.md`, `agents/reviewer.md`, README/INSTALL);
if they overlap, serialize them or expect a conflict, and never edit the main tree to "just fix
the changelog".

When the overlap is resolved by scripted find-and-replace inside a rebase, the conflict marker's
branch line (`>>>>>>> <ref> <commit-subject>`) is part of the hunk: a resolution that strips the
marker keyword but keeps its trailing text pastes the commit subject into the changelog line — and
lands in the merged PR. After ANY programmatic conflict resolution, grep the file for `<<<<<<<` /
`>>>>>>>` AND read the resolved hunk for carried marker text before committing; verify a merged
PR's diff before declaring closure.

**Recovering a user PR that sits `CONFLICTING`:** the branch predates recent merges on main.
Rebase it inside its own worktree (`git fetch origin main && git rebase origin/main`), then
resolve conflicts. For a shared file like `CHANGELOG.md`, **combine both sides** — HEAD's entry
AND the branch's new bullet, never drop one side — finish with `GIT_EDITOR=: git rebase
--continue`, then `git push --force-with-lease` and wait for GitHub to recompute `mergeable`
before merging. When two PRs touch the same file, merge the mergeable one first and rebase the
second onto the updated main.

### Overlapping file sets: chain the PR, do not "wait" for the other one

Overlap does NOT mean the second change is blocked. Cut **one worktree per change** but base the
new branch on the **other change's branch**, not `main`, and record the strategy as `chained-pr`
in the new change's `design.md` — the merged PR description does not survive, the design does.

```bash
git worktree add -b agent/<slug> ../<repo>-worktrees/<slug> agent/<parent-slug>
```

Consequences that will otherwise waste a round:

- **Measure the diff against the PARENT branch**, not `main`. `git diff main...HEAD` on a chained
  branch returns the parent's files too, so a collision check against `main` reports overlap that
  no longer matters — the child is not touching those files, it *inherits* them.
- **The PR's base is the parent branch.** Merge the parent first; the child then rebases onto
  `main`. Say this in the PR body's first paragraph so the reviewer is not left inferring it.
- **Do not re-derive the parent's work.** If the parent change already declares a rule the child
  cites, cite it; do not restate it in the child's delta spec.

### Before creating a branch, check whether the work already exists

An interrupted turn leaves its worktree and branch behind, and its spec may already be written.
List branches and compare tips before creating anything new: a branch whose tip equals another's,
with no unique commits, is a duplicate to delete rather than a parallel effort.

```bash
git worktree list
git log --oneline agent/<other>..agent/<candidate>   # empty = candidate has nothing of its own
```

Delete the duplicate with `git worktree remove <path> --force` + `git branch -D`, then continue on
the branch that already carries the artifacts — re-scaffolding a change that exists on another
branch is the expensive mistake.

## Reviewing a proposal-only agency change

When improving the agency itself via a `feature`/`/do` loop, the first deliverable is a
draft OpenSpec change with **no code yet** — and the reviewer stage reviews the artifacts
as an implementable specification, not a diff. A green `openspec validate` is not a pass.
Run the spec-draft checklist in `references/review-spec-draft.md` (contradicting spec↔design,
phantom capability, behavior with no owning workflow, orphaned design consequence, "verify"
that only greps, mutable file breaking the release fingerprint, plus the post-implementation
classes). Fix the defects, then re-dispatch the reviewer and require each prior finding
CONFIRMED closed with a fresh run.

### Dispatching the reviewer (mechanics that decide whether the review is worth it)

- **Give it a per-finding `output_schema`.** A prose report for a dozen findings runs tens of
  thousands of characters and comes back truncated; a schema of
  `{finding, status, verification_command, observed_output}` per entry survives intact and is
  machine-checkable. If the dispatch is rejected on the schema, drop it and enforce the shape in
  the prose.
- **On a re-review, brief the numbered prior findings verbatim and ask CONFIRMED-CLOSED or
  REFUTED per finding**, each with the command and its observed output — never a self-reported
  "fixed". A re-review is a fresh-context run that re-derives every verdict; it must not be
  handed the fix's own description as an input.
- **Require a regression check in the same dispatch.** The fix for a finding is itself new code,
  and the reviewer is the only actor that tests it adversarially. Name the surface the fix
  touched ("verify the corrected pattern does not over-match these ordinary paths") rather than
  asking for a general re-read.
- **Reproduce the reviewer's headline defect yourself before acting on it.** A forwarded audit
  is a self-report: a subagent's finding is a lead until your own command reproduces it.
- **Do not edit the tree while the reviewer is reading it.** A fix applied mid-review invalidates
  the run and forces a fresh dispatch; wait for the verdict, then apply all findings in one pass.
  If you want to make progress meanwhile, work in a different worktree on the next batch.
- **A user's go-ahead is not a verifier verdict.** When a re-review runs in the background, an
  in-flight unit is not an approval, and a user replying "confirmo"/"dale" is authorizing the
  continuation — not attesting to findings they have not seen. Check the unit's status before folding
  any outcome into the work, and say plainly that it is still running. Folding user assent into a
  technical gate is how an unreviewed fix ships described as verified. Likewise a status report that
  ends "te aviso" is not a request for a decision: do not leave the user hunting for the choice.

Two durable traps surfaced the hard way:
- **A mutable per-run log in the tree breaks the release fingerprint.** `no-smoke-worktree`
  fingerprints via `git add -A` (includes untracked files); a log that grows during a run
  makes reviewer and release hashes differ, which `rules/quality.md` treats as a RELEASE
  BLOCKER. When a run-trace/telemetry log lands, gitignore it in the same change.
- **A trace that grows during a run must not hold cycle/metric data the spec separately
  demands.** Write the summary from the same fields the trace already has; if the spec asks
  for a metric the schema omits, spec and design contradict and no builder can implement.

## References

The bundle/level mechanics here assume the protocol in the bundled
`hermes-sdd-orchestration` skill (envelope, retry limits, blocking, report closure). Load
it (and `openspec-sdd`) for the process layer; this skill is the instance maintenance.
- `references/review-spec-draft.md` — reviewer checklist for an agency change's artifacts at
  both stages (proposal-only and post-implementation): the defect classes, the check that
  catches each, and the re-review confirmation step.
- `references/review-evidence-binding.md` — the frozen review candidate and the review-tier
  table: field-by-field contract of `bin/review-snapshot`, the declared tier rows, the
  cannot-assess rule, and the fixture shape that proves both. Load it before editing
  `rules/quality.md`'s "Frozen review candidate" / "Review tier" sections or those two bins.
- `references/derived-state-and-transitions.md` — the state/transition contract of
  `bin/agency-next`: the public and precise vocabularies and their drift surface against
  `rules/orchestration.md`, the honesty rules (a missing input *narrows* but never optimizes, and a
  command that ran and failed is a missing input), the bash 3.2 runtime traps a syntax check never
  sees, `jq`-not-`sed` parsing, how the agency's own bins are resolved, and the fixture shape that
  proves the machine. Load it before editing that bin, that rule's table, or its fixture.
