## Context

`bin/skill-registry`'s block-scalar check flagged any `description:` whose value is a YAML block
or folded indicator — which is exactly what a legal folded scalar looks like. The only real
`context-architecture` skill (a `>- ` with an 821-char body) was reported `BLOCK-SCALAR`, and the
flag was believed in a session report before being verified against a parser. The fixtures pinned
the wrong shape too: both "defective" fixtures carry content under the indicator, so they are
legal YAML exercising nothing. And there is no suite at all — nothing runs the fixtures.

Constraints: bash 3.2 portability, no runtime beyond Bash + git, evidence over assertion. The
detector's job is to catch the loader mis-routing a skill; the loader mis-routes when the
*indicator is presented as the description*, which happens only when there is no body.

## Goals / Non-Goals

**Goals:**

- A detector that distinguishes content-less indicators (defect) from indicators with bodies
  (legal), with both shapes pinned by a runnable suite.
- The real `~/.hermes/skills` tree inventoried clean (no false positives).

**Non-Goals:**

- A YAML parser in the bin. The decision needs only "is there an indented line after the
  indicator", which the frontmatter text it already parses provides.
- Rewriting legal skills to avoid folded scalars — they are valid YAML and load correctly; the
  detector, not the skills, was wrong.

## Decisions

### Decision: The defect is an indicator with no body, not an indicator

- **What:** a line `description: |` (or `>-`, `|2-`, …) — including one carrying a trailing
  YAML comment (`>- # text`) — is `BLOCK-SCALAR` only when the next non-blank frontmatter
  line is not indented (i.e. the body is missing). Otherwise the skill is healthy and the
  description is a preview of the indented text.
- **Why:** the loader's failure mode is presenting the literal indicator as the description;
  with a body the YAML value is the text, so there is no failure. Detecting "starts with an
  indicator" instead of "has no value" is exactly the class of bug where a scanner trusts a
  shape and not the content. A trailing comment is still an indicator and still needs a body;
  treating it as anything else would re-introduce the same literal-as-description failure.
- **Discarded alternative:** keep the old rule and change the fixture — rejected: the fixture
  was wrong about what a block scalar is, and "fixing" the fixture to match a wrong detector is
  how the false positive stays believed.

### Decision: The inventory's description is a first-line preview, elided

- **What:** `DESC` for a healthy block/folded scalar is the body's first line, joined with
  `…` when the body spans more than one line.
- **Why:** the registry is an inventory, not a YAML parser (see Goals/Non-Goals). A full
  multi-line body in the record stream would bury the per-skill one-liner the inventory is
  for; eliding the rest while signalling it ("…") keeps the record honest without pretending
  to parse. The suite pins the elision by asserting the full first line *including* the `…`.
- **Consequences:** a multi-line body can never be silently reported as if it were the whole
  description — the `…` is the honest marker of truncation, and the task/spec wording says
  "first line" rather than "the body".

### Decision: The suite replaces the unrun fixtures as the gate

- **What:** `fixtures/skill-registry/check.sh` executes the command over both roots and asserts
  each fixture's expected flag, failing loudly when it cannot run.
- **Why:** the reason the false positive survived is that nothing executed the inventory; a
  fixture that exists but never runs is documentation, not a test. The same fail-loud contract
  as the other fixture suites (`exit 3`-style when unrunnable) applies.
- **Consequences:** the inventory of the real tree becomes the acceptance check: the task
  asserts `context-architecture` reports without `BLOCK-SCALAR`.

## Delivery strategy (recorded per `workflows/implement-change.md`)

**Choice: `single-pr`.** Small, self-contained follow-up on `main`; the work units are the
detector fix, the rewritten/added fixtures, and the new suite.

## Risks / Trade-offs

- **Risk:** the content test mis-classifies an empty-but-legal edge case (e.g. `|` with a blank
  line only). **Mitigation:** the suite pins the empty case (the defect) and the case with a
  body; the distinction is "is there an indented line", which blank lines do not satisfy.
- **Risk:** `context-architecture` could still be unusual in some other way. **Mitigation:** the
  real-tree check is an explicit task; if any other skill mis-reports, the suite run over
  `~/.hermes/skills` surfaces it.
