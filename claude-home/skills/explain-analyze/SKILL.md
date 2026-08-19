---
name: explain-analyze
description: Use when the user asks for a rich explanation or analysis of existing source code — how a subsystem works, where a behavior comes from, why a design is the way it is, what the tradeoffs or risks are. Analyzes code as it stands rather than a change to it. Produces HTML output.
---

# Explain Analyze

Please make me a rich, interactive analysis of the source code, answering the question in the rest of the prompt.

Read `~/.claude/skills/explain-html-common/FORMAT.md` in full before writing any HTML, and follow it exactly. It carries the build, diagramming, callout, code-block, file-naming, and prose rules for this document. The sections below and the analysis-specific rules at the end are the only additions.

## The analysis directive

The remainder of the prompt after this skill's invocation is the analysis directive: it names the code to analyze and the question to answer. Treat it as the document's thesis — every section exists to answer it, and nothing that doesn't serve it belongs in the document.

If the directive names a question (for example "is this thread-safe", "where does the latency come from", "why are there two caches"), the Analysis section answers that question and the document's title states the answer. If the directive only names a target with no question, default to a design walkthrough: how the code is structured, how control and data flow through it, and which decisions shape it.

## Investigate before writing

Read the code before making any claim about it. Trace the paths that matter end to end — callers, callees, error paths, concurrency, configuration — rather than reasoning from names and signatures. Check tests for the behavior the code is expected to have. Where the answer depends on something outside the repository (a runtime, a deployment, a dependency's internals), say so instead of guessing.

## Sections

- Background: Explain the existing system the analysis sits in. (You should broadly explore surrounding code for this.) We don't know how much the reader already knows, so include a deep background for beginners (note that it can be skipped if the reader is already familiar), and then a more narrow background directly relevant to the question.
- Intuition: Explain the core model of how this code works — the essence, not the full details. Use concrete examples with toy data. Use figures and diagrams liberally.
- Analysis: Answer the directive's question. Lead with the answer, then the evidence for it, then the cases where it doesn't hold. Distinguish what the code does from what it appears intended to do.
- Code: Walk through the code that carries the argument, grouped and ordered so it builds toward the conclusion. Show only the parts that matter; a cited `file:line` beats a pasted block the reader must scan.

Include a Findings, Risks, or Open Questions section only when the analysis actually produced them; state each with its evidence and its severity or confidence. Do not pad the document with a section that has nothing in it, and do not propose fixes or write code unless the directive asks for them.

Analysis-specific format rules:

- Use `line-focus` to point at the lines that carry an argument. Do not use `line-add` or `line-remove` — nothing here is a diff.
- `.compare` and `.diff-split` are for contrasting two code paths, two configurations, or two designs, not for before/after.
- `<description>` in the filename is a short kebab-case slug for the question being analyzed.
