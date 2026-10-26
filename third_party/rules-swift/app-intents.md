# App Intents: one adapter, intents declared by package, every word a late-resolved localized resource

**Status: MANDATORY for every project that exposes actions to Siri, Shortcuts, Spotlight, or the Action button.** App Intents code lives in one adapter target and nothing else imports the framework. Each intent is thin: it builds one engine command from its parameters, asks an injected door, and reads the outcome. An intent that lives in a Swift package is declared by an `AppIntentsPackage`. Every string a person sees or hears is a localized resource that the system resolves late, never a `String` made inside `perform()`.

Each rule below carries its basis: **documented** (Apple documentation, named so it can be read) or **observed** (found by running the toolchain; it names the version, and it is re-checked when the toolchain changes).

## Why

- **The system, not the app, owns the moment of use.** The system creates an intent with no arguments, fills its parameters, and runs `perform()` in a process that may be an extension while the app is not running. Anything the intent needs must therefore be registered, not passed, and anything it says must still be translatable by a process that has other language preferences than the one that wrote it.
- **The framework is an adapter, not a layer.** App Intents is a way for the system to reach the app. The engine does not know it exists; the same command a button produces is the command an intent produces, so a test of the command covers both.
- **A package is not an app.** The compiler extracts intent metadata when it builds an app or extension target. Source that sits in a package is found only when the app or extension says it includes that package.

## Rules

1. **One adapter target.** `import AppIntents` appears in exactly one target, the adapter, and in the composition roots that register it. The engine, the models, and the protocols they share never import it. *Basis: project architecture (`package-architecture.md`, `package-import-contract.md`); the framework itself does not require it.*
2. **Each intent is the twin of one engine command.** The intent holds no logic of its own beyond turning parameters into a command (rejecting a value that is not possible, and telling the person) and turning the outcome into words. A test pairs every case of the engine's command enumeration with a twin or with a written classification (exposed, planned, internal, ineligible), with no `default:` in the switch, so a new command cannot be forgotten silently. *Basis: Oracle First (`core/oracle-first.md`): every case handled or classified.*
3. **Created without arguments; dependencies are registered.** The system instantiates an intent with `init()`, so an intent takes its collaborators from `@Dependency`, registered once with `AppDependencyManager` by the composition root of every process that can run an intent (the app and each extension). The dependency is one `Sendable` value that holds the door to the engine and nothing the intent could mutate. *Basis: documented (`AppIntent`, `AppDependencyManager`, `AppDependency`).*
4. **A test never resolves the dependency through the framework.** `perform()` forwards to an internal `perform(using:)` that takes the door as a parameter, and every test calls that one. *Basis: observed (Xcode 27, Swift 6.4): `@Dependency` outside the intent flow traps, so a test cannot read it.*
5. **An intent in a package is declared by a package type.** The adapter target declares a type that conforms to `AppIntentsPackage`; each app and each extension that uses the adapter declares its own `AppIntentsPackage` whose `includedPackages` lists it. A package whose intents are not included is silently absent from Shortcuts. *Basis: documented (`AppIntentsPackage`).*
6. **Every word is a localized resource.** The title, the description, each parameter title, each display representation of an enum or entity, each dialog, each error, each parameter summary, and each App Shortcut phrase and short title is localized, in the languages the product ships. English is the source language. *Basis: documented (`Adding parameters to an app intent`: "Always provide localized strings for app intents, App Shortcuts, and their parameters").*
7. **The bundle is named.** `LocalizedStringResource` and `String(localized:)` look in the main bundle unless told otherwise, and the main bundle is not the package. Every resource the adapter writes names the adapter's bundle (`.atURL(Bundle.module.bundleURL)`), through one helper, so no call site can forget. *Basis: documented (`LocalizedStringResource`, `#bundle` proposal: code in a framework or package must specify the bundle).*
8. **Late resolution.** What the system shows or speaks is handed over as a `LocalizedStringResource`, not as a `String`: `IntentDialog(_:)` and `IntentDialog(full:supporting:)` take resources, and an error conforms to `CustomLocalizedStringResourceConvertible`. The system resolves it in the language of the surface that shows it, which can differ from the app's. `IntentDialog(stringLiteral:)` of a string built in `perform()` is a violation. *Basis: documented (`LocalizedStringResource`: "App Intents ... late resolution ... the Siri UI to potentially use different localization preferences").*
9. **A sentence with interpolation keeps its plural forms.** Build the resource from a `String.LocalizationValue` and the bundle with `LocalizedStringResource(_:table:locale:bundle:comment:)`; the key is the format with its placeholders (`%lld new messages.`), and the catalog holds one plural variation per form of each language: one and other in English and German, one, few and other in Croatian. Never write "item(s)" and never decide a singular in Swift. *Basis: documented (initializer); the key derivation and the plural forms **observed**.*
10. **A sentence is one key.** A clause that is sometimes present is its own whole sentence with its own key, chosen in Swift, and not a translated fragment appended to another: word order, agreement, and punctuation differ between languages. Where one sentence holds several numbers, the translation may read them as a label and a number, or use substitutions, so that no noun has to agree with a count it is not next to. *Basis: localization practice for string catalogs; the plural substitutions **observed**.*
11. **Limits are checked once, in the adapter, and told.** A value outside what a command may take is a failure the person reads, never a value the engine is left to refuse. Constants an attribute needs (a range) must be literals in the attribute; keep one source and a test that the literal equals it. *Basis: observed for the literal requirement; the rest is the thin-intent rule.*
12. **A restricted choice is an `AppEnum` or an entity with a query.** An enum is `String`-backed and `RawRepresentable`; a finite list is never a free `String` parameter. An entity names only what a person already sees and carries no content of a message. *Basis: documented (`AppEnum`, `AppEntity`).*
13. **`perform()` is concurrency-safe by construction.** The system runs it on an arbitrary queue and an `AppIntent` is `Sendable`; work that touches UI is marked `@MainActor`, and the intent holds no mutable state. *Basis: documented (`Creating your first app intent`, `AppIntent`).*
14. **Phrases name the app.** Each `AppShortcutsProvider` phrase contains `\(.applicationName)`, and the phrases are localized in the file Apple's sample uses for them (`AppShortcuts.strings`, in the app bundle). *Basis: documented (`AppShortcutsProvider` sample); where the file lives for a package is **not** established and is checked on a device.*
15. **Metadata is proved where it is made.** A passing unit test proves the words and the command, not that Shortcuts lists the intent in each language. The proof is a build of the app or extension, then the steps of the Apple guide (Shortcuts, Apps, the app's icon, run), repeated with the device set to each shipped language. Until that is done, the claim is "tested at the reading level, not seen in Shortcuts". *Basis: documented (`Creating your first app intent`: the compiler generates the metadata when an app that contains intents is built).*

## How to test the words

- **Resolve in a language by setting `locale` on a copy of the resource** (`var r = resource; r.locale = Locale(identifier: "hr"); String(localized: r)`). That is the documented way and it picks the language. `String(localized:bundle:locale:)` does **not**: the `locale` there formats numbers while the process's languages choose the strings (observed), so a test that uses it reads the machine's language.
- **Key sets agree.** A test reads the catalog from disk and the sources, and fails when a sentence in the sources has no entry or an entry is asked for by no source. The scan accepts both `LocalizedStringResource(` and `.init(` and a literal wrapped over lines, since the formatter changes the layout.
- **Each key is complete.** Every key has every shipped language, every localization is non-empty, and the arguments a translation reads are exactly the key's (`%1$lld` positions and plural substitutions counted).
- **Plural forms are those of the language.** Check the set of categories per language, and spell out expected text for counts that fall in each Croatian category (0, 1, 2, 4, 5, 11, 12, 21, 22, 25, 101), since a wrong category reads as correct English to a reviewer who does not read the language.
- **The language asked for is the one read.** Assert that a language the catalog lacks reads as the source language, and that a locale with a region override reads the language of its tag, so a test passes on any machine.
- **Mutations.** Mutate the language choice, a plural form of the catalog, and the point where a reading ignores its locale, and require the tests to fail (`core/testing-discipline.md`).

## Acceptance check

Run from the repository root, with `ADAPTER` the adapter target's source directory and `SOURCES` the directory of all package sources. Every command must print nothing, except check 2, which must print at least one line:

```sh
# 1. the framework is imported only by the adapter
grep -rlE '^[[:space:]]*import AppIntents' "$SOURCES" --include='*.swift' | grep -v "^$ADAPTER/"

# 2. the adapter declares an AppIntentsPackage (this one must print a line)
grep -rnE ':[[:space:]]*AppIntentsPackage' "$ADAPTER" --include='*.swift'

# 3. no title, description, or parameter title is a bare literal (each must name the bundle)
grep -rnE 'static (let|var) (title|description)[^=]*=[[:space:]]*(IntentDescription\()?"' "$ADAPTER" --include='*.swift'
grep -rnE '@Parameter\(title:[[:space:]]*"' "$ADAPTER" --include='*.swift'

# 4. no dialog is made from a String
grep -rnE 'IntentDialog\(stringLiteral:' "$ADAPTER" --include='*.swift'

# 5. no sentence is resolved to a String inside the adapter's intents
grep -rnE 'String\(localized:' "$ADAPTER" --include='*Intent.swift'
```

Promote the five commands to a build-failing script with a self-test (a fixture that breaks each one must fail it; a fixture that obeys all must pass it), and the key-set, completeness, and plural tests above to the project's test suite. The check passes when the commands print as stated, the tests pass, and rule 15 is either done or stated as not done.

Cross-references: `package-architecture.md` and `package-import-contract.md` (one adapter, one import), `dependency-injection.md` (the door is injected, nothing is a singleton), `testing.md` and `core/testing-discipline.md` (tests and mutations), `concurrency.md` (`Sendable` and `@MainActor`), `core/oracle-first.md` (every command is a twin or classified), `core/proof-discipline.md` (the basis of each claim).
