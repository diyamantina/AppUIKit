//
//  AppUIRowView+TextInput.Touch.swift
//  AppUIKit
//
//  The keyboard of the iPad, on the screen and attached, and its input methods: kana, pinyin, hangul, accents, dictation.
//

#if canImport(UIKit) && !(canImport(AppKit) && !targetEnvironment(macCatalyst))
    import CoreGraphics
    import Foundation
    import UIKit

    /// A place in the text of the row the caret is in, as it is shown: a column, in UTF-16 units.
    final class AppUIRowTextPosition: UITextPosition {
        let offset: Int

        init(_ offset: Int) {
            self.offset = offset
        }
    }

    /// A range of the text of the row the caret is in, as it is shown.
    final class AppUIRowTextRange: UITextRange {
        let first: AppUIRowTextPosition
        let last: AppUIRowTextPosition

        init(_ first: Int, _ last: Int) {
            self.first = AppUIRowTextPosition(min(first, last))
            self.last = AppUIRowTextPosition(max(first, last))
        }

        override var start: UITextPosition {
            first
        }

        override var end: UITextPosition {
            last
        }

        override var isEmpty: Bool {
            first.offset == last.offset
        }

        var range: NSRange {
            NSRange(location: first.offset, length: last.offset - first.offset)
        }
    }

    /// What the keyboard asks of a view that is typed in. The text it speaks of is the text of the row the caret is in, as it is shown (with what is being
    /// composed in it), so its places are columns of that row; the rest of the rows, which may be a gigabyte, are not its business. What is typed, deleted and
    /// settled goes to the owner of the rows as edits, as it does on the Mac.
    extension AppUIRowView: @MainActor UITextInput {
        // MARK: What was typed

        public var hasText: Bool {
            // The delete key of the keyboard on the screen is dead when this is false; what there is to delete is for the owner to say.
            true
        }

        public func insertText(_ text: String) {
            commit(text)
        }

        public func deleteBackward() {
            guard isEditable else { return }
            onEdit?(.deleteBackward)
        }

        // MARK: Places and ranges

        private var length: Int {
            guard let caret else { return 0 }
            return composedText(ofRow: caret.row).length
        }

        private static func offset(_ position: UITextPosition) -> Int {
            (position as? AppUIRowTextPosition)?.offset ?? 0
        }

        public var beginningOfDocument: UITextPosition {
            AppUIRowTextPosition(0)
        }

        public var endOfDocument: UITextPosition {
            AppUIRowTextPosition(length)
        }

        public var selectedTextRange: UITextRange? {
            get {
                if let composition {
                    return AppUIRowTextRange(composition.column + composition.selected.location, composition.column + NSMaxRange(composition.selected))
                }
                if let selection, selection.lowerBound.row == selection.upperBound.row {
                    return AppUIRowTextRange(selection.lowerBound.column, selection.upperBound.column)
                }
                return AppUIRowTextRange(caret?.column ?? 0, caret?.column ?? 0)
            }
            set {
                guard let range = newValue as? AppUIRowTextRange, let caret, composition == nil else { return }
                if range.isEmpty {
                    setCaret(AppUIRowPosition(row: caret.row, column: range.first.offset))
                } else {
                    let start = AppUIRowPosition(row: caret.row, column: range.first.offset)
                    let end = AppUIRowPosition(row: caret.row, column: range.last.offset)
                    selectionAnchor = start
                    selection = start ... end
                    self.caret = end
                    onSelectionChange?()
                }
            }
        }

        public var markedTextRange: UITextRange? {
            composition.map { AppUIRowTextRange($0.column, $0.column + $0.length) }
        }

        public var markedTextStyle: [NSAttributedString.Key: Any]? {
            get { composedStyle }
            set { composedStyle = newValue }
        }

        public func text(in range: UITextRange) -> String? {
            guard let range = range as? AppUIRowTextRange, let caret else { return nil }
            let text = composedText(ofRow: caret.row)
            return text.substring(with: NSIntersectionRange(range.range, NSRange(location: 0, length: text.length)))
        }

        public func replace(_ range: UITextRange, withText text: String) {
            guard let range = range as? AppUIRowTextRange else { return }
            commit(text, replacing: range.range)
        }

        public func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
            inputDelegate?.textWillChange(self)
            setComposition(markedText ?? "", selected: selectedRange)
            inputDelegate?.textDidChange(self)
        }

        public func unmarkText() {
            inputDelegate?.textWillChange(self)
            endComposition(commit: true)
            inputDelegate?.textDidChange(self)
        }

        public func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
            AppUIRowTextRange(Self.offset(fromPosition), Self.offset(toPosition))
        }

        public func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
            let moved = Self.offset(position) + offset
            return moved < 0 || moved > length ? nil : AppUIRowTextPosition(moved)
        }

        public func position(from position: UITextPosition, in _: UITextLayoutDirection, offset: Int) -> UITextPosition? {
            self.position(from: position, offset: offset)
        }

        public func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
            let first = Self.offset(position)
            let second = Self.offset(other)
            return first == second ? .orderedSame : (first < second ? .orderedAscending : .orderedDescending)
        }

        public func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
            Self.offset(toPosition) - Self.offset(from)
        }

        public var tokenizer: any UITextInputTokenizer {
            UITextInputStringTokenizer(textInput: self)
        }

        public func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
            guard let range = range as? AppUIRowTextRange else { return nil }
            switch direction {
            case .left, .up: return range.first
            default: return range.last
            }
        }

        public func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
            let offset = Self.offset(position)
            switch direction {
            case .left, .up: return AppUIRowTextRange(0, offset)
            default: return AppUIRowTextRange(offset, length)
            }
        }

        public func baseWritingDirection(for _: UITextPosition, in _: UITextStorageDirection) -> NSWritingDirection {
            .natural
        }

        public func setBaseWritingDirection(_: NSWritingDirection, for _: UITextRange) {}

        // MARK: Where things are

        public func firstRect(for range: UITextRange) -> CGRect {
            guard let range = range as? AppUIRowTextRange else { return .zero }
            return rect(ofComposedRange: range.range)
        }

        public func caretRect(for position: UITextPosition) -> CGRect {
            rect(ofComposedRange: NSRange(location: Self.offset(position), length: 0))
        }

        public func selectionRects(for _: UITextRange) -> [UITextSelectionRect] {
            []
        }

        public func closestPosition(to point: CGPoint) -> UITextPosition? {
            guard let place = rowPosition(at: point), place.row == caret?.row else { return nil }
            return AppUIRowTextPosition(place.column)
        }

        public func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
            guard let range = range as? AppUIRowTextRange, let found = closestPosition(to: point) else { return nil }
            return AppUIRowTextPosition(min(range.last.offset, max(range.first.offset, Self.offset(found))))
        }

        public func characterRange(at point: CGPoint) -> UITextRange? {
            guard let place = rowPosition(at: point), place.row == caret?.row else { return nil }
            return AppUIRowTextRange(place.column, min(length, place.column + 1))
        }
    }
#endif
