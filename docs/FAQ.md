# FAQ

### What exactly is this repo?

It is the **process** of a Spec-Driven Development agency for Hermes Agent: reusable
rules, workflows, agent contracts, templates, skill bundles and personas. It contains
no project's requirements — those live in each project's own `openspec/`.

### Do I need OpenSpec installed to use it?

Yes. The loop is built on the OpenSpec CLI (`openspec`). It must be ≥ 1.13.0 and on
your `PATH` (e.g. `~/.local/bin/openspec`). Hermes runs it from each project root.

### Do I need to install all 12 bundles?

No. `/agencia` loads the orchestrator plus `openspec-sdd`. The per-stage commands are
convenience entry points. The task-level shortcuts are:

- `/feature` → full loop, starting with analysis.
- `/bugfix` → minimal change with behavior, `skip_specs`, must carry a regression test.
- `/fix` → cosmetic, no behavior change, no OpenSpec change.

### When is a feature vs a bugfix vs a fix?

Hermes classifies by the three task levels (`rules/openspec.md`), and the classifier
diagram is in `docs/usage-examples.md`. Short version: does it change observable
behavior? Does it touch a business rule, a contract, or architecture? Feature if yes
to behavior + scope; minimal if it is a bounded behavior fix; cosmetic if no behavior
change at all.

### Can two agents talk to each other?

**No.** Agents never talk to each other and never read each other's state. Every output
returns to Hermes in the mandatory envelope and is re-verified in the repo. Hermes is
the only bus (`rules/orchestration.md`).

### Who can block progress?

Only the **reviewer** (`changes-requested`) and the **qa** agent (`fail`). They are the
two stages with blocking authority. Open BLOCKER/MAJOR, a `qa: fail` or any `blocked`
halts the workflow.

### What does "no code without a validated change" mean in practice?

From the project root, before `implement` starts, all of these must pass
(`rules/openspec.md`):

```bash
test -f openspec/project.md                        # else run initialize-project first
openspec context --json                            # root.path == expected root
openspec validate "<name>" --type change --json     # no ERROR
openspec instructions apply --change "<name>" --json  # state: ready
```

### Do I have to write the spec prose by hand?

No. The openspec stage's agent (persona `sdd-spec-writer`) writes the change artifacts
via the CLI. You supply the clear idea and the repo; Hermes and the stage agents produce
the proposal, spec deltas, design, tasks and code.

### The docs say the loop hasn't been run end to end. Should I trust it?

Not blindly. Treat the briefs and envelopes as **contracts, not enforcement**: before
trusting the loop on a large change, run a small (3–5 task) change end to end with real
delegations. Expect the first envelope to come back incomplete — that is the signal to
make the brief stricter with the exact command to run and the exact output to paste,
rather than adding prose to `rules/` (`agents/README.md`).

### Is everything in English?

Yes. All specs, docs, code, commits and PRs in this repo are English. The one exception
is the *conversation with the user* in Hermes, which may be in any language
(`rules/sdd.md`).

### Will installing overwrite my existing Hermes skills?

The skills in this repo install under `~/.hermes/skills/`. They only overwrite names
they own (the personas and process skills that back the agency). Local skills named
identically win, so review the names before a bulk copy. Use `INSTALL.md` for the
sanitized procedure.

### Can I use this on several projects at once?

Yes. Each project is a separate workflow with its own root, change and final report
(`rules/project-boundaries.md`). Hermes can run independent stages in parallel via
`delegate_task`; it never mixes context across projects.

### How do I keep my fork in sync with the upstream?

`rules/`, `agents/`, `workflows/`, `templates/`, `docs/`, `skill-bundles/` and the
relevant `skills/` are copied from `~/.hermes/`. When you change one locally, re-copy
that directory here and commit (`INSTALL.md`). For a fork, use standard
`git remote add upstream … && git pull`.
