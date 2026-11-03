//
//  AppUICanvas.Key.swift
//  AppUIKit
//
//  The keys of the canvas that mean an edit or a change of view, reported as they are pressed.
//

public extension AppUICanvas {
    /// A key the canvas reports: the arrows, Delete, Escape, Tab, Return and Space. Every other key is left to the responder chain, so the menu's shortcuts work as they do
    /// everywhere.
    struct Key: Sendable, Equatable {
        /// Which key it is.
        public var kind: KeyKind
        /// The modifier keys held.
        public var modifiers: Modifiers
        /// Whether the key went down (`true`) or came up. Only Space reports its release, because it is held; the others report a press, and each repeat of a held key is a press.
        public var isDown: Bool
        /// Whether the press is the system's repeat of a key that is being held.
        public var isRepeat: Bool

        /// A key.
        public init(_ kind: KeyKind, modifiers: Modifiers = [], isDown: Bool = true, isRepeat: Bool = false) {
            self.kind = kind
            self.modifiers = modifiers
            self.isDown = isDown
            self.isRepeat = isRepeat
        }
    }
}
