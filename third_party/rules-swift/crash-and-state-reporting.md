# Crash and state reporting: MetricKit and StateReporting, joined to the app's own log

**Status: MANDATORY for every app that has the log of `app-logging.md`.** The app asks the system for what it knows about its crashes and hangs (MetricKit), tells the system what state it is in (StateReporting), and brings both into its own log and its reports, so a crash is read next to what the person did before it.

Each rule carries its basis: **documented**, **observed**, or **design**. Where a claim about Apple's new frameworks was read from the documentation and not run, it says so.

## Why

- **A crash takes the log's last seconds with it.** The system's report has the stack and the process; the app's log has the intents. Neither is enough alone.
- **The system can say which state the app was in.** A crash that says "while reading a report in the log viewer" is triaged in seconds; one that says nothing is not.
- **The system delivers when it chooses.** An app cannot count on a crash arriving soon, so a second, local door is needed.

## Rules

1. **Use the system's frameworks where they exist, guarded.** MetricKit's `MetricManager` and its diagnostic reports, and the `StateReporting` framework, are used behind `#if canImport(...)` and `#available(macOS 27, iOS 27, macCatalyst 27, *)`; the deployment target stays where the app's rule sets it, and nothing happens before those releases. Building them needs the SDK that has them. *Basis: documented (Apple, MetricKit and StateReporting, 2026); the deployment guard is design.*
2. **MetricKit is delivered on a device and when the system chooses.** Subscribe at launch, read the crash diagnostics of an earlier run, and treat the first delivery as late. On the Simulator, and in the test of one Mac in this repository's history, nothing arrived within three minutes. *Basis: observed (no delivery within three minutes on a Mac) and documented (delivery is the system's); a claim that MetricKit "reports crashes promptly" is **not established**.*
3. **A second door on macOS: the system's crash reports for the app.** On a Mac, the crash reports in `~/Library/Logs/DiagnosticReports` (`.ips`) for the app are read at launch, within a bounded age (three days here), the newest alone prompting. *Basis: observed.*
4. **One crash seen through both doors is one crash.** Merge by process id within a window of minutes (five here). The merge is tested, including that a report older than the age bound is not read. *Basis: design; a regression that dropped the age check was caught by this test.*
5. **A kept crash is data for the next report, never for the log's fields.** The crash is stored beside the log (the newest twenty). The log gets `crash.diagnosed` with the signal, the reason and the version, and never the call stack. The system's report, which holds stacks and paths that can name the person's account, goes only into a report the person chooses to send, and a crash a report has taken is not put in the next. *Basis: design.*
6. **The prompt is the person's.** At launch, in a Debug or Beta build, a recent crash opens the report flow with the note "The app crashed recently." for the person to add to or leave. It never sends. *Basis: design.*
7. **The app reports its state.** One reporter per app (`AppStateReporter`) tells the system a label and facts of the app: which screen, which example, which target, whether a report is open. Never a fact of what the person works on. Where a state is a tab or a mode, the change is reported at the one place that changes it. *Basis: documented (StateReporting reports app state to the system); design for the facts allowed.*
8. **The domain is told to MetricKit, and the states come back.** The domain of the reporter is given when the crash watch starts, so the system's report names the states active just before the crash; the kept crash copies them to the log as `states`. *Basis: documented that diagnostic reports carry environment states; the end-to-end return on a real crash of an app built with the new SDK is **not established** here until witnessed.*
9. **Witness it on a real crash.** The doors are held by tests on fixtures, and by one real crash of a built app: crash it, relaunch it, and require `crash.diagnosed` in the log and the crash in the next report. *Basis: design.*

## How to test it

- **Fixtures for the `.ips` reader.** A report of the app, a report of another app, one older than the bound, one cut short, and one in the future; each is read or refused as the rule says.
- **The merge.** The same crash through both doors gives one record; two crashes of two processes give two.
- **The store.** The newest twenty are kept; a crash taken by a report is marked and not offered again.
- **The log never holds the stack.** Feed a crash with a stack and require no field of `crash.diagnosed` to contain a frame.
- **A real crash.** Crash a built Debug app, relaunch, and read the log and the report.

## Acceptance check

Run from the repository root; `SOURCES` is the directory of package sources. Each command must print nothing unless it says it must print a line:

```sh
# 1. the new frameworks are only imported behind canImport
grep -rnE '^[[:space:]]*import (MetricKit|StateReporting)' "$SOURCES" --include='*.swift' | while IFS=: read -r f n _; do sed -n "$((n-1))p" "$f" | grep -q 'canImport' || echo "$f:$n"; done

# 2. every use is behind an availability check
grep -rnE 'MetricManager|StateReporter' "$SOURCES" --include='*.swift' | grep -v -E 'available|canImport|///|//'

# 3. the crash record has no field for a call stack in the log (must print nothing)
grep -rnE 'callStack|stackTrace|frames' "$SOURCES"/*Logging* "$SOURCES"/BugReporting --include='*.swift' | grep -v -E 'Tests/'

# 4. each app starts the crash watch (each app must print a line)
grep -rn 'watchForCrashes' "$SOURCES" --include='*.swift'
```

Command 4 is read against the list of apps; a missing app is a named row, as in `app-logging.md` rule 12.

Cross-references: `app-logging.md` (the log and the report these join), `cross-platform.md` (the availability and `canImport` patterns), `testing.md`, `core/proof-discipline.md` (rules 2 and 8 are stated at the strength they were shown), `core/testing-discipline.md`.
