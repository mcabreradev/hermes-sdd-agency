# Workflow: initialize-project

Initializes the current project's repository so that Hermes can manage it with
OpenSpec. It is the **first workflow** of every project: its absence blocks the others
(`rules/project-boundaries.md`).

- **Agents:** `discovery` (optional, if the repo already has code) · `openspec`
- **Rules:** `rules/project-boundaries.md`, `rules/orchestration.md`, `rules/openspec.md`
- **Creates (inside the project):** `openspec/` if missing · `openspec/project.md` ·
  `docs/architecture/` · `docs/decisions/` · `reports/` ·
  `reports/initialize-project.md`
- **Never creates:** implementation code, nor agents/workflows copied from Hermes.
- **Personas/method:** `codebase-explorer` + `prd` (discovery) · `sdd-spec-writer` (openspec) · `context-architecture` to leave the repo legible to agents.

## Inputs (provided by the human)

| Input | What it is | Where it ends up |
|---|---|---|
| project name | canonical name of the project/repo | `project.md` → `# Project:` + verification in step 2 |
| product idea | what it is and what problem it solves | `project.md` → Purpose |
| target users | who it is for | `project.md` → Target Users |
| main problem | main problem (if not given, it is derived from the product idea) | `project.md` → Main Problem |
| MVP goal | what the first version must achieve | `project.md` → MVP Goal + Scope |
| scope / non-goals | what is in and what is out | `project.md` → Scope / Non-Goals |
| preferred stack | languages, frameworks, services | `project.md` → Preferred Stack (+ real commands) |
| business rules | domain rules the software must respect | `project.md` → Business Rules |
| technical constraints | limits: platform, performance, integrations, security | `project.md` → Technical Constraints |
| architecture principles | principles that govern the design | `project.md` → Architecture Principles + `docs/architecture/` |
| product rules | what the product must and must not do | `project.md` → Product Rules |
| quality expectations | expected quality level (tests, coverage, gate) | `project.md` → Quality Expectations |

Hermes asks for whatever is missing before writing (`clarify`, ambiguity rule of
`rules/orchestration.md`: business, architecture, security and scope are decided by the human).

- **No input is invented.** Whatever the human cannot answer now is written into
  `project.md` as `Pending: <question>` and reported in `blockers`/`openQuestions`.
- If the repo already has code, its verified facts (real stack, commands, structure)
  take priority over the "preferred stack" input: the divergence is detected and reported.
- The inputs are **the project's**: they are written only to the repo, never to `~/.hermes/**`.

## 1. Detect the project root

```bash
cd <project-root>
pwd -P                                        # physical path (macOS: /tmp ⇒ /private/tmp)
git rev-parse --show-toplevel 2>/dev/null || echo "no-git"
openspec context --json                       # root.path, or root=null with no_openspec_root
```

Without a clear root **nothing advances**: the fail-safe of `rules/project-boundaries.md`
is applied (blocked with evidence, without writing anything).

## 2. Verify that it is the intended repository

Before creating a single file, confirm identity. Initialization writes structure
into a repo: doing it in the wrong place contaminates two projects.

```bash
basename "$(pwd -P)"                          # must correspond to the project name
git remote -v 2>/dev/null || echo "no-remote"
git log -1 --format='%h %ad %s' 2>/dev/null || echo "no-commits"
ls openspec/project.md 2>/dev/null && echo "ALREADY INITIALIZED" || echo "no project.md"
```

- `root.path` (normalized) **must be equal** to the expected root; if it differs (or the cwd
  fell into a nested root of a monorepo), stop and ask.
- The directory/remote name must correspond to the `project name` of the input. If it
  does not match, or the repo is not git, **ask the human** before continuing.
- If `openspec/project.md` already exists: **it is not an initialization, it is a revision**. The
  current state is reported and it is decided with the human whether to update it (merge) or abort.
- If the repo already has code, run the `discovery` agent (brief: root, objective
  "survey the real stack and commands", what NOT to survey). Its report provides the stack, build/test/lint
  commands, directory map and test status, with evidence.

## 3. Create the project's `openspec/` if missing

Never by hand: the CLI creates it, and **from the confirmed root** (in the wrong cwd the CLI
creates a spurious root without warning).

```bash
cd <project-root>
openspec context --json                # is there already a root?
openspec init --tools hermes --no-animation     # only if there is no root
openspec context --json                # root.path == <project-root>
openspec list --json
openspec list --specs --json
```

- `--tools hermes` generates the project's local `openspec-*` skills: that is the CLI's doing, not
  a copy of the Hermes agents (see step 8).
- Monorepo: decide the root (root or package) **once** and write it into `project.md` and into
  the repo's `AGENTS.md`. `openspec context --json` changes root according to the cwd, without warning.
- Non-git project: warn that the local skills are not discovered the same way (cwd-only) and that there
  are no branch/commit conventions.

## 4. Create `openspec/project.md` from the global template

Source: `~/.hermes/templates/openspec-project.md` — it contains the markdown to copy verbatim
with its `{{variables}}` and the substitution table. It is rendered with the human's inputs and
with the facts verified in step 2, and written **into the project**, at
`openspec/project.md`.

```bash
ls openspec/project.md
grep -c '{{' openspec/project.md       # must be 0: no placeholders remain
```

- Every `{{variable}}` without an answer from the human is replaced by `Pending: <question>`
  (the placeholder is never left, the content is never invented).
- The `## Agentic Workflow Rules` section is copied **literally**, without editing bullets.
- It is a **Hermes convention**, not the CLI's: `openspec validate/list/status` ignore it
  completely (verified in v1.13.0: with `project.md` present, `validate --all --json` and
  `list --specs --json` do not change). It exists for the human and for the agents, and it is the
  local marker of "this project has already entered the loop".

## 5. Create `docs/architecture/` if missing

Project structure for the current architecture:

```bash
mkdir -p docs/architecture && touch docs/architecture/.gitkeep     # if it was empty
```

- `.gitkeep` (or the repo's equivalent) so that the directory exists in git.
- If the project already has its place for architecture, **respect it** and record in
  `project.md` where it lives: the convention is Hermes's, the repo rules.
- No architecture is written here: that is the `architect` agent's job during
  `workflows/openspec-to-architecture.md`. This step creates the place, not the content.

## 6. Create `docs/decisions/` if missing

Project ADR directory (template: `~/.hermes/templates/adr.md`):

```bash
mkdir -p docs/decisions
```

ADRs are **the project's** and are created when there is a decision to record, not in
advance. This step creates the directory and, if the repo already has ADRs elsewhere, that
place is respected.

## 7. Create `reports/` if missing

Project run-artifact directory (review reports, QA, final reports):

```bash
mkdir -p reports
```

- Location convention: `reports/<workflow>.md` (for example
  `reports/initialize-project.md`, `reports/review-<change>.md`).
- If the repo prefers another location (or ignores them via `.gitignore`), it is respected: the
  real location is recorded in `project.md` and used in the briefs.
- Reports belong to the project: they are never written to `~/.hermes/**`.

## 8. Do not copy global agents into the project

**Prohibited.** The agents and workflows of `~/.hermes/` are Hermes process contracts and
continue to live there:

```
WRONG:  cp -r ~/.hermes/agents ./agents
WRONG:  cp ~/.hermes/rules/*.md ./rules/
WRONG:  duplicating a Hermes workflow inside the repo "for convenience"
RIGHT:  reference the global rules by path (and leave the project's local ones in AGENTS.md)
```

- A local copy silently becomes obsolete and mixes global process with local product
  (`rules/project-boundaries.md`).
- Legitimate exception: `.hermes/skills/openspec-*`, which the OpenSpec CLI generates
  (`openspec init --tools hermes` / `openspec update`) — versioned with the project.
- The repo's `AGENTS.md` contains only **project** rules (commands, style, fixed
  root, its own conventions).

## 9. Do not create implementation code

**Prohibited.** This workflow produces context and structure, not functionality:

- no `src/`, `app/`, `main.*`, product tests or build configuration;
- no "incidental" scaffolding (frameworks, linters, CI) unless the human explicitly asks
  for it as a separate OpenSpec change;
- the first line of product code is born in
  `workflows/idea-to-openspec.md` → `plan-change` → `implement-change`, with a validated change
  (`rules/openspec.md`).

## 10. Generate `reports/initialize-project.md`

Template: `~/.hermes/templates/initialize-project-report.md`, written into the project.

```bash
ls reports/initialize-project.md
```

Minimum content: verified project root, inputs received (and those left
`Pending`), state of `openspec/` (root, active changes, capabilities), the repo's real
commands, structure created, what was **not** created (code, copied agents) and the next
step.

## Completeness criteria

- [ ] `openspec/project.md` exists in the current project.
- [ ] `docs/architecture/` exists.
- [ ] `docs/decisions/` exists.
- [ ] `reports/initialize-project.md` exists.
- [ ] No product feature implementation was created.
- [ ] Nothing written outside the project root; no agent/workflow copied into the repo.
- [ ] `openspec context --json` points to the project root and only to it.
- [ ] `openspec validate --all --json` → 0 failed (if something fails, the finding is reported; it is
      not patched by hand).

```bash
cd <project-root>
test -f openspec/project.md && test -d docs/architecture && test -d docs/decisions \
  && test -f reports/initialize-project.md && echo "OK initialization"
openspec context --json
openspec validate --all --json | jq -c '.summary.totals'
git status --porcelain
```

## Return (to Hermes)

Mandatory envelope (`rules/orchestration.md`):

```
status:              done | blocked | needs-context
summary:             one line: project initialized with OpenSpec
projectRoot:         verified absolute path
filesCreated:        openspec/project.md, docs/architecture/, docs/decisions/, reports/, reports/initialize-project.md (or [])
filesModified:       <paths> (or [])
blockers:            <doubtful root, wrong repo, missing inputs that block> (or [])
nextRecommendedStep: idea-to-openspec (or the workflow that applies)
evidence:            openspec context --json, validate --all --json, git status --porcelain
openQuestions:       <pending inputs: business rules, MVP, constraints> (or [])
```

## Typical errors

- Initializing without confirming the repo (step 2) ⇒ structure in the wrong project.
- Creating `openspec/` with `mkdir` or from the wrong cwd ⇒ spurious root or change without
  metadata (`.openspec.yaml`).
- Copying global agents/workflows into the repo ⇒ duplicated and outdated process.
- Writing architecture or incidental scaffolding ⇒ implementation without a validated change.
- Inventing business rules or users that the human did not give ⇒ `project.md` with fiction.
- Leaving the root ambiguous in a monorepo: `openspec context --json` changes according to the cwd.
