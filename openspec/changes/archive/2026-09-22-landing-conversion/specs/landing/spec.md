## ADDED Requirements

### Requirement: The hero answers "what is it" in one glance

The first viewport MUST state, in plain language: what the product is (an agency-style
workflow for AI coding agents), the one-line promise, and a single primary call to
action (install). No product vocabulary (bins, tiers, gates) above the fold.

#### Scenario: A developer who has never heard of the project

- **WHEN** they open the page and read the first screen
- **THEN** they can restate what it is, what it does for them, and what to do next,
  without opening another page

### Requirement: The pain is the reader's own, named before the product

The page MUST open with the reader's failures (memory loss between sessions,
unverifiable claims, review depth that varies) before describing the product, and each
failure MUST close with the structural fix.

#### Scenario: The three failures appear before the features

- **WHEN** the page is read from top to bottom
- **THEN** the three pain cards appear before any section describing the loop or the
  install

### Requirement: The proof is verifiable, not claimed

The page MUST show a proof the reader can check right now (the repo maintains itself
through the same loop) instead of unverifiable product claims, and MUST link to the
repository.

#### Scenario: Proof is linked to the repo

- **WHEN** the reader follows the proof section's link
- **THEN** they land in the repository where the loop's own history is visible

### Requirement: The loop explains itself in four scenes

The loop MUST be presented as four plain-language scenes (say what you want → a visible
gate → code written test-first → two independent people who can say no), with concrete
artifact names but no surrounding jargon, and MUST fit one screen.

#### Scenario: A non-expert can retell the loop

- **WHEN** they read the loop section
- **THEN** they can retell it in their own words as a sequence of moments, not as a list
  of stage names

### Requirement: The final CTA is unambiguous

The page MUST end by repeating the same single action (install in one command) with a
short value recap, and MUST NOT introduce a second primary action.

#### Scenario: One action, twice

- **WHEN** the page is read end to end
- **THEN** every call to action resolves to the same install action, and no competing
  primary action appears
