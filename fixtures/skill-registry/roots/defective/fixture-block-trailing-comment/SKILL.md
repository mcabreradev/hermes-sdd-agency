---
name: fixture-block-trailing-comment
description: >- # folded text intended below, never becomes the description
metadata:
  hermes:
    tags: [fixture, defective]
---

# Fixture: content-less block scalar with a trailing comment

The `>- # …` indicator carries a YAML comment instead of a body. The loader presents the
literal `>- # …` as the description — the converted-persona defect, with a comment after
the indicator.
