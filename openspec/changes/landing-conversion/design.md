## Why

The homepage is a feature sheet. It leads with numbers (bins, skills, PR counts) and
process mechanics ("evidence chain", "review-tier", "blocker classes") — vocabulary the
repo's own builder understands, but a developer landing on the page has no reason to
decode. The pitch never lands: a visitor does not learn what it does, what it feels
like to use, or what happens to their own workflow with it installed. A page that
cannot answer "what is this for ME?" in one glance fails its only job: making someone
install it.

This change rebuilds `index.html` as a **conversion landing**: one idea per screen,
the reader's own failures named first, the loop shown as scenes instead of stages,
a working proof (the repo maintains itself) instead of badges, and one action to take.

## Non-goals

- Keeping every fact the current page states (counts, catalog, deep mechanics) — that
  material lives in `README.md` and `docs/`; the landing links to them.
- A multi-page site, a framework, or a build step. Still one static `index.html`
  served by GitHub Pages from `main`.
- Changing the install command, the repo layout, or any rule.

## The copy, section by section

The page follows the **Human Action Model** (current discomfort → better vision →
path to action) and answers three questions in order: *what is it*, *does it work for
me*, *is it real*.

### 1. Hero — the one-line promise

Headline: **"Your AI developer, with receipts."** — names the audience (anyone who
delegates real work to an AI agent) and the transformation (every claim backed by
something you can re-run), in six words.

Subheadline (specific, no jargon): "Agents write great code and terrible stories. This
is the workflow that makes them show their work — specs before code, proof after every
step, and a review you can actually trust."

CTA (primary): **Install in one command** → scrolls to the install section. "One
command" is the strongest concrete claim the repo has (vs. "Get Started" which commits
to nothing).

Proof line under CTA: "Maintained by the process it ships — every feature here went
through its own loop."

### 2. The pain — three cards, the reader's own failures

No product speak. Three sentences a developer has thought or said:

1. **"It wrote that yesterday. It doesn't remember anything today."** — context
   amnesia, named as the reader's experience.
2. **"It said it tested it. I can't tell, and I'm about to trust it in prod."** — smoke
   reports.
3. **"The review depth depends on the agent's mood more than the change."** — depth by
   mood (a real fix this repo made: review depth derived from the diff).

Each card closes with the structural fix in one line: state lives in files; evidence is
re-run, not recounted; review depth comes from the diff, not the mood.

### 3. Proof — "This repo is the demo"

A scene the reader can verify right now, instead of a claim: the repo's own
`CHANGELOG.md` + `git log` show features shipped through this loop; the homepage links
to the repo where the reader can see it. One line: "Everything in this repository —
including this page — went through the loop you're about to read."

### 4. The loop — scenes, not stages

The current "initialize-project → discovery → …" table becomes a visual story in four
panel scenes, each a moment the reader can imagine living:

1. **You say what you want.** — one sentence to Hermes; an agent turns it into a spec
   with scenarios.
2. **A gate you can see.** — no code enters until a validated change exists; the check
   commands are shown.
3. **The builder writes the code — test-first.** — code is the cheapest part; the
   review is where the value is.
4. **Two people who can say no.** — reviewer and QA independently verify against real
   behavior; only they can block. Nothing advances on a self-report.

Each scene keeps one concrete artifact name (spec, gate, test-first, reviewer/QA) with
zero surrounding jargon.

### 5. What changes — four outcomes, plain language

1. "A dead session isn't a lost week." — state resumes from files, not memory.
2. "No more reviewing smoke." — every claim binds to the tree it validated; a tree that
   moved bounces the evidence.
3. "'Done' has a definition." — review approved + QA passed = done; nothing less.
4. "You can sleep during /do." — the autonomous run ends in a PR for the morning review,
   with its assumptions flagged.

### 6. The FAQ — the four real objections

1. "Is this another framework to learn?" — no: one command installs it; you type plain
   words to Hermes.
2. "Does it force ceremony on small fixes?" — three task levels; a typo skips the whole
   loop.
3. "Do my agents have to change?" — no: the personas come with the install.
4. "What's the catch?" — the honest cost: it needs OpenSpec ≥ 1.13 and a will to read
   the receipts. (Honesty as a conversion device; this repo's whole credibility rests on
   never hand-waving.)

### 7. Final CTA — the loop closes

"One command installs the whole agency. Your next feature can go through it tonight."
Same primary CTA, repeated.

## Design rules

- Keep the existing theme (hum: warm dark, mint) and one-file static structure.
- Above the fold: headline, subhead, CTA, and the first proof (no scrolling to know
  what it is).
- Each section one idea; no section longer than its idea needs.
- All copy passes the humanizer run (no "not X but Y", no one-line closers, no forced
  triads, no AI stock words).
