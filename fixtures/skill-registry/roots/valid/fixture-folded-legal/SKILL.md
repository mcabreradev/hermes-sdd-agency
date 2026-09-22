---
name: fixture-folded-legal
description: >-
  A folded scalar with a real body — legal YAML whose description is this text, exactly
  the shape `context-architecture` uses and an old detector wrongly flagged.
metadata:
  hermes:
    tags: [fixture, valid]
---

# Fixture: legal folded scalar

`description: >-` followed by an indented body is valid YAML. The registry must report
this skill as healthy with the body as its description.
