# Rule: Project boundaries

Strict isolation rule for all Hermes agents and workflows. If it is broken,
the whole system becomes contaminated: foreign specs, another client's requirements, decisions of
one product applied to another.

## Principle

> Hermes provides the **process** (global and reusable). The project provides the **product**
> (local and non-transferable).

| Global — `~/.hermes/**` (Hermes) | Local — the project |
|---|---|
| agents, workflows, rules, templates | `openspec/` (changes, specs, archive, project.md) |
| quality, process and report-format conventions | requirements, domain, business rules, product decisions |
| tool knowledge (OpenSpec CLI, git, CI) | source code, tests, docs, `AGENTS.md` / `.hermes.md` |
| reusable skills | build/test/lint commands specific to the stack |
| — | change history, ADRs, client context |

Corollary: **a global instruction never contains a product requirement.** If some
knowledge is useful for only one project, it lives in that project.

## Hard rules

1. **Hermes' instructions are global and reusable.** They may talk about the process,
   never about a product, a client or a concrete requirement.
2. **Product knowledge is local to the project.** Domain, business rules,
   requirements, decisions and client context are written in the project's repo.
3. **OpenSpec always lives inside the repository of the current project.** Never in
   `~/.hermes/`, never in a shared directory, never in a global store out of habit.
4. **Agents read `openspec/` only from the current project root.** A single root per stage.
5. **Agents never read OpenSpec files from sibling directories.** Not to compare,
   not to copy, not "to see how the other project did it".
6. **Agents never apply requirements from one project to another.** Not specs, not domain
   conventions, not product architecture decisions, not client data.
7. **If `openspec/project.md` does not exist in the current project, Hermes first runs
   `workflows/initialize-project.md`.** It is a blocking preflight of any workflow.
   Hermes convention, not the CLI's: `openspec validate/list/status` **ignore** that file
   (verified in v1.13.0) — it exists for the human and for the agents, and the workflow creates it.
8. **If the human asks to work on several projects, they are separate workflows.** One per
   project, with its own preflight, its own root and its own report. Never a run
   that mixes two.
9. **Every report includes the project root used in that run** (`projectRoot` in the
   envelope, `rules/orchestration.md`).
10. **Every workflow fails safely if the root is not clear.** In the face of ambiguity: nothing
    is written, nothing is read from another project, the blocker is reported.
11. **Hermes never stores client or product requirements in global agent files**
    (rules, workflows, agents, templates, global memory).

## How to resolve and verify the root

`openspec` acts on the `openspec/` **closest to the cwd**: if the cwd is the wrong one, the
command touches the wrong project without warning. That is why the root is not assumed: it is
resolved and **contrasted** against the expected root.

```bash
cd <expected-project-root>
pwd -P                                   # physical path (macOS: /tmp ⇒ /private/tmp)
git rev-parse --show-toplevel 2>/dev/null || echo "no-git"
openspec context --json                  # root.path, or root=null with code=no_openspec_root
```

Mandatory check before any phase:

- `root.path` (normalized) **must be equal** to the expected project root. If it differs, stop.
- **Nested root danger**: from a subdirectory with its own `openspec/`, `root.path`
  changes silently — verified: with `openspec/` at the root and in `packages/a/`,
  `openspec context --json` at the root returns the root and in `packages/a` returns
  `packages/a`; `members` came back `[]` in both cases, so there is **no** warning. In a monorepo:
  fix the root once (root or package), write it in the repo's `AGENTS.md` and do not
  change it in the middle of a workflow.
- Compare paths with `pwd -P` / `realpath`: on macOS `/tmp` is a symlink to `/private/tmp` and
  a string comparison fails with two paths that point to the same place.
- If `openspec context --json` returns `root: null` with `status[0].code ==
  "no_openspec_root"`, the project is not initialized: there is no possible stage.

Every command that touches OpenSpec is issued with the project's cwd (`cd <root> && …`, or the
tool's `workdir`) and **every agent brief carries the literal root**. The shell's cwd
can change during the session: it is not a source of truth.

## Correct examples

Resolving the root and working against it:

```bash
cd <project-root>/filter
openspec context --json | jq -r '.root.path'      # <project-root>/filter
openspec list --json                              # changes of the active project, and only of it
openspec instructions proposal --change "<name>" --json   # writes to the project's resolvedOutputPath
```

- Preflight that stops when the product context is missing:

  ```bash
  cd <project-root>
  test -f openspec/project.md || echo "MISSING openspec/project.md → initialize-project"
  ```

- Correct brief from Hermes to an agent (minimal context, a single root):

  ```
  projectRoot: <project-root>/filter
  change: filter-array-dates   (openspec/changes/filter-array-dates/)
  files you may touch: src/operators/datetime/*.ts, src/utils/date-time/*.ts
  verification: pnpm test && pnpm typecheck
  what NOT to do: touch openspec/specs/, other repos, or files outside the list
  ```

- Two projects requested by the human ⇒ two runs:

  ```
  workflow A: root=<project A>, change=<A>, report A with projectRoot=<A>
  workflow B: root=<project B>, change=<B>, report B with projectRoot=<B>
  ```

- Correct global knowledge: "fixes carry a regression test that fails without the fix"
  (`rules/testing.md`). Correct local knowledge: "a request without `tenantId` is rejected
  with 403" (goes in the project's spec/ADR, not in a global rule).

## Incorrect examples

Reading or listing specs from a sibling project:

```bash
# WRONG: contaminates the stage with context from another product
openspec --store other-project list --specs --json
cat ../../gatekeepr/openspec/specs/tenant-rbac/spec.md
grep -r "tenant" ../other-project/openspec/
```

Wrong CWD ⇒ writes to the wrong project:

```bash
# WRONG: `openspec new change` creates a spurious root in the cwd when there is no root (verified)
cd ~ && openspec new change "my-change"
# WRONG: from a monorepo package, when the stage belongs to the root
cd packages/a && openspec new change "root-change"
```

Copying content from another project:

```
WRONG: "I used gatekeepr's requirements as a template for this project"
WRONG: "I adopted the neighboring repo's spec structure as a convention here"
RIGHT: use ~/.hermes/templates/*.md (reusable structure), never content from another repo.
```

Mixing into a single piece of work:

```
WRONG: a brief that includes two project roots.
WRONG: a review that reports findings from two repos in the same report.
WRONG: reusing one project's QA report to close another's release.
```

Storing product as global truth:

```
WRONG: adding "every endpoint needs an X-Tenant header" to rules/coding.md because this
     project uses it.
WRONG: storing in global memory that client Y demands such and such behavior.
RIGHT: that goes in the project's spec/ADR; if it is a truly universal pattern, it is proposed
      as a change to the global rules and the human decides.
```

## Failure behavior (fail-safe)

Without a clear root **there is no progress**. The workflow stops before reading or writing:

| Situation | Detection | Behavior |
|---|---|---|
| There is no `openspec/` | `context` → `root: null`, `no_openspec_root` | Stop. `blocked`: run `initialize-project` (do not create anything by hand) |
| Root ambiguous or different from the expected one | `root.path != <expected root>` | Stop. Report both paths and ask for human confirmation |
| Nested root (root vs package) | `root.path` changes when the cwd changes | Stop. Decide the root with the human, write it in `AGENTS.md`, restart the stage |
| `openspec/project.md` missing | `test -f openspec/project.md` | Stop. `blocked`: run `initialize-project` first |
| The brief brings two projects | two roots in the brief | Reject the brief. Open separate workflows |
| Context from another project appears | finding from the agent or from Hermes | Discard the whole output and repeat the stage without that context |
| Path suspected of being global | product is about to be written to `~/.hermes/**` | Block the step; the file goes to the project |

Blocker format (`rules/orchestration.md` envelope):

```
status:              blocked
summary:             project root not resolved / ambiguous
projectRoot:         <resolved path or "indeterminate">
filesCreated:        []
filesModified:       []
blockers:            <what was expected>, <what openspec context --json returned>, <required decision>
nextRecommendedStep: initialize-project, or confirm the root with the human
evidence:            literal output of `openspec context --json` and of `pwd -P`
openQuestions:       <root to fix if the repo is a monorepo>
```

Safe-failure rules:

- Never "continue with the most likely root". Ambiguity = stop and ask.
- Never create an `openspec/` to get out of trouble: the root is initialized by the workflow
  (`openspec init --tools hermes`), from the confirmed root.
- Never leave a spurious root behind as residue: if `openspec new change` ran in the wrong
  cwd and created an `openspec/` outside the project, it is deleted and the incident is reported.
- A boundary failure is not resolved by improvising: it is reported with evidence and the
  human decides.

## Boundary verification (before closing a stage)

1. Are all written files inside the project root? (`git status --porcelain` of the
   project, or `find` bounded to the root).
2. Did any file with product content land in `~/.hermes/**`? ⇒ move it to the project and
   leave only the reusable part in Hermes.
3. Was context from another project read or used? ⇒ discard the output and repeat the stage.
4. Does `openspec context --json` from the cwd still point to the expected root?
5. Does the report declare `projectRoot` and does it match the root verified in step 1?
