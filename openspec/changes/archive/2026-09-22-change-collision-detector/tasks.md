## 1. Bin

- [x] 1.1 `bin/change-collision` (bash 3.2 + `jq`, read-only): given `--base <ref> --a <refA> --b <refB>`, prints `parallelizable` / `collision` (with paths and families) / `cannot assess` (with reason, exit 2) — verifies: fixture suite green
- [x] 1.2 High-risk families force collision without literal overlap (schema/migrations, openspec/, contracts/auth, dependency manifests) — verifies: a schema-prisma vs migrations fixture yields `collision`

## 2. Rule

- [x] 2.1 `rules/orchestration.md` parallelization section: Hermes runs `bin/change-collision` before dispatching two changes concurrently; a `collision` verdict means sequential, `cannot assess` means no parallel until measured — verifies: `grep -q "change-collision" rules/orchestration.md`

## 3. Fixture

- [x] 3.1 `fixtures/change-collision/check.sh` builds two throwaway repos per case and asserts disjoint→parallelizable, shared-path→collision, schema-vs-migration→collision (family), empty-diff→cannot-assess — verifies: `bash fixtures/change-collision/check.sh` exit 0

## 4. Close

- [x] 4.1 `docs/sdd-feature-lifecycle.md` mentions the bin in the parallelization note — verifies: `grep -q "change-collision" docs/sdd-feature-lifecycle.md`
- [x] 4.2 `openspec validate --all` green — verifies: failed == 0
