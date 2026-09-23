# Sanitization greps

Reusable patterns to sweep a copied `~/.hermes` process tree before publishing. Run after copying, then again against the remote tree.

## One-shot coverage sweep (local working copy)

```bash
cd <export>/<repo>
grep -rniE '/Users/[a-z]|/home/[a-z]|mcabrera|Miguelangel|Workspace/migue|gho_|ghp_|github_pat|mcabrera\.dev|api_key|secret|password|token[=:]' \
  --include='*.md' --include='*.yaml' . 2>/dev/null | head
```
A hit needs a look: skip the *intentional* ones (`LICENSE` copyright, the repo's own URL in `INSTALL.md`/`CHANGELOG.md`).

## Token-only sweep (the dangerous subset)

```bash
grep -rniE 'gho_|ghp_|github_pat|[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}' \
  --include='*.md' --include='*.yaml' . 2>/dev/null
```

## Remote-tree verify (post-push, the real gate)

```bash
gh api repos/<owner>/<repo>/git/trees/main?recursive=1 --jq '.tree[].path' | \
  grep -Eic 'migue|mcabrera|\.env'      # expect 0
```
`0` is clean. Anything else is a leak that a fresh clone would serve.

## Persona/process-skill frontmatter audit

```bash
cd <export>/<repo>/skills/agents; for d in */; do d="${d%/}"; f="$d/SKILL.md";
head -30 "$f" | awk -v name="$d" 'NR==1{first=$0} /^description:/{print name" :: "NR": "$0; found=1} END{ if(!found) print name" :: NO-description (first="first")" }'; done
```
Watch for: no frontmatter at all, block-scalar `description: |`, or a `description` that describes the agent itself (`"You need ..."`) instead of an action it performs — the audit catches these where a plain existence check won't.
