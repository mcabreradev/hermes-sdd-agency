# sensitive-paths Specification

## Purpose
The explicit deny list of paths that are sensitive by nature — credentials, keys, tokens —
which no agency agent, bin or workflow may read, print, copy into a report or commit, and the
evidence-based way that prohibition is enforced at review time.

## Requirements

### Requirement: Sensitive-path deny list

The agency MUST define an explicit list of sensitive path classes in
`rules/project-boundaries.md` that no agent, bin or workflow may read, print, paste into a
report, or commit. The list MUST cover, at least: SSH material (`~/.ssh/*`), private keys and
certificates (`**/*.pem`, `**/*.key`, `**/*.p12`, `**/*.pfx`), environment and secret files
(`**/.env*`, `**/secrets/*`), cloud and tool credentials (`~/.aws/credentials`,
`~/.credentials/*`, `~/.config/gh/hosts.yml`) and the macOS keychain
(`~/Library/Keychains/*`). The list MUST be stated as literal path patterns so it can be
matched mechanically.

#### Scenario: An agent encounters a deny-listed path

- **WHEN** any agent is asked to read, print, diff, copy or report the content of a path
  matching the deny list
- **THEN** it refuses the content, names the path it refused in its report, and continues with
  the rest of its brief — a deny-listed path never appears in a report, a commit or a trace

#### Scenario: The list is available without inference

- **WHEN** an agent or workflow needs to know whether a path is sensitive
- **THEN** it reads the enumerated patterns in `rules/project-boundaries.md` instead of
  exercising judgment, and no agent may add to or narrow the list on its own initiative

### Requirement: Deny-list enforcement on evidence

The prohibition MUST be enforced on what was actually touched, not on the author's intent:
the `reviewer` stage MUST grep the paths of the declared diff against the deny list and report
any hit as a `BLOCKER` per `rules/quality.md`. A diff that touches a deny-listed path is not
reviewable as clean regardless of the file's apparent content.

#### Scenario: The reviewer finds a deny-listed path in the diff

- **WHEN** the `reviewer` greps the declared diff's paths against the deny list and a path
  matches
- **THEN** it reports the match as a `BLOCKER` with the `path:line` of the offending
  declaration, and the stage does not advance

#### Scenario: The reviewer finds no match

- **WHEN** the grep over the declared diff's paths returns no match
- **THEN** the reviewer records the grep command and its empty result as the evidence line for
  this check, and the stage proceeds
