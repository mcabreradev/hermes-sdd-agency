# Measuring headroom before a rewrite

A rewrite or language port proposed for performance is answered by a measurement, not by a language
preference. Prove the current engine is at its ceiling first: if a hand-written equivalent of the hot
path is orders of magnitude faster in the host language, the win is local and the port is
unnecessary.

## The probe

Throwaway script, never committed:

- Import the engine **from source** (its `src/index.ts` entry), not a built copy — you are measuring
  what ships.
- One dataset object reused by every variant; sizes 1k / 10k / 100k; warm up before timing; report
  the **min of several rounds** (a mean is dominated by GC).
- Run it with the repo's local binary (`./node_modules/.bin/<runner> <script>`); `pnpm exec` can try
  to reconcile the module store and abort without a TTY. Expect the editor's type-check pass to flag
  the temp script — it imports `.ts` sources with no tsconfig context — and judge only the script's
  stdout.

## The rows that decide it

| variant | what it isolates |
|---|---|
| `data.filter(() => true)` | the floor: array walk + result allocation |
| `filter(data, {})` — empty expression | engine entry / binding overhead alone |
| `filter(data, <real expression>)` | the hot path under test |
| the same expression as a hand-compiled predicate | the ceiling the host language already offers |

Read ratios, not absolutes, and per selectivity (all-match, half-match, few-match):

- **empty ≈ floor** ⇒ the per-item cost is the predicate walk (operator / property dispatch), not
  argument handling. The fix is a fast path in the engine, not a faster runtime.
- **hand-compiled ≈ floor while the engine is far above** ⇒ an order of magnitude is sitting in the
  host language; a port that reaches a fraction of it does not earn its cost.
- Build the predicate once outside the loop and reuse it. If that changes nothing, neither predicate
  construction nor the predicate cache is the cost — do not "optimize" them, and check whether the
  cache is even enabled by default before citing it as protection.

## Equivalence before speed

A fast path is a bug generator unless it is checked against the engine on the exact shapes:

- Assert identical output on the real data — same count **and** the same elements, in order — not
  just the shape you had in mind.
- Do not take the engine's semantics from its docs or from a plausible reading of an expression.
  Probe them: run the same field as a plain `{ field: 'value' }` and compare its match count against
  a hand-written filter for each candidate meaning (contains / equality / prefix). Choosing the wrong
  reading yields a fast path that silently returns different results.

## What to propose from the measurement

- **Local win available** ⇒ propose a bounded change in the host language: fast paths for the
  dominant expression shapes, falling back to the generic engine for everything else. Price in three
  things — differential equivalence tests against the generic route, the benchmark running in CI, and
  the semantics edges (any-property keys, negation prefixes, depth limits, case sensitivity, function
  predicates) named as explicit non-goals of the fast path.
- **No local win** ⇒ the port question is live, and the language is then decided by target
  (browser / FFI ⇒ Rust, server-only throughput ⇒ Go): `stack-selection.md`.
