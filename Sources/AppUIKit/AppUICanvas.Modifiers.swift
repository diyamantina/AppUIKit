//
//  AppUICanvas.Modifiers.swift
//  AppUIKit
//

public extension AppUICanvas {
    /// The modifier keys held when a ``Sample`` was made. The empty set means none were held.
    struct Modifiers: OptionSet, Sendable, Hashable {
        /// The bits, in the order of the declarations.
        public let rawValue: UInt8

        /// Creates a set from its bits.
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        /// Caps Lock is on.
        public static let capsLock = Modifiers(rawValue: 1 << 0)
        /// Shift.
        public static let shift = Modifiers(rawValue: 1 << 1)
        /// Control.
        public static let control = Modifiers(rawValue: 1 << 2)
        /// Option.
        public static let option = Modifiers(rawValue: 1 << 3)
        /// Command.
        public static let command = Modifiers(rawValue: 1 << 4)
        /// A key of the numeric keypad.
        public static let numericPad = Modifiers(rawValue: 1 << 5)
        /// A function key.
        public static let function = Modifiers(rawValue: 1 << 6)
    }
}
