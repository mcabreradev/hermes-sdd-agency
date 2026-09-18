---
name: security-evidence-first
description: "Security review: evidence before assurance; attacker, boundary, impact, challenge."
---
<!-- hermes-add-skill: framing adapted from gstack /cso (garrytan/gstack, MIT). Only the review
     discipline is kept; the heavy runtime (Docker/catalogs) is out of scope for this agency. -->

# Security review: evidence before assurance

Find exploitable defects, and prove each one — not "we ran a scanner". Every finding is
stated with **attacker, boundary, impact, and challenge**.

## The four-part finding

| Part | What it forces |
|---|---|
| **Attacker** | Who is the actor and what can they already do? (anonymous, authenticated low-priv, internal, LLM-fed input…) |
| **Boundary** | Where does trust cross? What is trusted input vs untrusted input at this seam? |
| **Impact** | What breaks or is exposed if exploited — confidentiality/integrity/availability, and who sees the cost? |
| **Challenge** | What's the strongest honest objection to calling this exploitable? Say it yourself. |

A finding missing any of the four is not actionable and goes back.

## OWASP-informed scope

Check the OWASP categories that apply to the stack (injection, broken access control,
secrets, insecure deserialization, SSRF… — adapt to what the project is). Report only what
the project could actually exhibit; a boilerplate OWASP list with no evidence is noise.

## Rules

- **Evidence before assurance**: a claim of security needs the reproduction path, not a
  vibe. "We reviewed for X" without a concrete finding + evidence is `blocked`, not `pass`.
- **`--diff` mental model**: prioritize the branch/worktree change and its affected security
  paths over re-auditing the whole untouched surface.
- Containment / no host blast radius is the *operator's* job, not a claim to make inside the
  review. Do not assert sandboxing you didn't set up.
- Findings, evidence, and harnesses are **not** uploaded anywhere or sent to any remote —
  they live in the report.
