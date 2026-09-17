# External personas and process skills (aitmpl.com)

There are two kinds of component behind a stage, and they install through different helpers:

- **Persona** — domain expertise (`~/.hermes/skills/agents/<slug>/SKILL.md`), converted from
  an agent definition (`~/.claude/agents/<slug>.md`) with `hermes-add-agent`.
- **Process skill** — the *how* of a stage (how to verify before claiming done, how to
  dispatch parallel agents, how to write a plan). Installed from the skills catalogue with
  `hermes-add-skill <category>/<slug>`.

The role files in `~/.hermes/agents/*.md` are contracts (brief, envelope, Done criteria).
Neither kind replaces them: a persona supplies expertise, a process skill supplies method.

## Role → components

| Role | Personas | Process skills |
|---|---|---|
| discovery | `codebase-explorer`, `prd` | `requirements-clarity` (only when the input arrives vague) |
| openspec | `sdd-spec-writer` (SDD-explicit), `research-technical-spike` in explore | — |
| architect | `code-architect`, `architect-reviewer` | `architecture-decision-records` |
| planner | `task-decomposition-expert` | `writing-plans` |
| builder | `fullstack-developer`, `typescript-pro`; `debugger` / `error-detective` when a task stalls | `executing-plans` |
| reviewer | `code-reviewer`, `code-simplifier`, `supply-chain-security` | `code-review-checklist` |
| qa | `qa-expert`, `test-engineer` | `qa-test-planner`, `e2e-testing-patterns` |
| release | `git-workflow-manager` | `commit-smart` |
| — (Hermes itself) | — | `verification-before-completion`, `dispatching-parallel-agents`, `context-architecture` |

`legacy-modernizer` and `technical-debt-manager` attach to refactor-shaped changes, not to a
fixed stage. `verification-before-completion` is the load-bearing one: it is the method behind
the evidence rule, so prefer it over another written reminder.

On aitmpl the source path is `<category>/<slug>`; the slugs above live under
`development-team/`, `development-tools/`, `ai-specialists/`, `git/`, `security/`,
`modernization/`, `data-ai/` and `productivity/`.

## Install procedure

1. **Locate before installing — name collisions are silent.** Local skills win over external
   dirs, so an install can look successful while the index still resolves the old copy. Check
   the real destination with `find ~/.hermes/skills ~/.agents/skills -name '<slug>' -maxdepth 3`
   rather than assuming a directory. Verify after installing by reading back
   `grep -m1 '^description:' <skill-dir>/SKILL.md` — never the installer's exit message.
2. Personas: fetch into `~/.claude/agents/<slug>.md` (never hand-copy into `~/.hermes`), then
   `hermes-add-agent <slug>` (`--force` to re-sync after editing the source).
3. Process skills: `hermes-add-skill <category>/<slug>` (`--force` to overwrite).
4. Both load in the NEXT session (the system prompt is cached per conversation).
   `hermes skills list` scans live and proves the file landed, not that the model saw it.

### Where `hermes-add-skill` actually writes

Its docstring says `~/.agents/skills`, but the real default is `$HERMES_HOME/skills` whenever
`HERMES_HOME` is set — i.e. always, in a Hermes session — and the closing line still claims the
`~/.agents` dir. Trust the resolved path, not the message or the docstring.

Skills installed there are **user-owned, not curator-managed**: `skill_manage` will refuse to
patch them, which is correct and not a bug to route around.

## Host and quota when downloading many components

Two hosts serve the same blobs and fail differently:

| Host | Limit | Failure |
|---|---|---|
| `raw.githubusercontent.com` | none for public repos | intermittent `HTTP 503: Backend.max_conn reached` |
| `api.github.com/.../contents/<path>` | **60 requests/hour unauthenticated** | `HTTP Error 403: rate limit exceeded` |

The anonymous API quota is spent in seconds by a bulk download: a tree listing plus ~60 blobs
exhausts it, and every later file 403s while raw still serves 200. Rules that follow:

- Download component blobs from **raw**, with retries:
  `curl -fsSL --retry 3 --retry-delay 2 -o <dest> '<raw-url>'`.
- Spend API requests only on the single enumeration call, or authenticate: `gh api <path>`
  uses the 5000/h quota. Confirm the login with `gh auth status` before blaming the network.
- Both local helpers (`hermes-add-agent`, `hermes-add-skill`) call `api.github.com`
  **unauthenticated** by default, so `--search` and any multi-file skill die on the anonymous
  quota. The fix is a token, resolved in this order: `GITHUB_TOKEN`, `GH_TOKEN`, then
  `gh auth token` — inject it as an `Authorization: Bearer` header in the helper's request
  headers once, at module import, and every call afterwards uses the 5000/h quota.

## Enumerating the catalogue without the site UI

`--search ""` errors out (it needs a non-empty term) and prints no totals. Two ways to get the
full list:

- Loop the search over `a`–`z` plus `-`, collect `<cat>/<slug>` lines and dedupe. Reachable but
  **incomplete**: it misses slugs whose letters are all covered by other matches (agents: ~370
  of 424; skills: far worse, ~883 of 898).
- One API request: `git/trees/main?recursive=1`, then filter
  `cli-tool/components/agents/**/*.md` or `cli-tool/components/skills/**/SKILL.md`. Complete
  and cheap — use this for anything you intend to reason about as a whole.

## Support directories, READMEs and duplicate entries

`hermes-add-skill` downloads `references/`, `templates/`, `scripts/`, `resources/` and
`examples/` alongside `SKILL.md`, but **not** `README.md`. Some components keep their worked
examples and task templates there, so the skill lands incomplete without it. Check the tree
for one before fetching; a 404 is expected, not a failure:

```bash
curl -fsSL -o ~/.hermes/skills/<slug>/README.md \
  'https://raw.githubusercontent.com/davila7/claude-code-templates/main/cli-tool/components/skills/<cat>/<slug>/README.md'
```

**The same skill is listed under two categories** — `executing-plans` and `writing-plans`
(`development/`, `productivity/`), `dispatching-parallel-agents` (`ai-research/`,
`development/`), `planning-with-files` (`productivity/`, `workflow-automation/`). Verified
byte-identical between paths (differences against the local copy are only the helper's own
normalization comments), so dedupe by slug: pick either path and install once. Counting
skills by path double-counts these.

## Upstream defects (silent failures)

**Agent frontmatter** is copied verbatim by `hermes-add-agent`, so a defective source produces
a skill that loads but routes to nothing:

- **No frontmatter at all** (file starts at `# Title`) → the helper invents
  `Use when working with the <name> persona.`, which says nothing.
- **Block-scalar description** (`description: |` plus indented text) → the literal `|` ends up as
  the description.
- **Malformed fences** → `***` and `-------------` are alternatives to `---`.

Fix in the source file (`~/.claude/agents/<slug>.md`), re-run with `--force`, then read the
rendered description back. The persona's first heading or its block-scalar first line is the
right summary; shorten it to fit the 60-char index budget with the trigger in the first 57.

**Skill frontmatter** is normalized by `hermes-add-skill` (`name:` rewritten to the directory
slug, long trigger-phrase descriptions condensed, original kept as a comment), so the upstream
name/description mismatch that bites agents does not bite skills. Two caveats:

- **Re-running the installer with `--force` renormalizes an already-trimmed description.**
  Re-installing the same skill to pick up a missing support file therefore rewrites its
  `description:` line even though nothing upstream changed. Diff before and after when the
  exact text matters.
- The remaining skill-specific trap is size, not corruption: a single process skill can carry
  10–27 KB of body, so install one only when its stage actually needs it. Each installed skill
  costs a line in the system-prompt index on **every** session (~60 chars of description),
  which is why the table above lists a process skill per stage instead of every plausible one.

### Audit an install (what actually landed)

Exit messages prove nothing. This compares the repo tree against the local directory and is
the check to run after any batch:

```python
paths = open('/tmp/tree.txt').read().splitlines()   # from git/trees/main?recursive=1
want = {p.split(f'/{slug}/',1)[1] for p in paths if f'/{slug}/' in p and 'components/skills' in p}
have = {str(p.relative_to(root)) for p in root.rglob('*') if p.is_file()}
print('missing:', sorted(want - have))
```

Expected result for a clean install: `missing` holds only directory entries (the set includes
folders) and, at most, the component's `README.md`. Anything else is a real gap.
