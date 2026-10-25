//
//  AppUIRowView+TextInput.swift
//  AppUIKit
//
//  The Mac's input methods: accents by dead keys, kana, pinyin, hangul, the character viewer, dictation.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import CoreGraphics
    import CoreText
    import Foundation

    /// What the Mac's text input system asks of a view that is typed in. The text it speaks of is the text of the row the caret is in, as it is shown (with
    /// what is being composed in it), so the ranges are columns of that row; the rest of the rows, which may be a gigabyte, are not its business, and an input
    /// method that wants to see around the caret sees the row.
    extension AppUIRowView: @MainActor NSTextInputClient {
        /// The string of what the system gives: text, or text with attributes.
        private static func plain(_ string: Any) -> String {
            (string as? NSAttributedString)?.string ?? (string as? String) ?? ""
        }

        public func insertText(_ string: Any, replacementRange: NSRange) {
            commit(Self.plain(string), replacing: replacementRange)
        }

        public func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
            setComposition(Self.plain(string), selected: selectedRange, replacing: replacementRange)
        }

        public func unmarkText() {
            endComposition(commit: true)
        }

        public func selectedRange() -> NSRange {
            if let composition {
                return NSRange(location: composition.column + composition.selected.location, length: composition.selected.length)
            }
            if let selection, selection.lowerBound.row == selection.upperBound.row {
                return NSRange(location: selection.lowerBound.column, length: selection.upperBound.column - selection.lowerBound.column)
            }
            return NSRange(location: caret?.column ?? 0, length: 0)
        }

        public func markedRange() -> NSRange {
            composition.map { NSRange(location: $0.column, length: $0.length) } ?? NSRange(location: NSNotFound, length: 0)
        }

        public func hasMarkedText() -> Bool {
            composition != nil
        }

        public func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
            guard let caret else { return nil }
            let text = composedText(ofRow: caret.row)
            let clamped = NSIntersectionRange(range, NSRange(location: 0, length: text.length))
            actualRange?.pointee = clamped
            return NSAttributedString(string: text.substring(with: clamped))
        }

        public func validAttributesForMarkedText() -> [NSAttributedString.Key] {
            []
        }

        public func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
            actualRange?.pointee = range
            let inView = rect(ofComposedRange: range)
            guard let window else { return inView }
            return window.convertToScreen(convert(inView, to: nil))
        }

        public func characterIndex(for point: NSPoint) -> Int {
            guard let window else { return 0 }
            let inView = convert(window.convertFromScreen(NSRect(origin: point, size: .zero)).origin, from: nil)
            guard let place = rowPosition(at: inView), place.row == caret?.row else { return NSNotFound }
            return place.column
        }

        /// What the input system asks of the view when a key is a command and not text: a line break, a delete, a tab, and Escape, which throws away what is being
        /// composed.
        override open func doCommand(by selector: Selector) {
            switch selector {
            case #selector(insertNewline(_:)), #selector(insertLineBreak(_:)), #selector(insertNewlineIgnoringFieldEditor(_:)): onEdit?(.newline)
            case #selector(deleteBackward(_:)): onEdit?(.deleteBackward)
            case #selector(deleteForward(_:)): onEdit?(.deleteForward)
            case #selector(insertTab(_:)): onEdit?(.insert("  "))
            case #selector(cancelOperation(_:)): composition = nil
            default: break
            }
        }

        /// Whether a key event is for the input system to make sense of before the view does: anything that is not a command key and not Command-something,
        /// and every key while text is being composed, since then the arrows and the return choose and settle it.
        func belongsToInputSystem(_ event: NSEvent) -> Bool {
            if composition != nil {
                return !event.modifierFlags.contains(.command)
            }
            return event.specialKey == nil && !event.modifierFlags.contains(.command)
        }
    }
#endif
