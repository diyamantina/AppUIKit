//
//  AppUICanvas.Command.swift
//  AppUIKit
//
//  The multi-finger taps of a touch screen, which stand where a keyboard has shortcuts.
//

public extension AppUICanvas {
    /// A command made by tapping a touch screen with several fingers, as Procreate does: two fingers undo, three redo, four toggle the interface. A touch screen has no shortcut
    /// keys, and a tap with
    /// more than one finger is not a stroke, so these cost the drawing nothing. A Mac makes none: its keys and its menus do the same.
    enum Command: Sendable, Equatable, CaseIterable {
        case undo
        case redo
        case toggleInterface

        /// The command of a tap with `count` fingers, or `nil` for any other count.
        public init?(fingers count: Int) {
            switch count {
            case 2: self = .undo
            case 3: self = .redo
            case 4: self = .toggleInterface
            default: return nil
            }
        }

        /// How many fingers make the tap.
        public var fingers: Int {
            switch self {
            case .undo: 2
            case .redo: 3
            case .toggleInterface: 4
            }
        }
    }
}
