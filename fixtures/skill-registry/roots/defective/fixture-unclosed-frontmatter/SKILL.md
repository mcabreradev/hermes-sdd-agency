---
name: fixture-unclosed-frontmatter
description: A frontmatter block that opens but never closes before the body starts.

# Fixture: unclosed frontmatter

The opening `---` has no matching closing `---`, so the block is malformed.
The registry must flag UNCLOSED-FRONTMATTER instead of reading the body as metadata.
