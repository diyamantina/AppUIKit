//
//  AppUIRowCaretKey.swift
//  AppUIKit
//
//  The keys that move the caret of a row view that can be edited, in the words of no platform: the Mac names them by what an event says, an iPad by the
//  usage of a key on a keyboard, and both end here.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

enum AppUIRowCaretKey: Equatable, Sendable {
    case left
    case right
    case up
    case down
    case home
    case end
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    extension AppUIRowCaretKey {
        /// The caret key an event's special key is, or nil for any other key.
        init?(_ key: NSEvent.SpecialKey?) {
            switch key {
            case .leftArrow: self = .left
            case .rightArrow: self = .right
            case .upArrow: self = .up
            case .downArrow: self = .down
            case .home: self = .home
            case .end: self = .end
            default: return nil
            }
        }
    }
#elseif canImport(UIKit)
    extension AppUIRowCaretKey {
        /// The caret key a key of a hardware keyboard is, or nil for any other key.
        init?(_ usage: UIKeyboardHIDUsage) {
            switch usage {
            case .keyboardLeftArrow: self = .left
            case .keyboardRightArrow: self = .right
            case .keyboardUpArrow: self = .up
            case .keyboardDownArrow: self = .down
            case .keyboardHome: self = .home
            case .keyboardEnd: self = .end
            default: return nil
            }
        }
    }
#endif
