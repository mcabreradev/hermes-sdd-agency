## 1. The declared homes

- [x] 1.1 The convention is stated where the producers are: `workflows/initialize-project.md` declares `docs/PRD.md` as the PRD's home and a step that creates or scaffolds it — verifies: `grep -q 'docs/PRD.md' workflows/initialize-project.md && grep -q 'PRD' workflows/initialize-project.md`
- [x] 1.2 `agents/architect.md` owns `docs/ARCHITECTURE.md` as the durable architecture overview (distinct from the change's `design.md` and from an ADR) — verifies: `grep -q 'docs/ARCHITECTURE.md' agents/architect.md`
- [x] 1.3 `rules/project-boundaries.md` states the product-document boundary: the PRD derives from `openspec/project.md` and the agency ships no product content — verifies: `grep -qi 'docs/PRD.md' rules/project-boundaries.md || grep -qi 'product document' rules/project-boundaries.md`

## 2. The check that catches the improvisation

- [x] 2.1 `agents/reviewer.md` carries a checklist item: a product document at a path other than its declared home — in particular a root-level `PRD.md` / `ARCHITECTURE.md` — is `MINOR`, naming the declared home — verifies: `grep -q 'root-level' agents/reviewer.md && grep -qi 'docs/PRD.md' agents/reviewer.md`
- [x] 2.2 `rules/quality.md` "Definition of Done" carries the boundary for the `reviewer` row (the declared homes) — verifies: `grep -q 'docs/PRD.md' rules/quality.md || grep -q 'docs/ARCHITECTURE.md' rules/quality.md`
- [x] 2.3 The check is a review item, not a deny-list entry: the sensitive-path deny list gains no product-doc path (the added rule mentions the homes, but the deny-list section does not) — verifies: `! sed -n '/## Sensitive paths/,/^## /p' rules/project-boundaries.md | grep -qE 'PRD|ARCHITECTURE'`

## 3. The agency ships no product content

- [x] 3.1 No product document exists in this repository: no `docs/PRD.md` and no `docs/ARCHITECTURE.md` — verifies: `test ! -f docs/PRD.md && test ! -f docs/ARCHITECTURE.md`
- [x] 3.2 README and INSTALL reflect the change where they already list the project structure — verifies: `grep -qi 'PRD' README.md`

## 4. The change closes cleanly

- [x] 4.1 The OpenSpec change validates with no ERROR — verifies: `openspec validate project-docs-convention --type change --json | jq -r '.summary.totals.failed'`
- [x] 4.2 The change validates against the specs without breaking them — verifies: `openspec validate --specs --json | jq -r '.summary.totals.failed'`
- [x] 4.3 A CHANGELOG entry records the convention under `[Unreleased]` — verifies: `grep -qi 'project-docs\|docs/PRD.md' CHANGELOG.md`
- [ ] 4.4 The change archives cleanly (left unticked on the branch by convention; the archive is a separate follow-up PR) — verifies: `openspec validate project-docs-convention --type change --json | jq -r '[.items[].issues[]?.message] | map(select(test("Archive would refuse"))) | length'`
