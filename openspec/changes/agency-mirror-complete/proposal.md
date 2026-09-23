## Why

The public repo mirrors `hermes-sdd-orchestration` and `openspec-sdd` — the two
protocol-level skills — and `skills/agents/sdd-spec-writer` — but five agency skills
that complete the process system still live only in `~/.hermes`: `agency-invocation`
(the `/agency` and per-stage bundles cheat sheet), `sdd-agency-maintenance` (the
sysadmin layer: extending, auditing, keeping the levels consistent), `release-closure`
(the merge/cleanup tail of the loop), `sdd-agency-export` (how the mirror itself is
built and sanitized), and `hermes-sdd-packaging` (the portable packaging set).

`sdd-agency-export` literally documents the export procedure this repo is built from;
its own subject lives outside the mirror, which is a completeness gap: a reader who
follows `sdd-agency-export` to mirror a working agency onto a fork gets a repo that
lacks the packaging skill that describes what "complete" means (`hermes-sdd-packaging`
references the same set as `sdd-agency-export` but with the portability framing).

All five are public-ready process content: verified free of personal paths and
credentials (the only personal reference is the vault-capture rule in
`sdd-agency-maintenance`, which is user behavior, not a secret). Each carries a
`references/` set that must ship with it.
