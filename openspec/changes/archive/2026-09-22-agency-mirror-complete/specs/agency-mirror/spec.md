## ADDED Requirements

### Requirement: The five missing agency skills are mirrored

The repo MUST mirror the five agency skills that today live only in `~/.hermes` —
`agency-invocation`, `sdd-agency-maintenance`, `release-closure`,
`sdd-agency-export`, `hermes-sdd-packaging` — each with its SKILL.md and its full
`references/` set, under the same category structure as live
(`skills/software-development/` and `skills/autonomous-ai-agents/`).

#### Scenario: Each skill and reference ships

- **WHEN** the repo tree is compared against the live `~/.hermes` skill dirs
- **THEN** the five SKILL.md files and all seven references exist in the repo with
  identical content

### Requirement: The mirror stays public-ready

No mirrored file MAY contain a personal path (`/Users/migue`), a credential, or a
machine-specific absolute path. The one user-behavior rule (vault capturing in
`sdd-agency-maintenance`) is prose about how the user works, not a machine path, and is
allowed.

#### Scenario: Public readiness grep

- **WHEN** the mirrored tree is searched for personal paths and the vault ref
- **THEN** no personal path is found; the vault rule renders as intended
