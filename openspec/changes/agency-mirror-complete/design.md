# Design — agency-skill-mirror

## Context

The public repo mirrors the protocol skills (`hermes-sdd-orchestration`, `openspec-sdd`)
and the personas (`skills/agents/*`). Five process skills that complete the system live
only in `~/.hermes`. This change brings them into the mirror.

## Goals / Non-Goals

**Goals:**
- Mirror the five missing skills, each with its references, same categories as live.
- Keep the mirror public-ready: no personal paths, no credentials.
- After merge, sync back to `~/.hermes` is a no-op by construction (the repo copy is
  byte-identical to live; the copy direction has nothing new to add).

**Non-Goals:**
- Restructuring any skill content (they are mirrored as-is, no edits).
- Touching the protocol skills or the personas.
- Sanitizing legacy mirrored content beyond the public-readiness grep on the five new
  dirs.

## Decisions

### Decision: Mirror as-is, one-way from live

Byte-identical copy per file. No edits, no rewrites: these are living process skills a
`delegate_task` may load from `~/.hermes`; drifting content would make the repo mirror
teach a different process than the machine runs (the exact failure the previous change
fixed).

### Decision: Categories follow live

`agency-invocation`, `sdd-agency-maintenance`, `release-closure`, `sdd-agency-export`
land under `skills/software-development/`; `hermes-sdd-packaging` under
`skills/autonomous-ai-agents/` (the repo gains that category dir).

### Decision: Public-readiness grep is part of the gate

Each mirrored SKILL.md and reference must be free of `/Users/migue`, `/Users/migue/` and
credential-looking content. The vault-capture rule in `sdd-agency-maintenance` is user
behavior prose (how the user wants lessons recorded), not a machine path — allowed, and
pinned by the second scenario.

## Risks / Trade-offs

- **Risk:** a future live edit to one of the five skills desyncs the mirror.
  **Mitigation:** the same repo←live one-way copy pattern used for the protocol skills;
  a follow-up sync change is the fix.
- **Risk:** `hermes-sdd-packaging` gains a category dir (`autonomous-ai-agents`) that did
  not exist in the repo. **Accepted:** it mirrors the live structure; the spec pins the
  category.
- **Trade-off accepted:** the five skills carry the user's standing rules (PRs open,
  changelogs short, Spanish-conversation contract). That is the *point*: the mirror
  documents how the agency is actually run for anyone adopting it, and the rules are the
  product.

## Delivery strategy

Measured after implementation: **1865 authored lines** (`git diff --numstat main...HEAD`),
well over the advisory ~400 (the `sdd-agency-maintenance` skill alone is 687 lines).
Strategy: **`single-pr`** — it is a 1:1 byte-identical copy of 12 files from live,
verified by `diff -r` (readable in one pass as a copy), not 1865 lines of novel
reasoning. There are no independent slices; an export that omits one skill produces a
less-complete repo than the packaging skill itself describes.
