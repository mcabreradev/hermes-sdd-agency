# Tasks — docs sync after phase 3 (docs-only, skip_specs)

## 1. README

- [x] 1.1 Badges: 5 bins → 7, 60 skills → 65; Contents: evidence chain (5) → (7); TL;DR evidence row — verifies: `grep -c "bins" README.md` == expected, `grep -q "65 skills" README.md`
- [x] 1.2 Layout: "the 5 evidence bins" → 7; add the two new bins to the bin list — verifies: `grep -q "change-collision" README.md`
- [x] 1.3 Skill catalog counts: "60 skills · 23 personas + 37 process" → "65 · 23 + 42"; process count row — verifies: `grep -q "23 personas + 42 process" README.md`
- [x] 1.4 Fixture table: add change-collision + run-trace rows (7 suites) — verifies: `grep -q "run-trace" README.md`

## 2. Evidence bins doc

- [x] 2.1 Title "five bins" → "seven"; chain callout → 7 — verifies: `grep -q "seven" docs/evidence-bins.md`
- [x] 2.2 Add section 6 `run-trace` (one-liner, when it runs, sample) — verifies: `grep -q "run-trace" docs/evidence-bins.md`
- [x] 2.3 Add section 7 `change-collision` — verifies: `grep -q "change-collision" docs/evidence-bins.md`
- [x] 2.4 Update "chain in a real run" list to mention trace — verifies: `grep -q "trace" docs/evidence-bins.md`

## 3. Web (index.html)

- [x] 3.1 Stats strip: 92→108 cases, 60→65 skills, 5→7 bins, PR count → 39 — verifies: `grep -q "108" index.html`
- [x] 3.2 Hero loop: reorder release before pr-review (canonical) — verifies: `grep -n "pr-review" index.html | head -1` after release
- [x] 3.3 Advanced/evidence copy: add run-trace/change-collision mentions as needed — verifies: `grep -q "run-trace" index.html || grep -q "change-collision" index.html`

## 4. INSTALL

- [x] 4.1 Badge + TL;DR: 60 → 65 skills; "5 bins" → 7 — verifies: `grep -q "65" INSTALL.md && grep -q "7" INSTALL.md`

## 5. Close

- [x] 5.1 CHANGELOG bullet (English) — verifies: `grep -q "homepage" CHANGELOG.md || grep -q "evidence bins" CHANGELOG.md`
- [x] 5.2 `openspec validate --all` green — verifies: failed == 0
