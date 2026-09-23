---
name: hermes-sdd-packaging
category: autonomous-ai-agents
description: "Use when exporting the Hermes SDD agency to a repo."
---

# Packaging the Hermes SDD agency

Exporting/re-packaging the SDD process system (`~/.hermes/{agents,workflows,rules,templates,docs}`, `skill-bundles/`, and the skills behind it) for portability, adoption, or a public GitHub repo.

## The complete set to ship (omitting any breaks resolution)

The process tree alone is NOT a working agency. Everything below must ship or the target resolves less than the bundles promise:

1. **Process tree**: `~/.hermes/{agents,workflows,rules,templates,docs}` → copy as-is.
2. **Skill bundles**: `~/.hermes/skill-bundles/*.yaml` (the slash commands `/agency /feature /bugfix /fix` + per-stage).
3. **Personas**: `~/.hermes/skills/agents/` (per-role expertise).
4. **Orchestration skills the bundles LOAD**: `hermes-sdd-orchestration` and `openspec-sdd`, under `~/.hermes/skills/software-development/`. Without these a `hermes skills install` of a bundle resolves nothing.
5. **Per-role process skills** the orchestration skill references: requirements-clarity, architecture-decision-records, writing-plans, executing-plans, code-review-checklist, qa-test-planner, e2e-testing-patterns, commit-smart, verification-before-completion, dispatching-parallel-agents, context-architecture — each copied with its `references/`, `scripts/`, `resources/` subdirs.
6. **The `openspec-*` CLI skills**, from `~/.hermes/openspec-global/.hermes/skills/` — `openspec-sdd` dispatches by phase (`/openspec-explore`, `/openspec-propose`, `/openspec-new-change`, `/openspec-apply-change`, `/openspec-archive-change`, `-sync-specs`, etc.). Without them the OpenSpec CLI mechanics do not resolve.

> Pitfall: exporting only the process tree + personas looks complete, but the bundles and `openspec-sdd` silently cannot resolve their skills. `openspec-sdd`/`hermes-sdd-orchestration` list their per-phase and per-role dependencies in their SKILL.md body — grep those references and include every named skill before cutting the set.

### How bundles register (verified)

A bundle is registered on a target simply by **placing its `.yaml` in `<home>/skill-bundles/`** — `hermes bundles list` reads that directory directly; it is not indexed anywhere else. Do NOT have installers call `hermes skills install <path-to-yaml>` per bundle: that subcommand only accepts catalog IDs or remote URLs, so a local path is reported as "Could not download" (but the yaml still lands in `skill-bundles/`, which is why it can appear to work). The correct install is `cp`-ing the bundle `.yaml` files into `skill-bundles/`, nothing more — a single-step copy for all bundles. State this in INSTALL.md so targets don't reproduce the `hermes skills install <path>` failure.

## Sanitization before a PUBLIC push (mandatory)

Skills and rules copied from `~/.hermes/` carry tool-generated and real identifiers. Grep the whole staged tree and replace before publishing:

- `/Users/<user>/...` and `~/.claude/agents/<slug>.md` source paths (injected by `hermes-add-agent` in every persona's SKILL.md) → keep the path but make it portable: `~/.claude/agents/<slug>.md`.
- Real workspace paths that appear as examples in rules (e.g. in `rules/project-boundaries.md`) → `<project-root>/...`.
- The user's real first name can appear in `rules/sdd.md` and process prose → anonymize. Expect the repo's own URL in INSTALL and the LICENSE copyright to be intentional hits, not leaks.
- Tokens/emails: grep for `gho_`, `ghp_`, `github_pat`, `@[a-z]`.

> Pitfall: re-copying a directory AFTER sanitizing can reintroduce the real paths (a later `cp -R` pulls the unsanitized origin). Re-run the sensitive grep against the staged set before every commit, not just once at the start.

### Naming a new bundle command

Before naming a new slash-command bundle, check the native Hermes slash-command registry (`references/slash-commands.md` under the hermes-agent skill — `/resume [name]` already resumes a session) so your agency command does not shadow or clash with the shell's. Pick a name that is both semantically apt and free; renaming post-merge touches the bundle, its workflow, every doc and the installer, and a rename must go through the same worktree+PR path as the original feature. A name collision is a design-time catch, not a runtime one.

### Bundles can depend on skills the repo does not ship

A bundle's `skills:` list is only resolvable on a target if every entry lives somewhere the target can load. When re-syncing a bundle, inventory each skill against concrete source trees before committing: (a) shipped by this repo, (b) installed by a documented plugin, or (c) from a documented third-party repo. Do not assume a plugin carries a skill just because the bundle names it — verify against the actual plugin dir and the referenced repo (the github contents API works when the tree page 404s; `npx skills@latest add <owner/repo> --list -a hermes-agent` lists what a repo exposes WITHOUT installing). Resolve (b)/(c) by **documenting the one-command install** in INSTALL.md, never by forking the third-party skill into this repo — check for a one-command installer (`npx skills@latest add <owner/repo>`, `hermes plugins install <owner/repo> --enable`) BEFORE deciding to fork. The repo ships "process + what it resolves"; it does not fork third-party skills. When `/feature`-style bundles load external skills, the installer should **warn (never install)** when those skills are absent, printing the exact commands to run — it must not reach into npx/plugin installers itself, or the single-command agency installer becomes fragile and conflates concerns.

Public docs carry a language contract: everything in the repo (INSTALL.md, README, bundle instructions) stays in English even when the user speaks Spanish — only the conversation with the user is Spanish. A translated doc block is a slip that gets committed with the bundle.

When adding an autonomous path to the agency, follow the pattern in
`references/autonomous-mode.md` (relax the human-approval rules via a declared
decision table, never by rewriting the standing rules; terminal = PR awaiting
human review).

## Repo layout

The exported `skills/` ends up **flattened** even though the source `~/.hermes/skills/` is categorized (`software-development/…`, `agents/…`). Internal file references (`references/…`) and `cp -R` install still work, but document the layout in the repo's INSTALL.md so the target knows where each piece lands. Replicating the source hierarchy is ideal but not blocking.

## Re-sync maintenance

Each exported directory is a copy of `~/.hermes/...`. When a rule changes or a bundle/skill is added locally, re-copy that directory into the repo and commit — otherwise the public export drifts from the working system. State this in INSTALL.md.

## Verify before declaring done

- Every bundle YAML parses: `yaml.safe_load` over each `skill-bundles/*.yaml`.
- The target can list the new commands (`hermes bundles list | grep` on a live install, or the gh repo tree on a published one).
- If the repo ships an `install.sh`, validate syntax (`bash -n`) and dry-run it to a temp target; confirm it writes nothing and exits 0. Pitfall: the exit code of a `trap ... EXIT` handler becomes the script's exit code, and a `set -e` script silently returns the last command's status — a cleanup like `[[ -n "$TMP_DIR" ]] && rm -rf "$TMP_DIR"` with `$TMP_DIR` empty returns 1 and turns a successful install into `exit 1` with no error printed. End the cleanup with `return 0`, and test `echo "$?"` after the run, not a pipeline (`cmd | tail` returns tail's status). Also: guard overwrites — a fresh target installs cleanly, an existing home asks (or aborts without a TTY unless `-y/--yes`) before merging.
- The `index.html` landing carries its OWN `:root` variables (`--text`, `--surface`, oklch palette) and is served standalone via GitHub Pages — it must NOT rely on the CSS vars the Hermes desktop shell injects (`--foreground`, `--card`). When styling a new block there, use the page's own `:root` vars; a `var(--foreground)`/`var(--card,#<hex>)` silently falls back and drops out of the palette when the page is opened outside the shell. Render the page live in the desktop preview pane to confirm the block before merging.
- The landing's responsive nav is an a11y trap if built as a no-JS `<label>+<input type=checkbox>` toggle: `display:none` on the input leaves no focusable trigger (keyboard-inoperable) and hides state from assistive tech. Make it a semantic `<button aria-expanded aria-controls>` toggling an `.open` class via JS (sync `aria-expanded` on toggle and on close-on-link-tap), keep a `prefers-reduced-motion` rule that disables the panel transition, and give the open burger an X shape so the state is visible. A `max-height` collapse with `overflow:hidden` clips the panel's box-shadow — split the panel into an outer wrapper (border/shadow, not clipped) and an inner collapsible.
- When you create/edit a PR body, write it with `--body-file <heredoc>` and AFTERWARD verify the content yourself (`gh pr view <n> --json body -q .body | grep -cE '^- \*\*'`). A body passed through a shell pipeline + `sed` with parentheses/escapes can silently drop lines and leave a corrupted body — treat a just-written PR body as a self-report until read back.
- Reverting a single follow-up commit from an OPEN, unmerged PR (not merged history): `git reset --hard <parent>` makes it no longer HEAD (working tree was clean, so nothing is lost), then `git push --force-with-lease` moves the remote branch and the PR re-computes. After the reset, verify by grepping for the SPECIFIC markers the commit added AND confirming the shared/base ones you must keep are still present — a generic "grep should now be 0" overcounts the base you must not delete (e.g. removing `use.card`/`panel-card` while keeping `use.adv`/`adv-head`). Then remove the matching follow-up section from the PR body with a script (find + slice in Python); a shell `sed` with parens/escapes can break the command. Re-check the body after. Only valid for `agent/*` unmerged branches.
- "Borra este cambio" / "revert" is ambiguous: it may mean one follow-up commit on the current branch, the whole unmerged PR, or the merged history of main. Confirm scope (and that the offending work is unmerged) before a destructive `reset --hard`/`force-with-lease` — the branch must still merge cleanly afterward.
- `git status` clean; sanitize grep returns only intentional hits (LICENSE, own repo URL).
- For a published repo, confirm via `gh repo view` (visibility, branch, url) and a tree listing that the staged file count matches the source.
- Re-verify no sensitive data landed in the REMOTE tree, not just locally.

## Excluded on purpose

Generic personal skills in `~/.hermes/skills/` (obsidian, email, media…) are not part of the agency and should not ship unless the task explicitly wants everything. The export is "process + what the agency resolves", nothing else.
