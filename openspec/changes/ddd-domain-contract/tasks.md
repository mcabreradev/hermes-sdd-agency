## 1. The trigger and the architect's artifacts

- [x] 1.1 Replace the "applied when the domain merits it" phrasing in `agents/architect.md` with the five objective signals (invariant across more than one operation; entity with identity and lifecycle; a term defined or redefined in the project's vocabulary; a boundary between two business capabilities; vocabulary drift already present) and the rule that any one fires the trigger — verifies: `grep -q 'vocabulary drift already present' agents/architect.md && grep -q 'at least one' agents/architect.md`
- [x] 1.2 State in `agents/architect.md` that the evaluation is recorded whether or not the trigger fires, and that a partially evaluated trigger is not a valid skip — verifies: `grep -q 'whether or not the trigger fires' agents/architect.md`
- [x] 1.3 State the three artifacts in `agents/architect.md`: the `## Domain` section of the change's design, the project's `CONTEXT.md` glossary (term, tight definition, `_Avoid_` synonyms), and an ADR — plus the rule that the glossary is never copied into `~/.hermes/**` — verifies: `grep -q 'CONTEXT.md' agents/architect.md && grep -q '_Avoid_' agents/architect.md`
- [x] 1.4 State in `agents/architect.md` that a contradiction between the change and the existing glossary is reported as a blocker, never resolved by silently redefining the term — verifies: `grep -q 'blocker' agents/architect.md`
- [x] 1.5 Align the ADR location with the agency's convention: `docs/decisions/` is named first in `templates/adr.md` (the `domain-modeling` method's own example is `docs/adr/`) — verifies: `grep -q 'docs/decisions/' templates/adr.md`

## 2. The design artifact

- [x] 2.1 Add the `## Domain` section to `templates/architecture.md` — vocabulary resolution, entities/aggregates with the invariants that must hold on them, and the boundaries between the change's business capabilities — verifies: `grep -q '^## Domain' templates/architecture.md`
- [x] 2.2 Add the `## Domain` filling rules to `templates/architecture.md`: populated only when a signal fires; every element verifiable against the real diff; the vocabulary resolution points at the project's `CONTEXT.md` in glossary format; a section present but hollow (no invariant, no boundary, no vocabulary resolution) is an incomplete design — verifies: `grep -q 'hollow' templates/architecture.md`

## 3. The stage wiring

- [x] 3.1 `workflows/openspec-to-architecture.md`, step 1: add the domain deliverables to the agent's minimum output list (signal evaluation + `## Domain` + `CONTEXT.md`) — verifies: `grep -q '## Domain' workflows/openspec-to-architecture.md`
- [x] 3.2 `workflows/openspec-to-architecture.md`, step 2: add the domain checks to the validation loop — trigger evaluation recorded (or the signals evaluated, in the skip case), every stated invariant covered by a test that fails when it is violated, no requirement unlocated in the model, no hollow section — verifies: `grep -q 'trigger' workflows/openspec-to-architecture.md && grep -q 'invariant' workflows/openspec-to-architecture.md`
- [x] 3.3 `rules/coding.md` "Domain model": point the builder at the design's `## Domain` section and the project's `CONTEXT.md` as the vocabulary source of truth, keeping the existing duty to follow the model — verifies: `grep -q 'CONTEXT.md' rules/coding.md`
- [x] 3.4 `rules/quality.md`, "Definition of Done by task type": the `architect` row requires the recorded trigger evaluation and the domain artifacts when a signal fired; the `reviewer` row requires the domain checks to be reported — verifies: `grep -q 'trigger evaluation' rules/quality.md`

## 4. The reviewer's checklist

- [x] 4.1 `agents/reviewer.md` checklist, new item after "Consistency with the design": the four domain checks, each with its severity — glossary conformance (one business concept named in two ways, or a glossary term used with a meaning the glossary does not carry) = MAJOR; an invariant with no test that fails when it is violated = MAJOR; code contradicting the declared model with no recorded departure = MAJOR; a diff carrying domain structure with no recorded trigger evaluation = BLOCKER — verifies: `grep -q 'glossary' agents/reviewer.md && grep -q 'invariant' agents/reviewer.md`
- [x] 4.2 Extend `agents/reviewer.md` "Definition of Done" with the domain contract, and state that the verification is review — an agent reading the diff against the contract — with no executable tool required and none replacing it — verifies: `grep -qi 'domain contract' agents/reviewer.md && grep -q 'no executable tool is required' agents/reviewer.md`

## 5. Bundle and installer

- [x] 5.1 Add `domain-modeling` to `skill-bundles/architecture.yaml` (repo copy) — verifies: `ruby -ryaml -e 'y=YAML.load_file("skill-bundles/architecture.yaml"); exit(1) unless y["skills"].include?("domain-modeling")' && echo OK`
- [x] 5.2 Check the added name against the collision rule before it lands — a bare name that resolves in more than one skill **root** is skipped silently, so the check is the resolver's own output, not a directory count (two paths under `~/.agents`/`~/.claude` are the same linked tree and resolve fine) — verifies: `cd ~/.hermes/hermes-agent && PYTHONPATH=. ./venv/bin/python -c "from agent.skill_bundles import build_bundle_invocation_message as b; m,l,x=b('/architecture'); print(x)"` prints `[]` (empty missing set)
- [x] 5.3 Mirror the same edit into the live `~/.hermes/skill-bundles/architecture.yaml` and prove the bundle now resolves its method skill: `/architecture` loads `domain-modeling` with zero missing members — verifies: `cd ~/.hermes/hermes-agent && PYTHONPATH=. ./venv/bin/python -c "from agent.skill_bundles import build_bundle_invocation_message as b; m,l,x=b('/architecture'); print(l); print(x)"` prints `domain-modeling` in the loaded list and `[]` for missing
- [x] 5.4 `install.sh`: extend the missing-skill warning so a selected bundle set covers the architecture stage — `architecture` reports a missing `domain-modeling` just as `feature` does, and a set naming it twice prints the skill once — verifies: `tmp="$(mktemp -d)" && bash install.sh --prefix "$tmp" --yes --bundles architecture 2>&1 | grep -A3 'selected bundles load skills missing' ; bash install.sh --prefix "$(mktemp -d)" --yes --bundles feature,architecture 2>&1 | grep -c 'domain-modeling'` — with no skill installed at the prefix, the first prints the note naming `domain-modeling`, and the second prints `1` (de-duped)
- [x] 5.5 `install.sh` still parses and the non-interactive path is unchanged for the other bundles — verifies: `bash -n install.sh && bash install.sh --prefix "$(mktemp -d)" --yes --bundles plan >/dev/null 2>&1; echo $?` prints `0`

## 6. Documentation

- [x] 6.1 `docs/sdd-feature-lifecycle.md`, stage 3: replace the "when the domain merits it" line with the explicit signals, the artifacts (design `## Domain`, `CONTEXT.md`) and the note that the reviewer verifies the contract — verifies: `grep -q 'CONTEXT.md' docs/sdd-feature-lifecycle.md && grep -q 'signal' docs/sdd-feature-lifecycle.md`
- [x] 6.2 `README.md`: state the contract where the DDD/`domain-modeling` methodology is described, instead of the intention — verifies: `grep -q 'CONTEXT.md' README.md`
- [x] 6.3 `CHANGELOG.md` `[Unreleased]` `### Added` (and `### Changed` for the deferred requirement): the DDD trigger is explicit signals, the ubiquitous language lives in the project's `CONTEXT.md`, the design carries `## Domain`, and the reviewer verifies the contract — verifies: `grep -q 'DDD trigger' CHANGELOG.md`

## 7. Verification of this change

- [x] 7.1 The change validates with no failure — verifies: `test "$(openspec validate ddd-domain-contract --type change --json | jq -r '.summary.totals.failed')" = "0"`
- [x] 7.2 The `ℹ [INFO]` lines are read, not ignored: no `Archive would refuse this delta` for either delta — verifies: `openspec validate ddd-domain-contract --type change --json | jq -r '[.items[].issues[]?.message] | map(select(test("Archive would refuse"))) | length'` prints `0`
- [x] 7.3 The main specs stay valid after the deltas are written (the new capability must not break `--specs`) — verifies: `openspec validate --specs --json | jq -r '.summary.totals.failed'` prints `0`
- [x] 7.4 The repo's own known trap is checked: no main spec starts with a delta header — verifies: `grep -rl '^## ADDED Requirements' openspec/specs/*/spec.md | wc -l | tr -d ' '` prints `0`
- [x] 7.5 The installer still carries what it carried: exit code and the process tree land in a temp prefix — verifies: `bash install.sh --prefix "$(mktemp -d)" --yes >/dev/null 2>&1; echo $?` prints `0`
- [x] 7.6 The declared diff matches the touched files (the declared diff rule) — verifies: `git add -A && git diff --cached --name-only main | sort` equals the declared list below, which is the same set sorted:

  ```
  CHANGELOG.md
  README.md
  agents/architect.md
  agents/reviewer.md
  docs/sdd-feature-lifecycle.md
  install.sh
  openspec/changes/ddd-domain-contract/
  rules/coding.md
  rules/quality.md
  skill-bundles/architecture.yaml
  templates/adr.md
  templates/architecture.md
  workflows/openspec-to-architecture.md
  ```
- [x] 7.7 The authored-lines budget is measured and the delivery strategy recorded against the measurement (design.md, "Delivery strategy") — verifies: `git add -A && git diff --cached --numstat main | awk '{a+=$1; d+=$2} END {print a+d}'` and the strategy named in `design.md` agree (at or under 400 ⇒ `single-pr`; over ⇒ the strategy is re-chosen and re-recorded)
