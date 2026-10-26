# App logging: every app writes a structured log, and can turn a moment of it into a report

**Status: MANDATORY for every app that ships.** An app records what it does as structured entries (names, numbers and categories, never what the person is working on), through one recorder given to it, and has a Developer menu that turns the log around a moment into a report the person may send. The menu exists in a Debug build and a Beta build and not in a Release build.

Each rule carries its basis: **documented** (Apple documentation, named), **observed** (found by running it), or **design** (a choice, with the reason).

## Why

- **A bug that cannot be reproduced can still be read.** A log of intents and state changes, with the version of the build, says what the app did before the moment someone marked.
- **A log that holds the person's work is a leak.** The log is kept on disk and put in reports; what the person typed or pasted must never be in it.
- **A report that is not the person's choice is surveillance.** Nothing is sent by the app; the person reads the message and presses Send.

## Rules

1. **One recorder, given.** An app makes its recorder once, at its composition root, and hands it to what logs. No global logger, no singleton (`dependency-injection.md`). A test run gets a recorder that writes nowhere. *Basis: design.*
2. **Entries are facts, not content.** An entry has a category, a name, a level, an outcome and fields of numbers, booleans and short names. A field never holds text the person wrote, pasted, or opened; a failure's reason is cut to its first line and a bounded length, and what it quotes between quotes is replaced. A fingerprint (a hash) of the content may stand for it. *Basis: design; the reason quoted text is cut is that a compiler or parser message quotes its input.*
3. **Every intent and every change of state is an entry.** What a person does (selection, edit, toggle, command) and what the app then is (loading, done, failed) are written at the one place that makes the change, so the log is complete without each view remembering to log. *Basis: design.*
4. **Spans for work that takes time.** Work with a start and an end writes both with its duration and its outcome, and a failure says why. *Basis: design.*
5. **The log names the build.** The first entry of a run carries the version of the build in the form `versioning.md` rule 8 gives, so a report says which build it came from. *Basis: design.*
6. **It can be switched off by the person, and is on by default.** A defaults key (`-<App>Logging NO`) turns it off. *Basis: design.*
7. **The Developer menu is gated in the one file that starts the app.** `#if DEBUG || BETA` sets a flag in the app target's entry file and hands it to the coordinator; package code never reads the compile flag. The project has a `Beta` configuration (Release settings and the `BETA` condition) and the scheme archives with it. A Release build must not contain the menu. *Basis: design; verify it on a built app, not on the code (see the check).*
8. **A report is made on the person's request, for any reason.** The menu item is "Send a Report…", not "Report a crash": a slow moment, a wrong picture or a bug is as good a reason. It takes a note, offers what else may go in, and makes a zip. *Basis: design.*
9. **A report holds the log around the mark and facts of the window.** The log window is a bounded count of entries before the mark and all after it; the snapshot is counts, switches and fingerprints. Whatever else (the pasted source, the layers of the app being read, the log being read) is **content**: off by default, named to the person in the app's words, and in the report only when chosen. A content file cannot take a name the report keeps for itself or leave the report's folder. *Basis: design.*
10. **The report is kept, and is mailed only on the person's choice.** The zip is kept beside the log (the newest twenty), so it can be sent later. "Open Email" opens a new message in the person's mail app with the zip attached and the note in the body; without a mail account the file is offered for sharing. The app sends nothing. *Basis: documented (Apple, the system's mail compose and share interfaces) for the means; design for the choice.*
11. **The viewer is the same format.** The tool that reads logs and reports reads this log, refuses a report that holds a link or a path that leaves its folder, and shows the marks. An older viewer refusing a newer category is stated, so viewer and apps ship from one release. *Basis: observed (an older viewer refused the `bug` category).*
12. **Every app, not most.** Each app of a repository has the log, the menu and the report, or its absence is a named row in the repository's audit with the reason (a test fixture app is one). *Basis: design.*

## How to test it

- **The log is held to the model.** Drive the model through every intent and require an entry for each, and no field of any entry equal to, or containing, the content the test fed it.
- **The window of a report against its closed form.** For a log of known length and a mark at a known place, the report holds exactly the entries before and after that the rule states.
- **A whole report, from the mark to the zip, read back.** Unpack it with the viewer's reader and require the mark, the snapshot, the README, and the content only when asked for.
- **The menu in a built app.** Build Debug, Beta and Release; open the app and read its menu bar through the accessibility interface of that one process. Debug and Beta have the Developer menu; Release does not.
- **The questions with a stand-in for the screen.** A scripted asker answers each question in turn so the order and the refusals (no mail account, a cancelled sheet) are tested without a window.

## Acceptance check

Run from the repository root. `SOURCES` is the directory of package sources, `APPS` the app targets. Each command must print nothing unless it says it must print a line:

```sh
# 1. the compile flag is read only in the app targets, never in package code
grep -rnE '#if.*(DEBUG|BETA)' "$SOURCES" --include='*.swift' | grep -v -E 'Tests/|#if (DEBUG|BETA).*(canImport|os\()'

# 2. every app entry file gates the menu (each app must print a line)
for f in $(grep -rlE '@main' "$APPS" --include='*.swift'); do grep -Ln 'DEBUG || BETA' "$f"; done

# 3. a Beta configuration exists in each project (must print a line per project)
grep -n 'BETA' "$APPS"/*/project.yml

# 4. no singleton recorder
grep -rnE 'static (let|var) (shared|default|current)[^=]*(Recorder|Logger)' "$SOURCES" --include='*.swift'

# 5. the Release build has no Developer menu (prints the menu titles of the built app; "Developer" must not appear)
# build -configuration Release, launch, then read the menu bar of that process through the accessibility interface
```

Command 5 is run on a built app, once per release, and its result is recorded in the release notes. Promote 1 to 4 to a build-failing script with a self-test.

Cross-references: `versioning.md` (the version the log names), `crash-and-state-reporting.md` (the crashes and states the log also holds), `dependency-injection.md` (the recorder is given), `testing.md`, `core/oracle-first.md` (the window's closed form), `core/proof-discipline.md` (the basis of each claim), `ui/appuikit.md` (the questions and the mail go through AppUIKit).
