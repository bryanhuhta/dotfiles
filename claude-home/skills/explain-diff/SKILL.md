---
name: explain-diff
description: Use when the user asks for a rich explanation of a code change, diff, branch, or PR. Produces HTML output.
---

# Explain Diff

Please make me a rich, interactive explanation of the specified code change.

Read `~/.claude/skills/explain-html-common/FORMAT.md` in full before writing any HTML, and follow it exactly. It carries the build, diagramming, callout, code-block, file-naming, and prose rules for this document. The sections below and the diff-specific rules at the end are the only additions.

It should have these sections:

- Background: Explain the existing system relevant to this change. (You should broadly explore surrounding code for this.) We don't know how much the reader already knows, so include a deep background for beginners (note that it can be skipped if the reader is already familiar), and then a more narrow background directly relevant to the change.
- Intuition: Explain the core intuition for the code change. The focus here is to explain the essence, not the full details. Use concrete examples with toy data. Use figures and diagrams liberally.
- Code: Do a high-level walkthrough of the changes to the code. Group/order the changes in an understandable way.

Diff-specific format rules:

- Use `line-add` and `line-remove` on `.code-block` lines to show what the change did; use `.diff-split` for side-by-side before/after comparisons.
- `<description>` in the filename is a short kebab-case slug for the change.
