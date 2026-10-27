# Help: one file of words, a Help Book on the Mac, in-app help and a Settings page on an iPad and an iPhone, tips where the work is

**Status: MANDATORY for every app that ships to people.** An app's help is written once, in one file, and every platform's help is made from that file: a Help Book on the Mac, an in-app help sheet and a page in the Settings app on an iPad and an iPhone, and a few tips (TipKit) at the places a person first needs them. Each platform says it in its own words, because a Mac is clicked and a phone is touched. The About page says the name and the version the build stamped (`versioning.md`).

Each rule below carries its basis: **documented** (Apple documentation or the Human Interface Guidelines, named so it can be read), **observed** (found by building and running it), or **design** (a choice, with the reason). Where the Apple document is not in the Cupertino corpus the basis says so, and the claim rests on what was observed.

## Why

- **Help kept in several places says different things.** A Help Book, an in-app list and a web page written by hand disagree within a release. One file has nothing to disagree with.
- **A platform's help in another platform's words is wrong for the reader.** The Human Interface Guidelines say help must not tell people to click a button on an iPhone or tap a menu item on a Mac. A reader who is told to hold Command on a phone stops reading.
- **Each platform has its own place for help, and people look there.** A Mac has a Help menu with a search field; an iPad with a keyboard has the same menu bar; a phone has no menu bar, so help sits in the app and the version in the Settings app. Putting help where the platform puts it is what makes it found.
- **A tip is for the moment of need, a page is for looking up.** The two do different work and neither replaces the other.

## Rules

1. **One source of the words: a JSON file in the package that owns the editor.** `Resources/Help.json` holds the topics (`id`, `title`, `symbol`, and either `text` for every platform or `mac` and `touch` for a topic the platforms say differently) and the keys of the Mac. The file is a resource of the package; the in-app help decodes it, and the Help Book is made from it by a script. No topic is written as a string in Swift. A damaged file is refused when it is decoded, and the in-app help says so; it never shows an empty help. *Basis: design.*
2. **Each platform is told in its own words.** The words are chosen for the platform the help is read on: the Mac's help says click, Command, the File menu and a window; a touch screen's says tap, touch, the list of files and the Files app. A touch screen's help has no list of keyboard keys. *Basis: documented (Human Interface Guidelines, Offering help: "don't write copy that tells people to click a button on an iPhone or tap a menu item on a Mac").*
3. **The Mac carries an Apple Help Book, and the system makes the Help menu from it.** The app's `Info.plist` names the book with `CFBundleHelpBookFolder` (the folder, `<App>.help`) and `CFBundleHelpBookName` (the book's own bundle identifier). The book is a folder in the app's resources. An app that carries a book does not replace the Help menu: a SwiftUI `CommandGroup(replacing: .help)` is only for an app that has none, and the check for the keys decides which. The system's menu has the search field and the item that opens the help viewer. *Basis: observed (macOS 26, SwiftUI: with the two keys set and no replacing group, the Help menu showed "<App> Help", the item opened the system's help window with its search field and the book's access page; with a replacing group the system's window did not open). The Help Book format is described in Apple's Help Programming Guide, which is not in the Cupertino corpus.*
4. **The Help Book has the structure the viewer reads.** `<App>.help/Contents/Info.plist` has `CFBundleIdentifier` (equal to `CFBundleHelpBookName` of the app), `CFBundleName`, `CFBundlePackageType` `BNDL`, `CFBundleSignature` `hbwr`, `HPDBookType` `3`, `HPDBookTitle`, `HPDBookAccessPath` (the access page), `HPDBookIndexPath`, `HPDBookCSIndexPath` and `HPDBookKBProduct`. `Contents/Resources/<lang>.lproj/` holds the access page, a page for each topic in `pgs/`, the shared style in `shrd/`, and the two search indexes. Each page has `<meta name="AppleTitle">`, `description`, `keywords` and `robots` `anchors`. The indexes are made by `hiutil -Caf <name>.helpindex <lang>.lproj` and `hiutil -I corespotlight -Caf <name>.cshelpindex <lang>.lproj`. The style follows the system's colors and appearance (`color-scheme: light dark`). *Basis: observed (the book built this way opened in the system's help window, with its topics, its pages, its search field, and in dark appearance).*
5. **The Help Book is generated from the file, and committed.** One script writes the book from `Help.json`; `--check` regenerates it into a throwaway folder and compares it with the committed book, leaving out the two index files, which hold times. A build needs nothing outside its repository, and a change of the words that is not carried into the book fails the gate. *Basis: design.*
6. **The book's own files are named in lowercase, as `file-naming.md` asks.** The names are free in the book's `Info.plist`, so the access page and the indexes are `<app>.html`, `<app>.helpindex` and `<app>.cshelpindex`. The names a tool expects verbatim (`Info.plist`, and `Root.plist` of a Settings bundle) are exempt in the file-name gate, by name. *Basis: design; documented for the exempt names (Apple, Settings bundle: the main file is `Root.plist`).*
7. **An iPad and an iPhone have no Help Book; their help is an in-app page, in the places the platform has.** The page is the list of the same topics, in the touch words, in a sheet with a Done button. It is opened from a Help menu of its own in the toolbar (not from inside View), and, on an iPad, from the menu bar as well: About in the app menu and Help in the Help menu, which a keyboard reveals. A phone has no menu bar, so the toolbar is its place. *Basis: documented for the menu bar (Human Interface Guidelines, The menu bar: menu bar menus on iPad are similar to those on Mac and appear in the same order); design for the sheet and the toolbar.*
8. **About says the name and the version, in the app menu of the Mac.** It shows the display name, the version and the build number as the build stamped them into the `Info.plist` (`versioning.md`), and the richer form for bug reports, small. It never holds a version written by hand. *Basis: design; documented for the place (the Mac's app menu, Human Interface Guidelines, The menu bar).*
9. **The Settings app shows the version, from a Settings bundle.** An iPad and an iPhone app carry `Settings.bundle` with `Root.plist`: a group "About" and read-only title rows (`PSTitleValueSpecifier`, `Key` the defaults key) for the version and the build. The Settings app reads the rows from the app's defaults, so the app writes the two values to its defaults each time it starts, from the stamped `Info.plist`. The strings file is named by `StringsTable` (lowercase, `root`). *Basis: documented (Apple, Building a Settings bundle for your app: the title element "displays a read-only version of the setting's name and its currently configured value", read from the app's defaults database); observed (the values were in the app's defaults after a launch).*
10. **Tips are for the first thing to do, and go when it is done.** A tip is a TipKit `Tip` with a rule that stops it once its feature has been used (a `@Parameter` set by the feature), shown inline where the thing is (`TipView`) and never over the work. TipKit is configured once, at launch, and a failure to configure is logged with its reason, not swallowed: without its store, tips are not shown, and nothing else changes. A tip never holds what the help does not also say. *Basis: documented (TipKit, iOS 17 and macOS 14; Human Interface Guidelines, Offering help: help is related to the task people are doing and easy to dismiss).*
11. **The help is words, not pictures of the interface, until the interface is stable.** A picture of a screen is a second source that is not generated. A topic names the control and says where it is. *Basis: design.*
12. **Language.** The help is in one language until a second is shipped; then each language has its own `<lang>.lproj` in the Help Book and its own text in the file, and the check of rule 5 covers all of them. A claim that the help is localized is made only with the files for the language present. *Basis: design; not established here (no second language has been shipped).*

## How to test it

- **The file against its rules.** Decode the bundled file in a test: topics and keys are present; every `id` and `title` is unique and not empty; every topic says something on the Mac and on a touch screen; a damaged file (empty, wrong shape, not JSON) is refused with an error and never read as empty help.
- **The words against the platforms.** Join the Mac's words and the touch words of all topics and require that the Mac's contain none of `tap`, `touch`, `files app`, `open in`, and the touch words none of `click`, `command `, `file menu`. Run it on the Mac and on a simulator, so each platform is checked in its own build. Require one anchor phrase each (`command and click`, `tap it`) so that a test of absence cannot pass on an empty text.
- **The check for a book, as a function of the plist.** Require `true` for both keys set and not empty and `false` for each of: only one key, an empty value, none.
- **The book against the file.** Run the script's `--check`; it must say the book is current. Change a word in the file and require that it fails and names the difference.
- **The Mac's menu in a built app.** Build and open the app; read its menu bar through the accessibility interface of that one process (`System Events`, the process, `menu "Help"`): the item "<App> Help" is there; click it and require that the system's help window opens (it belongs to the system's help viewer, whose process is not the app's), and look at the window: the access page, its topics, the search field. Never scan the windows of other processes.
- **The sheets on a simulator.** A UI test opens the Help menu of the toolbar, reads the About page (the version matches `^Version \d+\.\d+\.\d+ \(\d+\)$` and the richer form contains `+`), closes it with Done, opens the help and finds a topic.
- **The tip.** A UI test finds the tip, performs the thing it points at, and requires that the tip is gone.
- **The Settings page.** After a launch the app's defaults hold the version and build keys; the built app contains `Settings.bundle`.

## Acceptance check

Run from the repository root. `HELP_JSON` is the file, `BOOK` the committed book, `APP` a built app (Mac) and `IOSAPP` a built app of an iPad or iPhone target. Every command must print nothing, except where it says it must print a line:

```sh
# 1. the file is valid JSON and every topic has an id, a title, a symbol, and a text for each platform
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); [sys.exit("bad topic %s" % t.get("id")) for t in d["topics"] if not (t.get("id") and t.get("title") and t.get("symbol") and (t.get("text") or (t.get("mac") and t.get("touch"))))]' "$HELP_JSON"

# 2. no Swift source holds a topic as a string (the words live in the file only)
grep -rnE 'Topic\(\s*title:' "$SOURCES" --include='*.swift'

# 3. the committed Help Book is the one the file makes (prints "help book is current")
sh scripts/build-help-book.sh --check

# 4. the book has its plist, its pages and both indexes
test -s "$BOOK/Contents/Info.plist" && test -s "$BOOK"/Contents/Resources/*.lproj/*.helpindex && test -s "$BOOK"/Contents/Resources/*.lproj/*.cshelpindex || echo "book is incomplete"

# 5. the book's files are lowercase (the C locale, or a UTF-8 locale reads [A-Z] as both cases)
LC_ALL=C find "$BOOK/Contents/Resources" -type f -name '*[A-Z]*' -print

# 6. the built Mac app names its book and carries it (this must print two lines and the folder)
plutil -extract CFBundleHelpBookFolder raw "$APP/Contents/Info.plist"; plutil -extract CFBundleHelpBookName raw "$APP/Contents/Info.plist"; ls -d "$APP"/Contents/Resources/*.help

# 7. the book's own identifier is the name the app gives (the two lines must be equal)
plutil -extract CFBundleHelpBookName raw "$APP/Contents/Info.plist"; plutil -extract CFBundleIdentifier raw "$APP"/Contents/Resources/*.help/Contents/Info.plist

# 8. an iPad or iPhone app carries a Settings bundle with a Root.plist
test -s "$IOSAPP/Settings.bundle/Root.plist" || echo "no Settings bundle"

# 9. help words are not hard-coded for one platform in the sheets: no 'click' in the touch words of the file
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); [print(t["id"]) for t in d["topics"] if "click" in (t.get("touch") or t.get("text") or "").lower()]' "$HELP_JSON"
```

Promote commands 1 to 5 and 9 to a build-failing script with a self-test (a fixture that breaks each must fail it; a fixture that obeys all must pass it), and the tests above to the project's test suite. The check passes when the commands print as stated, the tests pass, the Mac's help window has been opened from the menu of a built app, and rule 12 is stated as not established until a second language ships.

Cross-references: `versioning.md` (the version the About page and the Settings page show, stamped into the `Info.plist`), `core/file-naming.md` (the lowercase names of the book's files), `ui/appuikit.md` and `package-structure.md` (the help view is in the presentation package, the words in its resources), `testing.md` and `core/testing-discipline.md` (the tests), `core/oracle-first.md` (the file is the answer key for the book and the in-app help), `core/proof-discipline.md` (the basis of each claim), `app-logging.md` (a tip that cannot start is logged).
