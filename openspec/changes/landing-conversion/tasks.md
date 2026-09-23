# Tasks — landing conversion

## 1. Draft the copy

- [x] 1.1 Hero written (headline "Your AI developer, with receipts.", subhead, CTA "Install in one command", proof line under CTA) — verifies: `grep -q "with receipts"` index.html
- [x] 1.2 Three pain cards (memory / smoke / mood), each ending with the structural fix — verifies: `grep -q "doesn't remember anything today"` + `grep -q "said it tested it"` + `grep -q "mood"` index.html
- [x] 1.3 Proof section ("This repo is the demo") linking to the repo, no numbers — verifies: `grep -q "github.com/mcabreradev/hermes-sdd-agency"` index.html (link in proof)
- [x] 1.4 Loop as four scenes (say what you want / visible gate / test-first / two people who can say no) — verifies: `grep -q "Two people who can say no"` or scene equivalents, no "initialize-project" string on the landing
- [x] 1.5 Outcomes section (4 plain-language outcomes) — verifies: `grep -q "A dead session isn't a lost week"` index.html
- [x] 1.6 FAQ (4 objections incl. "What's the catch?") — verifies: `grep -q "What's the catch"` index.html
- [x] 1.7 Final CTA repeating install, no second primary action — verifies: exactly one `btn-solid` link? (allow hero + final = 2 identical install CTAs, no others)

## 2. Design

- [x] 2.1 Existing hum theme and one-file structure kept (no build step added) — verifies: `grep -q "data-theme=\"hum\""` index.html, and no new files in the diff beyond index.html + change dir

## 3. Quality

- [x] 3.1 Humanizer run on the copy: no not-X-but-Y, no one-line closers, no forced triads, no AI stock words — verifies: manual read + grep for the strongest tells (`not just`, `that's the real win`, em-dash density in prose)
- [x] 3.2 All links resolve (repo URL is the real one; anchor links exist for their targets) — verifies: `python3` parse of anchors + hrefs

## 4. Close

- [x] 4.1 `openspec validate --all` green — verifies: failed == 0
- [x] 4.2 GitHub Pages serves the new index.html after merge — verifies: `curl https://mcabreradev.github.io/hermes-sdd-agency/ | grep "with receipts"`
