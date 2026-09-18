---
name: web-performance-benchmark
description: "Baseline Core Web Vitals and bundle size; before/after on every PR."
---
<!-- hermes-add-skill: concept adapted from gstack /benchmark (garrytan/gstack, MIT). -->

# Web performance benchmark

Establish baselines for a web app and detect regressions on every PR: page load time,
Core Web Vitals, and resource/bundle sizes. Evidence-based — a perf claim needs a number
and the measurement that produced it.

## Baselines

Measure and record:

- **Load time** (e.g. TTFB, DOMContentLoaded, load) on a reference page/route.
- **Core Web Vitals**: LCP, INP/CLS on the key pages.
- **Resource sizes**: bundle/size per entry, total, and per-image/video weight.

Store the baseline in the project (e.g. `.context/perf.jsonl` or a committed table), tied
to the commit/content it was measured on.

## Before/after per change

On a PR that can affect performance, measure against the stored baseline and report:

- before vs after per metric.
- A regression beyond the declared threshold is a `MAJOR` finding (a perf-sensitive change
  that didn't measure anything is itself a finding).

## Integrity notes

- Quote the **page/route, the tool, and the run** that produced each number; an unmeasured
  "it's fast enough" is not evidence.
- Vary run conditions; a single noisy run is not a baseline. Report the environment
  (local browser, headless, throttled) alongside the result.
