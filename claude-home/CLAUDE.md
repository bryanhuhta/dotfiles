## Preferred tooling

- Use `jq` to analyze JSON data structures. Avoid using inline JavaScript or Python piped to `node` or `python` to analyze JSON.

## Code style

- Never use banner comments under any circumstances. This includes any decorative section header like `// ===== Section =====`, `// --- Helpers ---`, `/* ## Title ## */`, boxed ASCII headers, or similar divider-style comments meant to label a region of code. They are unsightly and clutter the codebase.

## Markdown style

- When creating markdown files, don't hard-wrap lines at 80 characters (or any column limit). Write each paragraph or list item as a single line; individual IDEs apply soft-wrap based on user preference.

## Document creation

- When asked to produce a standalone technical document (an explanation, report, review summary, architecture walkthrough, postmortem, analysis, etc.), favor a single self-contained HTML file styled with the explain-css system over markdown or plain text. The stylesheet is at `~/.local/share/explain-css/explain.css`; the design guide, component catalog, and rules are at `~/.local/share/explain-css/DESIGN.md` — read the guide before building the document and follow it exactly. Inline the full contents of `explain.css` into a `<style>` block in the document's `<head>` so the file stays self-contained. This preference doesn't apply to short inline answers, code itself, or when the user asks for a different format.
- Name the produced file `<YYYY>-<MM>-<DD>-<project>-<description>.html` and save it in `/tmp`. `<project>` is the name of the repo or project the document concerns; `<description>` is a short kebab-case slug for the document's subject. For example: `/tmp/2026-08-13-explain-css-retry-queue-refactor.html`.
