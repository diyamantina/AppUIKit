import Testing
@testable import AppUIKit

/// The context menu a shared canvas is written against: the sections are asked for when the menu opens, separators divide them, an off entry is off, and choosing an entry runs its
/// action (AppKit; UIKit builds its menu for the system to show).
@MainActor
@Suite("AppUIKit context menu")
struct AppUIContextMenuTests {
    @Test func `the menu is built from the sections each time it opens, with a separator between sections, and choosing an item runs its action`() throws {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let view = AppUIView()
            var pressed: [String] = []
            var second = true
            view.appuiSetContextMenu {
                var sections = [[
                    AppUIContextEntry(title: "One", symbol: "trash") { pressed.append("one") },
                    AppUIContextEntry(title: "Two", isEnabled: false) { pressed.append("two") },
                ]]
                if second {
                    sections.append([AppUIContextEntry(title: "Three") { pressed.append("three") }])
                }
                return sections
            }
            let menu = try #require(view.menu)
            let delegate = try #require(menu.delegate)
            delegate.menuNeedsUpdate?(menu)
            #expect(menu.items.map(\.title) == ["One", "Two", "", "Three"] && menu.items[2].isSeparatorItem)
            #expect(menu.items[0].isEnabled && !menu.items[1].isEnabled && menu.items[0].image != nil)
            _ = menu.items[2].target
            let first = menu.items[0]
            _ = first.target?.perform(first.action, with: first)
            #expect(pressed == ["one"])
            second = false
            delegate.menuNeedsUpdate?(menu)
            #expect(menu.items.map(\.title) == ["One", "Two"], "the state of the moment: the sections are asked for again")
        #else
            let view = AppUIView()
            view.appuiSetContextMenu { [[AppUIContextEntry(title: "One") {}]] }
            #expect(view.interactions.contains { $0 is UIContextMenuInteraction })
        #endif
    }
}

/// The menu of a button: asked for each time it opens, and a flag that says whether a plain press opens it (the tool flyouts of SlayerDraw). A press that opens the menu is not
/// tested through a
/// modal pop-up; the flag and the menu are what the owner reads.
@MainActor
@Suite("AppUIKit button menu")
struct AppUIButtonMenuTests {
    @Test func `a button menu is built when it opens, and the flag says whether a press opens it`() throws {
        let button = AppUIButton()
        var titles = ["One", "Two"]
        button.appuiSetMenu(opensOnPress: true) { [titles.map { AppUIContextEntry(title: $0) {} }] }
        #expect(button.appuiMenuOpensOnPress)
        button.appuiMenuOpensOnPress = false
        #expect(!button.appuiMenuOpensOnPress)
        button.appuiSetMenu { [titles.map { AppUIContextEntry(title: $0) {} }] }
        #expect(!button.appuiMenuOpensOnPress, "the default is a menu from the secondary click or the long press only")
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let menu = try #require(button.menu)
            let delegate = try #require(menu.delegate)
            delegate.menuNeedsUpdate?(menu)
            #expect(menu.items.map(\.title) == ["One", "Two"])
            titles = ["Three"]
            delegate.menuNeedsUpdate?(menu)
            #expect(menu.items.map(\.title) == ["Three"], "asked for again each time")
        #else
            #expect(button.menu != nil)
        #endif
    }

    @Test func `the image colour of a button reads back`() {
        let button = AppUIButton()
        button.appuiContentTintColor = .red
        #expect(button.appuiContentTintColor == .red)
    }
}

@MainActor
@Suite("AppUIKit button content insets")
struct AppUIButtonInsetsTests {
    @Test func `a borderless button has its padding taken out`() {
        let button = AppUIButton()
        button.appuiMakeBorderless()
        button.appuiRemoveContentInsets()
        #if canImport(UIKit) && !(canImport(AppKit) && !targetEnvironment(macCatalyst))
            #expect(button.configuration?.contentInsets == .zero)
        #else
            #expect(button.isBordered == false)
        #endif
    }
}
