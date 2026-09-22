## 1. Detector

- [x] 1.1 Replace the `is_block_scalar` decision in `bin/skill-registry` with a content-aware one: an indicator (`|` / `>-` / `|2-` / …) immediately followed by indented text is legal and yields the folded text as the description; an indicator followed by the next key (or EOF) is `BLOCK-SCALAR`. Verifies: `bin/skill-registry --root fixtures/skill-registry/roots/valid` reports the folded fixture as `FLAG: ok` with its description; the defective root reports `BLOCK-SCALAR`
- [x] 1.2 Rewrite `fixtures/skill-registry/roots/defective/fixture-block-scalar/SKILL.md` to the real defect shape: `description: |` followed immediately by the next frontmatter key (no body), and add `fixture-block-trailing-comment` (`>- # …`, also body-less). Verifies: the suite's defective cases assert `BLOCK-SCALAR` against both
- [x] 1.3 Add `fixtures/skill-registry/roots/valid/fixture-folded-legal/SKILL.md` — the exact shape that was wrongly flagged (a `>-` with a real body, like `context-architecture`). Verifies: the suite's valid case asserts `FLAG: ok` and the first body line plus `…` as the description preview

## 2. Suite

- [x] 2.1 Add `fixtures/skill-registry/check.sh`: runs `bin/skill-registry --root` over both fixture roots, and asserts each fixture's expected flag (and description for the folded one). Verifies: `bash fixtures/skill-registry/check.sh` exits 0 with `failures=0`, naming each fixture
- [x] 2.2 The suite fails loudly when it cannot run (missing bin or root). Verifies: with the bin path broken the suite exits non-zero with a reason — never `failures=0` + exit 0

## 3. Closure

- [x] 3.1 `openspec validate "skill-registry-followup" --type change --json` with `failed == 0`. Verifies: the command's JSON totals quoted
- [x] 3.2 `bash -n` on the bin and the new suite; `bin/no-smoke-worktree` still exits 0; and the REAL tree no longer flags `context-architecture` when run against `~/.hermes/skills`. Verifies: `bin/skill-registry --root ~/.hermes/skills 2>/dev/null | grep -c "context-architecture" ; grep -A1 FLAG` reports the skill WITHOUT `BLOCK-SCALAR`
- [x] 3.3 Tick every task against its own verification, then archive + sync as the follow-up PR (same standing rule as the previous chain). Verifies: `openspec instructions apply --change "skill-registry-followup" --json` with `remaining == 0` after archiving
