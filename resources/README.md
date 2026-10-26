# Resources

Reference material *about* these dotfiles rather than files that get applied by them: specifications, style guides, and other documents worth keeping next to the configuration they inform.

Nothing here is a chezmoi source directory. The repository root applies nothing (see the root [README](../README.md)), and profile directories never see files above themselves, so a document can be dropped in here without any `.chezmoiignore` entry. Reach a file from a template with `{{ .chezmoi.sourceDir | dir }}/resources/<file>` or from a script with `$(dirname $(chezmoi source-path))/resources/<file>` if something ever needs to.

Not everything listed below is in git — this repository is public, so a document whose licence does not permit redistribution is ignored by `.gitignore` and the index records where to download it instead.

## Index

| Resource | Kind | In git | Upstream | Why it is here |
|----------|------|--------|----------|----------------|
| `ASD-STE100_ISSUE9.pdf` | Specification (434 pp.) | no — download it | [asd-ste100.org](https://asd-ste100.org/) (free, registration required) | ASD-STE100 Simplified Technical English, Issue 9 — the controlled-English standard used as a writing reference for documentation, commit messages, and script help text. Distilled into [`claude-home/simplified-technical-english.md`](../claude-home/simplified-technical-english.md), which is loaded into every Claude Code session. |

## Adding a resource

1. Drop the file in this directory, keeping its upstream filename when it carries a version or issue number.
2. Check whether it may be redistributed. If not — or if it is large or frequently revised — add it to `.gitignore` with a comment saying why, and set the index's **In git** column to `no` with a pointer to the download. Vendor a copy only when having it offline is the point and the licence allows it.
3. Add a row to the index above: what it is, where it came from, and what it is used for. The last column is the one that matters — a file with no stated reason is a file nobody can confidently delete later.
