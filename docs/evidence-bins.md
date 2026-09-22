# The Evidence Chain — five bins that make the agency's claims verifiable

> An agent's report is a **self-report**, not a fact. These five tools turn every claim into
> something you can confirm or refute with a command — before you trust it overnight.

## The problem this solves

Three failures happen in every AI-assisted workflow if you let them:

1. **Smoke** — an agent says "I tested it" about content it may never have seen, or about a
   tree that changed right after. The review describes code that no longer exists.
2. **Amnesia** — a new session starts from zero and asks you questions the files already answer.
   State lives in a session's memory instead of in the repo, where it can be read.
3. **Depth by mood** — small fixes get a rubber-stamp review and big migrations get a skim,
   because review depth follows whoever happened to be on shift, not the diff's real risk.

The fix is five small commands that read **files**, print **hashes**, and never trust a memory:

| Bin | The question it answers | When it runs |
|---|---|---|
| `no-smoke-worktree` | "What is the exact content of this tree, right now?" | Every stage that claims evidence |
| `review-snapshot` | "Which candidate was frozen before the review?" | Before the reviewer/QA read a thing |
| `review-tier` | "How deep should this review go?" | Before the review, from the diff itself |
| `agency-next` | "What is the single next step, and why?" | Every checkpoint, from files alone |
| `skill-registry` | "Which skills actually resolve — and any that mis-route?" | After any install/sync |

The chain: **freeze → tier → review → compare**. Read the sections in order and run the
examples; each output below is a real run.

---

## 1 · `no-smoke-worktree` — the tree's content fingerprint

A working tree can be "clean" in git's eyes yet different from what a stage validated:
a rebase, an amend, an edited file, an untracked file. This prints a **content fingerprint**
of everything — tracked, staged, untracked and ignored — built from the same object
mechanics as `git write-tree`, over a **temporary index** (your real index is untouched).

```bash
$ bin/no-smoke-worktree
68847faa821aefe6d23d5af90095292d6ff0aee8
```

That hash is the tree's identity for evidence. Reviewer and QA record it in their reports;
`release-change` compares the fingerprints at delivery. **A mismatch means the shipped tree
was validated on older content** — re-review before landing. It survives rebase/amend/squash
when the content is preserved, and changes when **any** source changes.

**Why it matters:** it converts "I validated this" from an assertion into a *referenced
object*. No fingerprint, no claim.

---

## 2 · `review-snapshot` — freeze the candidate before anyone reads it

Run **before** the reviewer or QA opens the change. It captures the base ref, the HEAD, the
working-tree fingerprint (from `no-smoke-worktree`) and a hash of the diff that will be
reviewed:

```bash
$ review-snapshot --base origin/main --out reports/review-snapshot.json
# writes:  fingerprint, diffHash, base, head, authoredLines
```

```json
{
  "base": "origin/main",
  "head": "314dc9bae9ff29713779ce0b6c3dc8d83eb03a93",
  "fingerprint": "4e707f0e6a1390929848a9754195ebcfa70d5deb",
  "diffHash": "f3b27446a1f8282fabe38282143610f7b432092c",
  "authoredLines": "301+15"
}
```

The reviewer's report names **that snapshot**, not "the code". At delivery, `--compare`
re-computes the fingerprint and re-checks the base, so a forged or stale manifest is caught:

```bash
$ review-snapshot --compare reports/review-snapshot.json
review-snapshot: the working-tree content moved since the review was recorded —
                 the evidence belongs to different content     # exit non-zero
# and when nothing moved:
review-snapshot: MATCH — the tree is the snapshot 4e707f0e… (diff unchanged)   # exit 0
```

**Why it matters:** evidence can no longer describe content that no longer exists. "Approved"
means "approved *this exact content*", and the comparison is content-based, so a clean rebase
still matches while any real change trips the alarm.

---

## 3 · `review-tier` — depth that follows the diff, not the mood

Reviews fail in two directions: the obvious typo gets three passes and the migration touching
auth gets one skim. The tier derives depth from the diff's **own shape**, using the declared
rules in `rules/quality.md`:

```bash
$ review-tier --base origin/main
tier: medium
reason: behavior-bearing diff, no high-consequence path, 316 authored lines at or under the bound (400)
rules:
MEDIUM  behavior-bearing (bin/skill-registry fixtures/skill-registry/check.sh …), no
        high-consequence class fired, 316 authored lines at or under the bound (400)
```

| Tier | When | Depth |
|---|---|---|
| `low` | only docs/process paths | standard structural checks |
| `medium` | behavior-bearing, no high-consequence path, ≤ 400 authored lines | + full `code-review-checklist` sweep |
| `high` | > 400 lines, **or any** high-consequence path (schema/migration, auth, security config, dependency manifests) | + domain persona and security audit |
| `cannot assess` | empty/unmeasurable diff | reported as such — **never** silently treated as `low` |

Key discipline (encoded in the bin): an empty or unmeasurable diff is **`cannot assess`**
(exit 2), never an optimistic `low`. **The tier is informational**: it never blocks and never
replaces the formal QA gate; a human decides how to use it.

**Why it matters:** review effort now matches risk by rule — and the rule, not the judge,
owns the decision.

---

## 4 · `agency-next` — the next step, derived from files

The oracle that ends "what do I do now?": it reads the OpenSpec CLI's JSON, the git tree,
the working-tree fingerprint and the review snapshot, and prints **one public state, the
precise state underneath, the single valid next transition and the command that performs it**.
No session memory involved — a fresh session gets the same answer:

```bash
$ agency-next
state:      needs-decision
precise:    AMBIGUOUS_CHANGE
transition: name the change
command:    agency-next --change <name>
reason:     2 active changes exist; which one to follow is your call
candidates:
  - skill-registry-followup
  - loop-telemetry-run-log
```

| Public state | Meaning | Next transition is… |
|---|---|---|
| `working` | spec being written or code being built | continue the stage |
| `checking` | candidate frozen, evidence expected | review / compare |
| `ready` | gates passed, human may release | release (human's call) |
| `needs-decision` | ambiguity, missing input, or a gate that must not auto-advance | name the change / answer |
| `stale` | tree moved since the evidence was recorded | re-review |

Honesty is built in: a missing input **narrows** the answer — no run trace, no `gh`, no
remote, an ambiguous list of changes, each narrows rather than defaulting to the optimistic
state. And it is **informational**: it reports `ready` for a human decision; it never blocks,
merges, archives or replaces a gate.

**Why it matters:** dead sessions stop costing you re-reading. State lives in **files**, so
any new session — or another agent — gets the same truthful answer.

---

## 5 · `skill-registry` — what actually resolves, and what mis-routes

The agency promises "these skills will load". This bins audits the promise: it walks a skills
root and prints each skill's exact `SKILL.md` path, name, description and tags, plus an
explicit flag when the frontmatter would make the skill load but **mis-route**:

```bash
$ bin/skill-registry --root fixtures/skill-registry/roots/valid
ROOT: …/fixtures/skill-registry/roots/valid
PATH: …/fixture-crlf/SKILL.md
NAME: fixture-crlf
DESC: A CRLF skill whose line endings must not corrupt the tags field.
TAGS: alpha, beta
FLAG: ok
```

The defects it flags (with the marker that lands on the record):

| Marker | What it means |
|---|---|
| `BLOCK-SCALAR` | a block/folded indicator (`\|`, `>-`, `\|2-`) **with no body** — the loader would present the literal `\|` as the description |
| `MISSING-DESCRIPTION` | `description:` empty with no continuation |
| `NO-FRONTMATTER` | the file starts without a `---` block |
| `UNCLOSED-FRONTMATTER` | the block opens and never closes — distinct from `NO-FRONTMATTER` |
| `MULTILINE-SCALAR` | a value continued on indented lines, or a quote left open |

A block/folded scalar **with** a body (like `description: >-` followed by text) is *legal*
YAML and inventories as `FLAG: ok` — the detector keys on content absence, not on the
indicator's presence. Run it against your real tree:

```bash
$ bin/skill-registry --root ~/.hermes/skills | tail -3
PATH: …/.hermes/skills/context-architecture/SKILL.md
FLAG: ok
# 183 skills inventoried, 0 defects
```

**Why it matters:** "the skills were installed" and "the skills load correctly" are different
claims. This checks the second — and its pinned suite (`fixtures/skill-registry/check.sh`)
runs the command against both healthy and defective fixtures, so the detector itself cannot
silently drift.

---

## The chain in a real run

1. Before the review, Hermes freezes the candidate: `review-snapshot --base <base> --out …`
   and derives the depth: `review-tier --base <base>` (this follow-up scores `medium`, 316
   lines).
2. The reviewer and QA report against **that snapshot**, with `path:line` findings.
3. Findings are validated in the **real code** (a finding is discarded without evidence).
4. At delivery, `release-change` runs `review-snapshot --compare` — a `MISMATCH` bounces the
   change back for re-review, because the evidence described different content.
5. Every checkpoint answers "what next?" from **files** via `agency-next`; a dead session
   resumes from the same truth instead of asking you what was happening.

## Copy-paste quick reference

```bash
bin/no-smoke-worktree                                  # tree identity
review-snapshot --base origin/main --out reports/snap.json   # freeze before review
review-snapshot --compare reports/snap.json            # evidence still current?
review-tier --base origin/main                         # how deep should review go?
agency-next                                            # next step, from files
bin/skill-registry --root ~/.hermes/skills             # what actually resolves
```

All five are informational or evidence-bound: they surface truth, they never silently
approve. The gates remain the reviewer's and QA's verdicts — and now those verdicts describe
a tree you can point at.
