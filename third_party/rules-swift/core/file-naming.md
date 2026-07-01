# File Naming Rules

**Status: house convention for committed filenames.** Every committed document or asset follows these conventions: lowercase, dash-separated, ASCII, ISO dates. This is the filename companion to `commits.md` (the same discipline applied to commit text): a name a future reader can predict, type, and glob without surprises.

## Scope

This rule governs committed **documents and assets**: scanned documents, photos, exports, dated records, and the other non-code files a repository accumulates. Two classes are out of scope and are never flagged by the audit below, because a different authority already names them:

- **Source code.** A source file follows its language's own naming convention. A Swift type file is `PascalCase`, named for the single type it holds, and a framework-style internal type may carry a leading underscore (`_ConditionalContent.swift`); a Go file is lowercase; and so on. That language convention is the authority for those files, and the code-style rule of each language domain owns it. This rule does not override it, so source trees are excluded from the audit.
- **Conventional and tool-mandated names.** The uppercase names a tool or ecosystem expects verbatim: the repository-root files `LICENSE`, `CHANGELOG`, `CONTRIBUTING`, `CODEOWNERS`, `NOTICE`, `AUTHORS`, and `README`; the platform infrastructure under `.github/` (`ISSUE_TEMPLATE/`, `PULL_REQUEST_TEMPLATE`, `FUNDING.yml`); and the build and package manifests a toolchain loads by an exact name (`Package.swift`, `Package.resolved`, `Package@swift-5.9.swift`, `Dockerfile`, `Makefile`, `Gemfile`, `Rakefile`, `Podfile`, `Cartfile`, `Fastfile`). Renaming any of them would break the tool that looks for them.

## General rules

- **Lowercase only**: no uppercase letters in filenames.
- **Dashes for separators**: use `-` instead of spaces, underscores, or camelCase.
- **No spaces**: ever.
- **No special characters**: no accented letters, `()`, `[]`, `&`. Transliterate accented characters to plain ASCII (for example, c-with-caron to `c`, s-with-caron to `s`, d-with-stroke to `dj`).
- **No trailing dots**: remove any dot before the file extension.
- **ASCII only**: filenames must be plain ASCII.

## Date format in filenames

Always use the ISO format `YYYY-MM-DD`:

- `30.11.2023` -> `2023-11-30`
- `11.03.2024.` -> `2024-03-11`
- `Mar 24, 2025` -> `2025-03-24`

## Document naming patterns

### Scanned documents

```
Scan MMM DD, YYYY at HH.MM.pdf    -> scan-YYYY-MM-DD-HH-MM.pdf
Scan DD.MM.YYYY. at HH.MM.pdf     -> scan-YYYY-MM-DD-HH-MM.pdf
Scan DD MMM YYYY at HH.MM.pdf     -> scan-YYYY-MM-DD-HH-MM.pdf
```

### Photos

```
IMG_XXXX.jpeg                      -> keep as-is (acceptable)
IMG_XXXX.HEIC                      -> convert to IMG_XXXX.jpg
Photo DD-MM-YYYY.heic              -> photo-YYYY-MM-DD.jpg (convert + rename)
```

### Dated documents

```
<type>-<description>-YYYY-MM-DD.<ext>
```

Use a date suffix only when the document is date-specific; omit it otherwise. Neutral examples:

```
invoice-2024-03-01.pdf
design-notes-2025-06-14.md
release-checklist.md          # not date-specific, no suffix
```

## Renaming existing files

When renaming, use `git mv` to preserve history:

```bash
git mv "Old File Name.pdf" "old-file-name.pdf"
```

Commit: `rename: normalize filenames`

## Audit (before any processing)

Run these in the repo before reporting counts:

Point `<repo>` at the document and asset directories the rule governs, or add a `-not -path "*/<source-dir>/*"` for each source tree (`Sources`, `Tests`, `src`), so the queries do not flag source files that follow their language convention (see Scope).

```bash
# Files with spaces
find <repo> -name "* *" -not -path "*/.git/*" -not -name "*.md"

# Files with uppercase (documents and assets only; source files and the
# conventional or tool-mandated names of the Scope section are out of scope)
find <repo> -regex ".*/[^/]*[A-Z][^/]*" -not -path "*/.git/*" -not -path "*/.github/*" \
  -not -name "*.md" \
  -not -name "README*" -not -name "LICENSE" -not -name "CHANGELOG" \
  -not -name "CONTRIBUTING" -not -name "CODEOWNERS" -not -name "NOTICE" \
  -not -name "AUTHORS" \
  -not -name "Package.swift" -not -name "Package.resolved" -not -name "Package@*.swift" \
  -not -name "Dockerfile" -not -name "Makefile" -not -name "Gemfile" \
  -not -name "Rakefile" -not -name "Podfile" -not -name "Cartfile" -not -name "Fastfile"

# Files with underscores (excluding .git and the tool-mandated .github tree)
find <repo> -name "*_*" -not -path "*/.git/*" -not -path "*/.github/*" -not -name "*.md"

# HEIC files
find <repo> \( -name "*.heic" -o -name "*.HEIC" \) -not -path "*/.git/*"
```

Run over the documents and assets in scope, a clean repo returns nothing from the first three queries: the `.md`, `README`, and conventional-root-file exclusions cover the in-scope exceptions, and the source-tree exclusion keeps the audit off code, which the language's own code-style rule governs (Scope).

## Skip list

Some asset paths legitimately carry vendor-supplied names and are exempt from the audit. Document the skip paths per repo (for example, browser-extension resource folders, generated asset bundles, vendor media dumps). Keep the list short and justified: every exemption is a name a reader cannot predict, so it must earn its place.

## Companion rules

- `commits.md`: the same lowercase/dashed/ASCII/ISO discipline applied to commit messages and branch names.
- `no-shortcuts-first-principles.md`: an unpredictable filename committed "just this once" is a small shortcut that compounds across a tree.

## Why this exists

Filenames are an interface. A predictable scheme means a reader can guess a path, a glob can match a set, and a sort orders by date without a parser. Mixed case, spaces, and locale-specific characters break globs, confuse case-insensitive filesystems, and force quoting. The convention costs nothing at creation time and saves every later reader.
