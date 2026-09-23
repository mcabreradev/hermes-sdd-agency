# Derived state and the next transition

Depth notes for `bin/agency-next` — the read-only bin that answers "which step is next" from
**files** instead of from a session's memory. It is the third member of the same family as
`bin/review-snapshot` and `bin/review-tier`: informational, read-only, never a gate. Load this
before editing that bin, `rules/orchestration.md`'s "State and transition" table, or its fixture.

## The contract

One public state, the precise state underneath, the single valid next transition, and the command
that performs it:

| Public state | Meaning |
|---|---|
| `working` | the machine waits on work; no decision is owed |
| `checking` | a gate is pending (review, QA, CI) or recorded evidence went stale |
| `ready` | the next decision is the **user's** (merge, archive, scope) |
| `needs-decision` | it cannot be determined honestly, or the human must choose |

The precise vocabulary underneath is what a workflow branches on: `READY_TO_APPLY`,
`IMPLEMENTING`, `NEEDS_FIX`, `READY_TO_REVIEW`, `NEEDS_REVIEW`, `READY_TO_QA`, `QA_FAILED`,
`PR_OPEN_CI_RED`, `PR_OPEN_CI_PENDING`, `READY_TO_MERGE`, `ARCHIVE_PENDING`, `STALE_EVIDENCE`,
`EVIDENCE_UNVERIFIED`, `NO_ACTIVE_CHANGE`, `AMBIGUOUS_CHANGE`, `UNKNOWN_CHANGE`.

**Every precise state the rule file names must be reachable in the code, and every state the code
emits must be named in the rule.** A reachable state the rule omits, or a declared state that is
never emitted, is a reviewer finding — the same drift surface as a rule table row with no matching
pattern. Assert the equivalence between rule and code directly rather than reading both and hoping.
When a state a workflow genuinely needs has no readable input behind it yet, declare it out of scope
with the reason instead of advertising it: a declared-but-unreachable state tells a workflow to
branch on something that never arrives, and emitting it optimistically is worse still.

## Honesty rules that are the whole point

- **A missing input narrows the answer; it never optimizes it.** Every transition the tool could not
determine is listed in a `precision` section with its reason (no run trace, `gh` not on `PATH`, no
remote, no review snapshot). Assuming "CI green" or "review passed" because the input was
unreadable is the highest-severity failure this tool can have — it is the exact class the tool
exists to refuse.
- **A verifier that cannot be found is NOT a pass.** An unresolvable `review-snapshot` yields
`EVIDENCE_UNVERIFIED`, never "the evidence is current". Distinguish "looked and found it current"
from "could not look".
- **Stale evidence outranks "tasks done".** A snapshot that no longer matches the tree wins over
every downstream signal; bind a fixture case to exactly that ordering, since the cheerful path is
the one that regresses.
- **Report the ambiguity, never pick.** Several active changes without an explicit selector →
`AMBIGUOUS_CHANGE` plus the list, not a guess.
- **A PR with no checks is not a green PR.** Distinguish passing / failing / pending / no-checks
reported; collapsing "no checks" into "ready to merge" is the optimistic default again.
- **A limit about a thing that does not exist contaminates every honest answer.** The `precision`
section is assembled from *inputs that failed*, and an empty derived field still satisfies a later
`length == 0` test: with `gh` working but no open PR, the check-rollup test fires on an empty PR
number and the tool emits "whether PR # has passing checks" — a limit naming an empty `#`, attached
to the two most common determinate states (`ARCHIVE_PENDING`, `READY_TO_REVIEW`), where the tool
does have an answer. Scope each limit inside its own guard (`[ -n "$PR_NUMBER" ]`) and assert the
precision section on a working-`gh`/no-open-PR repo carries **no** `PR #` bullet. A phantom limit is
the mirror of the optimistic default and just as misleading: it reports a gap the tool can actually
close, and a consumer branching on the section cannot tell "no PR, checks unknown" from "PR #,
checks unknown".
- **Informational only.** It never blocks, merges, archives or replaces a gate; a human decision is
reported as `ready` and the output says so. Wiring it as an authority is a process defect.
- **Read-only and deterministic**, both asserted rather than assumed: `git status --porcelain`
unchanged, `HEAD` unchanged, two runs byte-identical.

- **A command that RAN AND FAILED is a missing input, not the negative answer.** `X=$(cmd || true)`
followed by a field extraction collapses two different worlds into one empty string: "the CLI read
the artifacts and they are incomplete" and "the CLI could not read them at all". The empty string
then compares unequal to the proven-false literal and falls into the *other* branch, so a broken
read announces "planning is complete" with no input behind it. Check the exit status **and** the
presence of the field, and route the failure to a declared undetermined state — and bind a control
case with a genuine proven-false value to prove the incomplete branch is still reachable. Same rule
for a tool that exists but cannot answer: `gh` installed and unauthenticated is not "no open PR",
and a remote-less repo must report its own limit rather than the tool's.

## bash 3.2 runtime traps a syntax check never sees

- **Expanding an EMPTY array is fatal under `set -u`.** `"${arr[@]}"` on an array with no elements
is an unbound-variable error in bash 3.2, and the fatal arrives *after* the surrounding output has
already been written — so the tool prints a complete, correct state and then exits 1, contradicting
the exit-status contract its own rule file declares. Apply both defences: initialise every
accumulator (`ARR=()`) **before** the first branch that may read it rather than leaving it for the
happy path to populate, and write the expansion empty-safe (`${ARR[@]+"${ARR[@]}"}`). The shape that
reaches it is the cheerful one — remote configured, `gh` on `PATH`, snapshot matching, no open PR —
so a fixture must build that shape explicitly instead of exercising only the degraded paths.
- **The same fatal applies to any variable initialised on one branch and read on another.** A
`PR_UNAVAILABLE=0` set inside `if [ -n "$GH" ]` is unset on the no-`gh` path and kills the run where
it is read. Declare the whole related family together at the top of the section that owns them.
- `bash -n` stays green through all of this. Only running the bin on the offending input finds it,
and only a fixture that builds that input finds it in CI-less work.

## Parsing the CLI's JSON

Parse with `jq`. The repo declares it as the JSON tool, and line-oriented text tools cannot read a
nested object: a `sed`/`grep` extraction over multi-line JSON returns **empty** for the nested
field, and an empty extraction that falls through to a shell default reports the opposite of the
truth — task counts read 0/0 and a brand-new change is announced as fully implemented. Every field
read from a CLI is either parsed properly or declared undetermined; never defaulted. Check the tool
is present too: a missing `jq` is a declared cannot-determine exit, not a silent pass through a
`|| true`.

## Resolving the agency's own bins

The bins ship with the **agency** (its `bin/` in the Hermes home), not with the project being
worked on, so resolving a sibling bin only against the project's cwd finds nothing in a normal
project. Search in this order — next to the script, then the project's `bin/`, then the agency home
— and when none resolves, report the undetermined transition instead of assuming. Two details that
cost rounds:

- Capture the **resolved path** in a variable and *execute* it. Assigning a resolver's return value
to the value variable prints the path where the hash belongs — a fingerprint line that looks
plausible and means nothing.
- A helper must be defined before its first call; shell reads top to bottom, so a function invoked
above its definition fails at runtime while a syntax check stays green.

## Fixture shape that proves the machine

- **Build the throwaway repos with the real CLI** (`openspec new change`), not by hand-writing
directories: the machine reads the CLI's own JSON, so a hand-made tree tests a fiction.
- **Scaffold every artifact the CLI counts toward planning-complete** (`proposal.md`, `specs/`,
`design.md`, `tasks.md`). An omitted `design.md` silently makes the case exercise the *planning
incomplete* state while it asserts the state after planning — green for the wrong reason.
- **Commit on a `work` branch off a baseline `main` commit**, so `<base>...HEAD` carries the diff the
  tool is supposed to read.
- **Fake a tool by putting a stub directory FIRST on `PATH` while APPENDING the real dirs** — never
  replace `PATH`. The bin under test shells out to interpreters (`openspec` is a node wrapper), so a
  `PATH` that shadows `gh` but drops `node` makes the CLI itself fail and the case dies with a bare
  non-zero exit and no output, which reads like a tool bug instead of a fixture bug.
- **A fixture repo needs an `origin` remote to reach the remote-dependent branches.** Without one the
  case never gets past the "no remote" guard, so a stub `gh` that always fails proves nothing about
  the `gh`-present-but-failing path.
- **Scaffold fixtures under `$TMPDIR`, never inside the repo tree, and audit `git ls-files` before
  committing.** A fixture that creates `openspec/changes/<name>/` in the working repo gets swept up
  by a later `git add -A`; the tool then reports a dozen active changes it can never resolve, and the
  fixture has polluted the exact state it exists to measure. One `git ls-files | grep <fixture-name>`
  before the commit catches it.
- **bash 3.2 declares every name in a multi-assignment `local` BEFORE assigning any of them**, so
`local name="$1" dir="$WS/$name"` reads an unset variable — under `set -u` a hard error whose message
points at the second name, not the cause. Assign on separate lines.
- One case per declared precise state, plus: no active change, ambiguous list without a selector,
unknown selector, planning incomplete, planned with nothing ticked, partially implemented,
all-done-without-evidence, stale evidence beating "tasks done", current evidence with no PR
(reported `ready` with the decision named as the user's), a working-`gh`/no-open-PR repo whose
precision section carries NO `PR #` bullet, not-a-repository (non-zero exit),
determinism, read-only — and the four that only exist because a read failed: the cheerful shape that
empties the precision list (remote + working `gh` + matching snapshot + no open PR, asserting exit
0 *and* a complete stdout), `gh` present but failing, an unreadable `openspec status`, and the control
showing each of those still reaches its honest branch when the value really is negative.
- When a case is red, reproduce the sequence by hand in a scratch repo before touching the bin — a
self-authored assertion is as likely to be wrong as the artifact.
