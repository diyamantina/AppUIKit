// AppUIKit.AccessibilityActions.swift
// AppUIKit
//
// Cross-framework accessibility value, hint and custom actions, so call sites do not need per-platform branches.

import Foundation

/// A named thing a user can do to a view without a pointer: the alternative to a gesture (a drag, a swipe) for VoiceOver, Switch Control, Voice Control and the keyboard.
public struct AppUIAccessibilityAction {
    public let name: String
    public let handler: @MainActor () -> Void

    public init(name: String, handler: @escaping @MainActor () -> Void) {
        self.name = name
        self.handler = handler
    }
}

public extension AppUIView {
    /// Set the accessibility value uniformly across AppKit and UIKit: the state the label does not carry ("40 percent", "2 of 3").
    func setAXValue(_ value: String) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            setAccessibilityValue(value)
        #elseif canImport(UIKit)
            accessibilityValue = value
        #endif
    }

    /// Set the accessibility hint uniformly across AppKit (`help`) and UIKit (`accessibilityHint`): what activating the view does.
    func setAXHint(_ hint: String) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            setAccessibilityHelp(hint)
        #elseif canImport(UIKit)
            accessibilityHint = hint
        #endif
    }

    /// Replace the view's custom accessibility actions uniformly across AppKit and UIKit. The view must be an accessibility element (a label, a button) to offer them.
    func setAXActions(_ actions: [AppUIAccessibilityAction]) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            setAccessibilityCustomActions(actions.map { action in
                NSAccessibilityCustomAction(name: action.name) {
                    MainActor.assumeIsolated { action.handler() }
                    return true
                }
            })
        #elseif canImport(UIKit)
            accessibilityCustomActions = actions.map { action in
                UIAccessibilityCustomAction(name: action.name) { _ in
                    MainActor.assumeIsolated { action.handler() }
                    return true
                }
            }
        #endif
    }

    /// Have VoiceOver speak `text` without moving focus, uniformly across AppKit and UIKit: the way to say that a layout changed.
    func postAXAnnouncement(_ text: String) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            NSAccessibility.post(
                element: self,
                notification: .announcementRequested,
                userInfo: [.announcement: text, .priority: NSAccessibilityPriorityLevel.high.rawValue]
            )
        #elseif canImport(UIKit)
            UIAccessibility.post(notification: .announcement, argument: text)
        #endif
    }
}
