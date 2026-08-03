## Preferred tooling

- Use `jq` to analyze JSON data structures. Avoid using inline JavaScript or Python piped to `node` or `python` to analyze JSON.

## Code style

- Never use banner comments under any circumstances. This includes any decorative section header like `// ===== Section =====`, `// --- Helpers ---`, `/* ## Title ## */`, boxed ASCII headers, or similar divider-style comments meant to label a region of code. They are unsightly and clutter the codebase.

## Markdown style

- When creating markdown files, don't hard-wrap lines at 80 characters (or any column limit). Write each paragraph or list item as a single line; individual IDEs apply soft-wrap based on user preference.
