//
//  AppUIAccessibilityActionsTests.swift
//  AppUIKitTests
//

import Testing
@testable import AppUIKit

@Suite("AppUIKit accessibility value, hint and actions")
@MainActor
struct AppUIAccessibilityActionsTests {
    @Test("Label, value and hint read back what was set")
    func labelValueHint() {
        let view = AppUIView()
        view.setAXLabel("Divider between A and B")
        view.setAXValue("40 percent")
        view.setAXHint("Swipe up or down to resize the panes")
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            #expect(view.accessibilityLabel() == "Divider between A and B")
            #expect(view.accessibilityValue() as? String == "40 percent")
            #expect(view.accessibilityHelp() == "Swipe up or down to resize the panes")
        #elseif canImport(UIKit)
            #expect(view.accessibilityLabel == "Divider between A and B")
            #expect(view.accessibilityValue == "40 percent")
            #expect(view.accessibilityHint == "Swipe up or down to resize the panes")
        #endif
    }

    @Test("Custom actions keep their names and order, and each runs its handler")
    func actions() {
        let view = AppUIView()
        var ran: [String] = []
        view.setAXActions([
            AppUIAccessibilityAction(name: "Maximize pane") { ran.append("maximize") },
            AppUIAccessibilityAction(name: "Swap with B") { ran.append("swap") },
        ])
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let actions = view.accessibilityCustomActions() ?? []
            #expect(actions.map(\.name) == ["Maximize pane", "Swap with B"])
            for action in actions {
                _ = action.handler?()
            }
        #elseif canImport(UIKit)
            let actions = view.accessibilityCustomActions ?? []
            #expect(actions.map(\.name) == ["Maximize pane", "Swap with B"])
            for action in actions {
                _ = action.actionHandler?(action)
            }
        #endif
        #expect(ran == ["maximize", "swap"])
    }

    @Test("Setting no actions clears them")
    func clearing() {
        let view = AppUIView()
        view.setAXActions([AppUIAccessibilityAction(name: "A") {}])
        view.setAXActions([])
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            #expect((view.accessibilityCustomActions() ?? []).isEmpty)
        #elseif canImport(UIKit)
            #expect((view.accessibilityCustomActions ?? []).isEmpty)
        #endif
    }
}
