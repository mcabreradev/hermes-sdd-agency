# Contributing to Hermes SDD Agency

Thanks for helping make the SDD agency better. This is a public, process-only
repository: it ships reusable rules, workflows, agents, templates, bundles and
personas. It contains no project's requirements.

## Ground rules

- **Process only.** Do not add anything project-specific, client-specific or tied to
  any one machine here. That belongs in a project's own `openspec/`
  (`rules/project-boundaries.md`).
- **English only.** Everything — code, docs, specs, commits, PRs — is in English. The
  only exception is a user conversation in Hermes, which is not part of this repo.
- **Match the existing structure.** Rules go in `rules/`, workflows in `workflows/`,
  roles in `agents/`, templates in `templates/`, bundles in `skill-bundles/`, personas
  and process skills in `skills/`.
- **Changes to rules are high-stakes.** A rule that changes here applies to every
  Hermes session that installs the agency. Propose the change, explain the *why* (the
  bug or gap it fixes), and keep it minimal.

## How to propose a change

1. Open an **issue** first for anything that changes behavior of the loop: a rule
   change, a workflow rework, a new stage. Describe the problem with evidence, not
   just an opinion.
2. For mechanical changes (a typo in a doc, a missing link, a bundle description) an
   issue is optional — a PR is fine.
3. Write it in **English**. One concern per PR, no unrelated edits bundled in.

## The task-level contract

A change to the agency itself is judged against the same three levels the agency
enforces on projects (`rules/openspec.md` "Task size and fast path"):

- **Cosmetic** (typo, link, wording) → direct edit, no change needed.
- **Minimal** (bounded doc fix, a template field) → PR is enough.
- **Feature** (new rule, new workflow, changed envelope) → open an issue, propose the
  design, get a second read, then PR.

## Before opening a PR

- Sanitize: **no absolute local paths** (`/Users/...`, `~/some/machine/path`), no real
  usernames, no machine-specific state. Use `<project-root>` placeholders.
- Verify: if you touch a skill, check its frontmatter stays valid (`---` closed, one-line
  `description`). If you touch a rule, confirm it still cross-references consistently.
- If you add a **mermaid diagram**, keep it `flowchart`-typed and balanced; GitHub
  renders it natively.

## Branching and PRs

- Work on a feature branch (e.g. `fix/docs-typo`), open a PR into `main`.
- Keep the diff bounded: touch only the files your change needs.
- Reference any issue in the PR body.

## Code of conduct

Be straightforward, kind and evidence-based. Assume good intent; say plainly when
something is wrong. No filler.

## License

By contributing you agree your contributions are licensed under the MIT License —
see `LICENSE`.
