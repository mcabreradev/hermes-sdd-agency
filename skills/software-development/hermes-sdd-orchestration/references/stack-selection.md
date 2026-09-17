# Choosing a stack for an MVP under this agency

The agency's personas are not stack-neutral, so the stack choice decides whether the builder
has expertise or only has a contract.

## The rule that dominates

**Pick the stack the installed personas cover, or install the persona for the stack you pick.**
Nothing breaks if you skip this — the builder still runs — but it runs as a role file with no
domain expertise, which is the exact state the persona install was meant to fix.

Measured bias of what backs the builder today: `fullstack-developer` assumes the
TypeScript-first stack (Next.js, tRPC, Drizzle, Postgres, Vercel, Bun) and `typescript-pro`
is TypeScript-heavy. The process skills (`executing-plans`, `qa-test-planner`,
`e2e-testing-patterns`, `code-review-checklist`) use Vitest/Playwright examples. Anything
outside TypeScript is uncovered.

## Default recommendation

**TypeScript full-stack in a single repo.** Preferred shape, by MVP form:

| MVP form | Stack | Why |
|---|---|---|
| Web app with users, auth, data | Next.js (App Router) + TypeScript + Postgres (Supabase/Neon) + Drizzle or Prisma + Tailwind | The stack `fullstack-developer` assumes by default; zero persona friction |
| Small product, no own backend | Astro + TypeScript + React islands | Less surface; tests stay Vitest |
| Library / npm package | TypeScript + pnpm + Vitest + tsd | Matches the existing package convention |
| API only | Bun + Hono + TypeScript | Fast startup, simple deploy |
| Data / ML | Python + FastAPI — **install `python-pro` first** | No Python persona installed today |
| Native performance, distributed CLI | Rust or Go — **install `rust-pro` / `golang-pro` first** | No persona installed today |

Single-repo is a deliberate part of the recommendation, not just convenience: one project
root, one `openspec/`, one gate. A multi-repo MVP multiplies the boundary checks in
`rules/project-boundaries.md` for no MVP-stage gain.

Package manager: pnpm (the established convention on this machine).

## Verify before recommending

Do not assert runtime availability from memory — check it:

```bash
node -v; bun -v; pnpm -v; python3 -V; rustc --version
cat <project>/package.json | jq '.packageManager, .dependencies'   # existing convention
```

Two traps this catches: a language runtime can be present but **too old** for the framework
being proposed (verify the interpreter version against the stack, not just its presence), and
"preferred stack" in an `initialize-project` input can contradict what the repo already uses —
the repo wins and the divergence gets reported.

## When the answer is not TypeScript

Install the persona before the first `/implement`, in this order:

1. `hermes-add-agent --search <lang>` to find the slug under `programming-languages/`.
2. `hermes-add-agent <slug>` (add `--force` to re-sync after editing the source).
3. Read the description back — never trust the installer's exit message.

If the persona cannot be installed, say so and flag that the builder stage runs without
expertise rather than silently proceeding.

## Rewriting a stack that already ships (migration decisions)

A migration is chosen by its target, not by its benchmark. Settle the target first, because it
decides the language:

- **Compute that must run in the browser, or behind an FFI boundary ⇒ Rust** — `wasm-bindgen` and
  napi-rs are the mature path for the two targets a library needs.
- **Throughput, concurrency or memory on the server only ⇒ Go** — the same gain for the hot loop
  with far less FFI machinery, and no WASM story to maintain. Go's `GOOS=js` target and the
  TinyGo trade-offs make it a poor answer to a browser requirement.
- **Neither mandated ⇒ do not migrate.** Measure the current engine's ceiling before proposing a
  rewrite: a mature TypeScript core of a few thousand LOC already answers 100k-item queries in
  tens-to-low-hundreds of ms, so a performance-only rewrite has to beat that on the same workload
  before it earns months of porting. Measure it as the hot path against two references — the raw
  array walk and a hand-compiled equivalent predicate of the same expression — per dataset size and
  per selectivity, never as one absolute number. When the hand-compiled route is orders of magnitude
  faster while a port would reach only a fraction of that, the win is local: the deliverable is a
  small change in the host language, not a migration (`references/performance-headroom.md`).

Then, before accepting any wave plan, measure the host language's own headroom first — an
order-of-magnitude local win makes the whole plan unnecessary, and that measurement is what turns
"Rust or Go?" into a decision. When the local win is not there, work through these in order:

1. **Measure the boundary tax; never assert it.** When the design crosses the boundary with JSON
   (or any serialization), write a throwaway harness that times the real engine against the
   `stringify(input) + parse(output)` cost of the same workload — a temp script importing the
   package's own entry point, with a warm-up run — and report the ratio per dataset size **and per
   selectivity**. The tax scales with the matched payload, so the all-match query is the worst
   case: that is precisely where parallelism looks best in theory and pays least in practice.
2. **Check who already consumes the package.** For a published library the consumers decide, not
   the benchmarks: read the download counts, and read the repo's documented install paths (CDN /
   `esm.sh`, Deno, bundler requirements). Native addons plus `optionalDependencies` change
   install-time behaviour and top-level await breaks ESM CDNs, so a 'no breaking changes' claim is
   false exactly in the paths nobody tests. Also check whether the package currently advertises
   lifecycle-script-free install or a per-module size budget — both are regressions a migration
   plan usually forgets to price.
3. **Enumerate the non-serializable public surface.** Function-typed members of the public API —
   predicate functions, custom comparators, callbacks receiving objects — cannot cross an
   FFI/JSON boundary. Grep the type definitions for them before committing, then either push them
   into the core query as part of the AST or keep those paths in the host language. Letting them
   reach the core as JSON silently degrades them to a default, which is a correctness bug, not a
   fallback.
4. **Price the semantics that move with the computation.** Anything reading 'now' (relative dates,
   ages, cache TTLs) changes meaning when the core computes it instead of the host, and a
   behaviour-preserving test suite will not catch it. Pin the clock as an input.
5. **Prove it on a vertical slice.** One subsystem, every target that is in scope, the existing
   test suite as the contract, and the benchmark running in CI the same day — weeks, not months.
   When a plan's bulk is packaging, CI matrices, cross-compilation, tooling and translating the
   test suite to the new language rather than porting logic, the port is the small part: cut that
   incidental scope before accepting the timeline.