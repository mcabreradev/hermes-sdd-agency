---
name: fixture-block-indicator
description: |2-
metadata:
  hermes:
    tags: [fixture, defective]
---

# Fixture: content-less block scalar with an indentation indicator

The `description: |2-` opens a block scalar with an explicit indentation indicator whose
body is immediately closed by the next key. The loader presents the literal `|2-` as the
description — the converted-persona defect, in its indicator-carrying form.
