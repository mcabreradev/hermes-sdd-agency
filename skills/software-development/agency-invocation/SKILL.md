---
name: agency-invocation
description: "Invoke the SDD agency: /agency and per-stage bundles."
---

# Agency invocation (cheat sheet)

How the Hermes SDD agency is used. Full detail: `~/.hermes/HOW-TO-INVOKE-THE-AGENCY.md`.

## Slash commands

- `/agency` — general orchestrator; asks for the stage if you did not name one.
- Per stage: `/init-project` · `/idea` · `/architecture` · `/plan` · `/implement` ·
  `/review` · `/qa` · `/release`

All of them are skill bundles in `~/.hermes/skill-bundles/`; each loads
`hermes-sdd-orchestration` + `openspec-sdd` and injects the stage protocol.
`hermes bundles list` to see them · `hermes bundles show <n>` to see what each loads.

## Without slash commands

The `hermes-sdd-orchestration` skill autoloads on: "the agency", "los agentes",
"run the SDD loop", "initialize the project", "the workflow".

## Before you start

```bash
cd <project-root> && pwd -P && openspec context --json
test -f openspec/project.md || echo "MISSING → /init-project"
```

Ambiguous root ⇒ the agency stops and reports. It never proceeds with the "most likely" one.

## Hard rules

1. No implementation code without a validated OpenSpec change.
2. OpenSpec lives in the project repo, never in `~/.hermes/`.
3. Agents never talk to each other; Hermes validates every output in the real repo.
4. Only review and QA can block.
5. Business/architecture/security/scope ambiguity ⇒ the human decides.
6. Every closure carries a final report, even a blocked one.

## Output language (verify before sending)

The agency's files, agents, workflows, rules, templates and specs are all in **English**.
Every reply **to the user** is in **Spanish** — including one-line acknowledgements and
closing summaries after an English-only task.

This has failed in practice: a full Spanish verification report (translation of 33 files)
came back written in **Chinese**, while the underlying tool output was correct. The language
of the work and the language of the answer are independent decisions — a task conducted in
English does not license answering in English, and never in a third language.

Before sending a reply, check the prose itself — tool output, code blocks, paths, slugs and
commands stay in English by design and do not count. If a reply goes out in the wrong
language, say so plainly in the next turn (the sent message cannot be recalled) and restate
the content in Spanish.
