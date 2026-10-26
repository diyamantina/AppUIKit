# Versioning: one VERSION file, a semantic version, a build number that is the commit count

**Status: MANDATORY for every app and service that ships a version number.** The version is written once, in a `VERSION` file, and is a Semantic Versioning 2.0.0 value. The build number is the number of commits on the first-parent chain of the release branch at build time. Both reach the code through a generated file, never through a constant that someone edits. The App Store fields take only what Apple documents for them, and everything richer stays in our own strings.

Each rule below carries its basis: **documented** (Apple documentation or the Semantic Versioning specification, named so it can be read), **observed** (found by running the toolchain), or **design** (a choice, with the reason).

## Why

- **A version kept in several places drifts.** A hand-edited Swift constant, a project setting of `1.0`, and a store listing will disagree within a sprint. One file has nothing to disagree with.
- **The store fields are narrow.** The short version takes three integers and the build takes one to three; neither takes a pre-release tag or a hash. A scheme that wants those keeps them in logs, bug reports, and headers, where they cost nothing.
- **A build number that names a commit is a pointer.** A tester reports build 42; `git rev-list --first-parent --reverse main | sed -n 42p` returns the commit. A timestamp or a counter in a CI service cannot be walked back that way from a clone.

## Rules

1. **One source: the `VERSION` file at the repository root.** It holds one line, a version in the form `major.minor.patch` with an optional `-pre.release`. No other file states a version number by hand: no Swift constant, no project setting, no plist. *Basis: design.*
2. **It is parsed by the grammar, not by habit.** A value that is not Semantic Versioning 2.0.0 (a leading `v`, a missing part, a leading zero, an empty identifier, a number too large for an `Int`) has no value, and the build stops with a message that names the file and the text. `VERSION` carries no build metadata; the build adds its own. *Basis: documented (semver.org, 2.0.0, sections 2, 9 and 10).*
3. **The store's short version is the core and nothing else.** `CFBundleShortVersionString` is `major.minor.patch`: digits and periods, three integers. A pre-release or build metadata cannot go in it. *Basis: documented (Apple, `CFBundleShortVersionString`: "The required format is three period-separated integers ... can only contain numeric characters (0-9) and periods").*
4. **The build number is the first-parent commit count of the release branch.** `git rev-list --first-parent --count HEAD`. On the release branch it grows by exactly one per commit and every value names one commit, which a plain `--count` does not guarantee once a merge brings in side commits. It never restarts when the version changes. *Basis: documented for the need (Apple, `CFBundleVersion` is "one to three period-separated integers"; and Xcode Cloud: "Mac apps must follow different build number requirements ... its build number must continuously increase, even across app versions"); design for the first-parent choice.*
5. **It is generated at build time, by a build-tool plugin, into a file the code reads.** The generator reads `VERSION` and git and writes a Swift file of constants; the version type in the code returns them. The plugin's command names its inputs: `VERSION`, and the git files that move when `HEAD` does (`.git/HEAD` and its reflog, `.git/logs/HEAD`, which every commit, merge, reset and checkout appends to). Name only inputs that exist; SwiftPM treats a missing input as an error. *Basis: observed (SwiftPM 6.x, macOS): in a clone with the inputs named, one new commit changed the generated build number from 43 to 44 and the commit hash with it.*
6. **No silent default.** A generator that cannot count commits stops. A shallow clone counts too few and is refused (`git rev-parse --is-shallow-repository`); a work tree with no repository is refused. A build that has no git history on purpose (a container image built from a copy of the sources) is given the facts in two named variables (`APP_BUILD_NUMBER`, a positive integer, and `APP_COMMIT`, a short hash), and a build with neither stops. Never fall back to `1`. *Basis: design. A shallow clone has fewer commits than the branch, so its count is smaller than the true one and can fall below a build already uploaded; a fallback to `1` is the same failure with a constant.*
7. **CI clones the full history.** Every job that builds a version fetches all commits (`fetch-depth: 0` in GitHub Actions, `GIT_DEPTH: 0` in GitLab). *Basis: the generator refuses anything else (rule 6).*
8. **The richer form is for our own strings.** `semanticVersion` is `major.minor.patch+build.commit` for a release and `major.minor.patch-pre.release.build+commit` for a pre-release, with `.dirty` appended to the metadata when tracked files had uncommitted changes. For a pre-release the count is a numeric identifier, which semantic versioning orders by value (`beta.9` before `beta.42`); metadata is ignored in precedence, so on a release it can name a build but not order it. It is used in logs, bug reports, and request headers, and nowhere a store field is. *Basis: documented (semver.org, section 11, precedence); design for where it is used.*
9. **The release branch's history is append-only.** A rebase, a force-push, or a re-import of that branch can lower the count below a build already uploaded, and a Mac app cannot recover from a lower build number. Whatever syncs commits into the branch merges them. *Basis: documented (the Mac rule in rule 4); design for the consequence.*
10. **A store build comes from the release branch, from a clean tree.** The release lane refuses any other branch and any uncommitted change to a tracked file, so the number leads back to one commit. *Basis: design.*
11. **A second upload of the same commit needs its own build number.** A commit count numbers commits, not uploads; App Store Connect requires each version and build pair to be unique. The dotted form (`42`, then `42.1`) is available because Apple allows up to three integers, but how App Store Connect orders `42.1` against `42` is **not established** here and is tried with one real upload before it is relied on. *Basis: documented for the uniqueness (Xcode Cloud, "unique combination of CFBundleShortVersionString and CFBundleVersion"); the ordering is **not established**.*
12. **The apps take the settings from the same place.** The release lane passes `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` to the build from one script that reads `VERSION` and git, so a project file's own `1.0` and `1` are never what ships. A plain run from the IDE shows the project file's values; that is a known limit, stated, not hidden. *Basis: design.*
13. **Bumping is one command that edits one file.** It validates the text by the grammar of rule 2 before writing, and it writes nothing else. *Basis: design.*
14. **In an Xcode app target the stamp is a post-build script phase.** Where the build is an Xcode project and not a package plugin, one script reads `VERSION` and the first-parent count (refusing a shallow clone, rule 6) and writes `CFBundleShortVersionString` and `CFBundleVersion` into the built product's `Info.plist`; user-script sandboxing is switched off for that target so the script can read git. The project's own `MARKETING_VERSION` stays a placeholder. *Basis: observed (the stamped values read back from the built app's plist); design for the choice.*

## How to test it

- **The parser against the specification.** Accept the specification's own valid examples and read each back as written; refuse each of its invalid forms (leading zeros, empty identifiers, missing parts, a leading `v`, whitespace, a number past `Int`); check the precedence chain `1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta < 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0` in every pair; check that `1.9.0 < 1.10.0` (numbers, not text); check that metadata takes no part in precedence but is part of equality.
- **The version type against the file.** A test reads `VERSION` and compares the core and the pre-release with the type's; it asks git for the first-parent count and requires the built number to be positive and no more than it.
- **The rule that builds the richer form, apart from the generated numbers.** Take it as a function of its inputs and hold it to its closed form: the release shape, the pre-release shape, the ordering of two builds of one beta, a pre-release below its release, the dirty mark, and that the text parses back to an equal value.
- **The generator's refusals.** Run the built tool against a shallow clone, a bad `VERSION`, a `VERSION` with metadata, a missing `VERSION`, a tree with no git and no variables, and a bad `APP_BUILD_NUMBER`; each must exit non-zero with a message that names the cause. Run it with both variables and no git; it must succeed.
- **Regeneration.** In a throwaway clone, build, make an empty commit, build again, and require the generated number to rise by one. This is the test that the plugin's inputs are named.

## Acceptance check

Run from the repository root. `VERSION` is the file; `SOURCES` is the directory of package sources. Every command must print nothing, except where it says it must print a line:

```sh
# 1. VERSION is one line and is a semantic version without build metadata
grep -Ex '(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-(0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*))*)?' VERSION | grep -c . | grep -vx 1

# 2. no Swift source states a version number by hand (a constant named major, minor, patch, sprint or build with an integer literal)
grep -rnE 'static (let|var) (major|minor|patch|sprint|build(Number)?)[^=]*=[[:space:]]*[0-9]+' "$SOURCES" --include='*.swift' | grep -v 'Generated'

# 3. the generator never falls back to a made-up count
grep -rnE 'return 1$' "$SOURCES"/*Generator* --include='*.swift'

# 4. the plugin names its inputs (this one must print a line)
grep -rn 'inputFiles' "$SOURCES"/../Plugins --include='*.swift'

# 5. CI fetches the full history (each of these must print a line where the file exists)
grep -n 'fetch-depth: 0' .github/workflows/*.yml 2>/dev/null
grep -n 'GIT_DEPTH: 0' .gitlab-ci.yml 2>/dev/null

# 6. the release build number equals the commit count of the commit built (prints the count; compare it to the build)
git rev-list --first-parent --count HEAD
```

Promote commands 1 to 3 to a build-failing script with a self-test (a fixture that breaks each must fail it; a fixture that obeys all must pass it), and the tests above to the project's test suite. The check passes when the commands print as stated, the tests pass, and rule 11 is either tried with an upload or stated as not tried.

Cross-references: `package-structure.md` (the plugin and its generator are their own targets), `dependency-injection.md` (the version type is read, never reached through a singleton), `testing.md` and `core/testing-discipline.md` (the tests and the regeneration check), `core/oracle-first.md` (the specification's examples are the answer key for the parser), `core/proof-discipline.md` (the basis of each claim), `core/git-discipline.md` (append-only history on the release branch).
