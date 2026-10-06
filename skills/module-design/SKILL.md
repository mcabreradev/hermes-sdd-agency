---
name: module-design
description: "Use when designing or disputing a module's shape: depth, seam, adapter, leverage, locality. Deep modules — a lot of behaviour behind a small interface, at a clean seam."
---

# Module design

Design **deep modules**: a lot of behaviour behind a small interface, placed at a clean seam, testable
through that interface. Use this language and these principles wherever code is being designed or
restructured. The aim is leverage for callers, locality for maintainers, and testability for everyone.

This is a **reference to consult**, not a session to run. `build-craft` and `bug-diagnosis` both speak
this vocabulary; reach for it directly when the *words*, not the process, are the problem.

## Glossary

Use these terms exactly: do not substitute "component", "service", "API" or "boundary". Consistent
language is the whole point.

- **Module** — anything with an interface and an implementation. Deliberately scale-agnostic: a
  function, a class, a package, or a tier-spanning slice. *Avoid*: unit, component, service.
- **Interface** — everything a caller must know to use the module correctly: the type signature, but
  also invariants, ordering constraints, error modes, required configuration and performance
  characteristics. *Avoid*: API, signature (too narrow — they name only the type-level surface).
- **Implementation** — what is inside a module; its body of code. Distinct from **Adapter**: a thing
  can be a small adapter with a large implementation (a Postgres repository) or a large adapter with a
  small implementation (an in-memory fake). Reach for "adapter" when the seam is the topic;
  "implementation" otherwise.
- **Depth** — leverage at the interface: how much behaviour a caller or a test can exercise per unit
  of interface they have to learn. A module is **deep** when a large amount of behaviour sits behind a
  small interface, **shallow** when the interface is nearly as complex as the implementation.
- **Seam** — a place where you can alter behaviour without editing in that place; the *location* at
  which a module's interface lives. Where to put the seam is its own design decision, distinct from
  what goes behind it. *Avoid*: boundary (overloaded with DDD's bounded context).
- **Adapter** — a concrete thing that satisfies an interface at a seam. It describes a *role* (what
  slot it fills), not a substance (what is inside).
- **Leverage** — what callers get from depth: more capability per unit of interface they learn. One
  implementation pays back across N call sites and M tests.
- **Locality** — what maintainers get from depth: change, bugs, knowledge and verification concentrate
  in one place instead of spreading across callers. Fix once, fixed everywhere.

## Deep vs shallow

**Deep** — a small interface, lots of implementation:

```
┌─────────────────────┐
│   Small Interface   │  ← few methods, simple params
├─────────────────────┤
│  Deep Implementation│  ← complex logic hidden
└─────────────────────┘
```

**Shallow** — a large interface, little implementation (avoid):

```
┌─────────────────────────────────┐
│       Large Interface           │  ← many methods, complex params
├─────────────────────────────────┤
│  Thin Implementation            │  ← just passes through
└─────────────────────────────────┘
```

When designing an interface, ask:

- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?

## Principles

- **Depth is a property of the interface, not the implementation.** A deep module can be internally
  composed of small, mockable, swappable parts; they are just not part of the interface. A module can
  have **internal seams** (private to its implementation, used by its own tests) as well as the
  **external seam** at its interface.
- **The deletion test.** Imagine deleting the module. If the complexity vanishes, it was a
  pass-through. If the complexity reappears across N callers, it was earning its keep.
- **The interface is the test surface.** Callers and tests cross the same seam. If you want to test
  *past* the interface, the module is probably the wrong shape.
- **One adapter means a hypothetical seam; two adapters mean a real one.** Do not introduce a seam
  unless something actually varies across it.

## Designing for testability

Good interfaces make testing natural. Each rule below is what `build-craft`'s seam discipline assumes
of the code it tests.

1. **Accept dependencies, don't create them.**

   ```
   // Testable
   function processOrder(order, paymentGateway) {}

   // Hard to test
   function processOrder(order) {
     const gateway = new StripeGateway();
   }
   ```

2. **Return results, don't produce side effects.**

   ```
   // Testable
   function calculateDiscount(cart) -> Discount {}

   // Hard to test
   function applyDiscount(cart) -> void {
     cart.total -= discount;
   }
   ```

3. **Small surface area.** Fewer methods means fewer tests needed; fewer params means simpler setup.

## Relationships

- A **Module** has exactly one **Interface** — the surface it presents to callers and tests.
- **Depth** is a property of a **Module**, measured against its **Interface**.
- A **Seam** is where a **Module**'s **Interface** lives.
- An **Adapter** sits at a **Seam** and satisfies the **Interface**.
- **Depth** produces **Leverage** for callers and **Locality** for maintainers.

## Rejected framings

- **Depth as the ratio of implementation lines to interface lines** (Ousterhout). It rewards padding
  the implementation. Depth-as-leverage is the measure used here.
- **"Interface" as the language's `interface` keyword or a class's public methods.** Too narrow:
  interface here includes every fact a caller must know.
- **"Boundary".** Overloaded with DDD's bounded context. Say **seam** or **interface**.

## Where this is checked

`rules/quality.md` and `agents/reviewer.md` make these terms the vocabulary a structural dispute is
settled against: a reviewer that flags a module names the term (a pass-through, a seam with nothing
varying across it) rather than arguing about taste. The finding carries a `path:line` like any other.
