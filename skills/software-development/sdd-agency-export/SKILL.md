---
name: sdd-agency-export
description: "Use when mirroring the Hermes SDD agency to a git repo."
metadata:
  hermes:
    tags: [sdd, openspec, export, publication, sanitization, github, hermes]
---
# SDD Agency Export

How to mirror the global process system (`~/.hermes/{agents,workflows,rules,templates,docs,skill-bundles,skills}`) into a versionable, public-ready repo.

The whole tree is *process* (global, reusable) and contains no product requirements, so it ports cleanly to another machine or a fork — `rules/project-boundaries.md`. But it must be **sanitized and complete** before it ships. Every step below is load-bearing.

## What to copy (and what to EXCLUDE)

Copy the process tree:

```bash
DEST=~/Workspace/<x>/<repo-name>
mkdir -p "$DEST" && cd "$DEST" && git init -b main
mkdir -p agents workflows rules templates docs skill-bundles skills/agents
cp ~/.hermes/agents/*.md agents/
cp ~/.hermes/workflows/*.md workflows/
cp ~/.hermes/rules/*.md rules/
cp ~/.hermes/templates/*.md templates/
cp ~/.hermes/docs/*.md docs/
cp ~/.hermes/skill-bundles/*.yaml skill-bundles/
cp -R ~/.hermes/skills/agents/. skills/agents/
```

Exclude **always** (machine-specific, never public): `config.yaml`, `memories/`, `.env`, `auth.json`, `profiles/`, any project content. The process tree is a clean copy; those are the boundaries.

## Completeness: walk the load/reference graph, don't guess

The first export is **incomplete to a fault**: copying the obvious dirs (`skills/agents/` personas + bundles) misses what the bundles actually load. Capture the full dependency closure:

- Each bundle's `skills:` list (e.g. `/agency` loads `hermes-sdd-orchestration` + `openspec-sdd`).
- `openspec-sdd`'s SKILL.md references the `openspec-*` CLI skills **by phase** (`/openspec-explore`, `/openspec-propose`, `/openspec-new-change`, … `/openspec-archive-change`).
- The 11 per-role process skills (`requirements-clarity`, `executing-plans`, `code-review-checklist`, `verification-before-completion`, …).

Rule: a skill is not exported because it is listed here, but because it is reachable from what you already ship. Trace references, then verify the file count matches. The orchestrator skills live in `skills/software-development/` on this machine; the `openspec-*` CLI skills live in `~/.hermes/openspec-global/.hermes/skills/` (that is the real `skills.external_dirs` path — copy from there, not `.agents/skills/`).

## Sanitize before publishing (public + local-machine reuse)

Run this over the whole copied tree and fix every hit **before** commit. Public repos leak real names and absolute paths.

| Source of leak | Where it hides | Fix |
|---|---|---|
| Absolute local paths | `rules/project-boundaries.md` example blocks (`cd /Users/x/.../filter`) | `<project-root>/filter` |
| Persona provenance | `hermes-add-agent` injects `Converted from /Users/x/.claude/...` into every persona SKILL.md | `~/.claude/agents/<slug>.md` (keep the `~` generic) |
| Real usernames | `rules/sdd.md` language contract quoting the user's name | drop the name |
| Machine refs | `openspec-sdd` had `~/Workspace/<user>/<proj>` | `<project-root>/<proj>` |
| Tokens / emails | any | scrub |

Grep pattern to run after cleaning — a hit is a leak, not a false alarm:

```bash
git grep -rniE '/Users/[a-z]|/home/[a-z]|mcabrera|Miguelangel|gho_|ghp_|github_pat|api_key|secret|password|token[=:]|Workspace/' -- .
```

Distinguish **intentional** hits (your own repo URL in `INSTALL.md`/`CHANGELOG.md`, your name in `LICENSE`) from real leaks. **Verify the REMOTE tree too**, not just the working copy — local hygiene and what GitHub serves are two different things:

```bash
gh api repos/<owner>/<repo>/git/trees/main?recursive=1 --jq '.tree[].path' | \
  grep -Eic 'migue|mcabrera|\.env'   # 0 = clean
```

## Publish to GitHub (public repo)

```bash
git add -A && git commit -m "<scope>: <summary>" && git push -u origin main
git tag -a v0.1.0 -m "..." && git push origin v0.1.0
# one commit per concern: export, + orchestration skills, + openspec-* CLI, + docs, ...
```

- Create the repo PUBLIC with `gh repo create` (visibility is one-way; confirm with the user before making it public — public is irreversible, private is not).
- Configure metadata: `gh repo edit --add-topic ...` (topics improve discovery), `--description`, `--homepage`.
- Create a release page from the tag with `gh release create v0.1.0 --title ... --notes "$(cat <<'EOF' ... EOF)"` — notes summarize the export.
- **Do NOT ship calibration/'not yet validated' caveats in public docs or release notes unless the user asks for them.** This user's preference is that their own public repo does not advertise that the loop is unproven. When he says "no quiero ser tan honesto," remove the 'not yet exercised / contracts not enforcement / before trusting it' notes from EVERY public artifact: README, CHANGELOG, FAQ, agents/README, and the orchestration skill — grep for `calibration`, `not been run`, `not been exercised`, `contracts, not enforcement` and delete each, in one sweep, not leaving it in one doc. Keeping one honest 'self-report, not a fact' verification rule is fine (it is discipline, not a limitation); dropping only the 'untested' ones. This is a content-preference for the public face of the repo — re-assert it each export, do not re-add such caveats when writing fresh docs.

## GitHub Pages landing (publish a site from the repo)

A static `index.html` in the repo root becomes a live landing via GitHub Pages — the site is versionable (commit the HTML, site updates with the branch). Activate on `main`, root `/`, and force HTTPS:

```bash
gh api -X POST repos/<owner>/<repo>/pages -f "source[branch]=main" -f "source[path]=/" -f https_enforced=true
git add index.html && git commit && git push   # site serves https://<owner>.github.io/<repo>/
```

**Account-level custom-domain trap:** a project site's Pages URL shows the *user site's* custom domain even when the project repo has no `CNAME` of its own — GitHub inherits the account-level domain. If the user site (`<owner>.github.io`) has `cname: <domain>`, every project site 301s to `<domain>/<repo>/`. When that domain's DNS is dead the site is unreachable (timeout HTTP 000) though the build is fine. Diagnose the **user site**, not the project:

```bash
gh api repos/<owner>/<owner>.github.io/pages --jq '.cname'   # inherited by all project sites
SHA=$(gh api repos/<owner>/<owner>.github.io/contents/CNAME --jq '.sha')
gh api -X DELETE repos/<owner>/<owner>.github.io/contents/CNAME -f message="remove dead custom domain" -f sha="$SHA"
```

Removing the account CNAME restores every project site to `https://<owner>.github.io/...` — reversible but affects ALL project sites, not just the one in hand. Propagation takes a minute or two: re-check with a cache-buster (append `?...=<epoch>`) before concluding it failed. No project-level `CNAME` edit can stop an account-level inherited redirect.

## Docs that make a public repo adoptable

Ship all of these, in English (the user's conversation stays Spanish; the repo's content is English — `rules/sdd.md`):

**Use English bundle and slash-command names in the export.** The user's conversation is Spanish, but the public system is universal: export `/agency`, `/architecture`, `/implement`, `/init-project`, not `/agencia`, `/arquitectura`, `/implementar`, `/init-proyecto`. A Spanish-named bundle is a non-universal surface that forces a later coordinated rename (see pitfall). Keep **one deliberate bilingual exception**: a natural-language trigger phrase like `"los agentes"` may stay in `hermes-sdd-orchestration` so Spanish requests still route, even though every other string is English. The rename is applied in **two places in lockstep** — the exported repo AND the live `~/.hermes/` install — then verified with `hermes bundles list` (old names gone, new names present).

- `README.md` — system overview, gate, three task levels, install, links, badges (`shields.io`).
- `INSTALL.md` — copy the whole `skills/` tree (`cp -R skills ~/.hermes/`), bundle installs, verification, and the layout note (skills export **flat**).
- `CONTRIBUTING.md` — process-only, English-only, sanitize before PR, task-level contract.
- `CHANGELOG.md` — keep-a-changelog format linked to the release tag.
- `docs/FAQ.md` — the common questions (what it is, feature-vs-bugfix-vs-fix, who blocks, `no code without a validated change`).
- A `docs/example-change/` study change showing the real `proposal.md` / `spec.md` / `tasks.md` shape, built from the system's own `templates/`.
- Mermaid diagrams in the lifecycle + usage docs; keep them `flowchart`-typed and balanced (see pitfall).

## Pitfalls

- **Do not export by directory only** — export the dependency closure of what bundles load. Incomplete = `hermes skills install` of a bundle resolves to nothing on another machine; the failure is silent until a stage runs.
- **Sanitize the copied tree, not only your hand-written docs.** The persona provenance and example absolute paths come from generated files; they will ship unless grep finds them.
- **Verify remote, not just local** — a clean working tree can still serve leaks if the commit predates the fix. Re-verify via the API tree after push.
- **Mermaid without `mmdc` installed:** don't install a browser-based renderer just to validate. Check syntax structurally — every block opens `flowchart`, and `[`/`]`, `{`/`}` balance. GitHub renders Mermaid natively, which is what a repo targets.
- **A 'hit' on grep for your own name/URL is not always a leak** — `LICENSE` copyright and the repo's own URL in docs are intentional. Judge context, don't blind-fail.

- **Renaming a bundle on only one side breaks the live system.** The public repo and the user's daily `~/.hermes/` install are two copies of the same surface; rename a slash-command in *both* in lockstep, then verify with `hermes bundles list` that only the new names remain. The user's working commands change with the rename — calling `/agency` when only `/agencia` is installed is a silent no-op. A language switch to English names must also grep the internal docs/skills (`HOW-TO-INVOKE`, `agents/README`, `hermes-sdd-orchestration` references, `rules/sdd.md`) for the old names, not just the bundles and README.

## References

- `references/sanitization-greps.md` — reusable grep sweeps (local copy + remote tree + persona frontmatter audit).
