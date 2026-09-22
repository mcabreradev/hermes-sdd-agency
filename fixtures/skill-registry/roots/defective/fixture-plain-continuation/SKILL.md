---
name: fixture-plain-continuation
description: first line of a plain scalar
  and an indented continuation line
---

# Fixture: plain multi-line scalar with a value on the first line

Legal YAML whose value cannot be reduced line-wise. The registry must flag it
MULTILINE-SCALAR rather than printing only the first line as if it were the whole
description.
