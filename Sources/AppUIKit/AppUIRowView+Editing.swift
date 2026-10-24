//
//  AppUIRowView+Editing.swift
//  AppUIKit
//
//  The caret of a row view that can be edited: where it is, how the keys move it, and how it is shown.
//

import CoreGraphics
import Foundation

public extension AppUIRowView {
    /// The text of a row, which the caret moves along; empty past the last row.
    private func text(ofRow row: Int) -> NSString {
        guard row >= 0, row < rowCount else { return "" }
        prepare(row ..< row + 1)
        return (cache[row]?.row.text ?? "") as NSString
    }

    /// Puts the caret at `position` (held to the rows), clears the selection, and shows the place.
    func setCaret(_ position: AppUIRowPosition?) {
        selection = nil
        selectionAnchor = nil
        guard let position, rowCount > 0 else {
            caret = nil
            return
        }
        let row = min(max(0, position.row), rowCount - 1)
        caret = AppUIRowPosition(row: row, column: min(max(0, position.column), text(ofRow: row).length))
        scrollCaretIntoView()
        onSelectionChange?()
    }

    /// The place a key that moves the caret moves it from: the caret, or the end of the selection the key is toward.
    private func origin(towardEnd: Bool?) -> AppUIRowPosition? {
        if let selection {
            guard let towardEnd else { return selection.upperBound }
            return towardEnd ? selection.upperBound : selection.lowerBound
        }
        return caret
    }

    /// Moves the caret one character, as the left and right arrows do, over the end of a row to the next or the one before.
    func moveCaret(by direction: Int) {
        guard let from = origin(towardEnd: direction > 0) else { return }
        let had = selection != nil
        var row = from.row
        var column = from.column
        let line = text(ofRow: row)
        if had {
            // A selection ends where the key points, and the caret goes there.
        } else if direction < 0 {
            if column > 0 {
                column = line.rangeOfComposedCharacterSequence(at: column - 1).location
            } else if row > 0 {
                row -= 1
                column = text(ofRow: row).length
            }
        } else if column < line.length {
            column = NSMaxRange(line.rangeOfComposedCharacterSequence(at: column))
        } else if row + 1 < rowCount {
            row += 1
            column = 0
        }
        setCaret(AppUIRowPosition(row: row, column: column))
    }

    /// Moves the caret to the row above or below, keeping its column as far as the row goes.
    func moveCaret(rows: Int) {
        guard let from = origin(towardEnd: rows > 0) else { return }
        setCaret(AppUIRowPosition(row: from.row + rows, column: from.column))
    }

    /// Moves the caret to the start or the end of its row.
    func moveCaretToRowEdge(end: Bool) {
        guard let from = origin(towardEnd: end) else { return }
        setCaret(AppUIRowPosition(row: from.row, column: end ? text(ofRow: from.row).length : 0))
    }

    /// Scrolls just far enough that the row of the caret is in view.
    func scrollCaretIntoView() {
        guard let caret else { return }
        let top = Double(caret.row) * Double(rowHeight)
        if top < position {
            position = top
            onPositionChange?(position)
        } else if top + Double(rowHeight) > position + Double(bounds.height) {
            position = top + Double(rowHeight) - Double(bounds.height)
            onPositionChange?(position)
        }
    }

    /// Whether a typed string is text and not a key that happened to give characters: no control characters, and none of the private ones the function keys use.
    static func isTypedText(_ characters: String) -> Bool {
        !characters.isEmpty && characters.unicodeScalars.allSatisfy { $0.value >= 0x20 && $0.value != 0x7F && !(0xF700 ... 0xF8FF).contains($0.value) }
    }

    // MARK: Selecting with the keys

    /// The end of the selection that moves when it is extended: the one that is not the anchor. With nothing selected, the caret.
    private var head: AppUIRowPosition? {
        if let selection, let selectionAnchor {
            return selectionAnchor == selection.lowerBound ? selection.upperBound : selection.lowerBound
        }
        return caret
    }

    /// Makes the selection run from where it began to `head`, as Shift with an arrow does; it is nothing, and the caret, when they are the same place.
    private func select(to head: AppUIRowPosition) {
        let anchor = selectionAnchor.flatMap { selection != nil ? $0 : nil } ?? caret ?? head
        let row = min(max(0, head.row), max(0, rowCount - 1))
        let there = AppUIRowPosition(row: row, column: min(max(0, head.column), text(ofRow: row).length))
        selectionAnchor = anchor
        selection = there == anchor ? nil : min(anchor, there) ... max(anchor, there)
        caret = there
        scrollCaretIntoView()
        onSelectionChange?()
    }

    /// Extends the selection one character, as Shift with the left or right arrow does.
    func extendSelection(by direction: Int) {
        guard let from = head else { return }
        let line = text(ofRow: from.row)
        var row = from.row
        var column = from.column
        if direction < 0 {
            if column > 0 {
                column = line.rangeOfComposedCharacterSequence(at: column - 1).location
            } else if row > 0 {
                row -= 1
                column = text(ofRow: row).length
            }
        } else if column < line.length {
            column = NSMaxRange(line.rangeOfComposedCharacterSequence(at: column))
        } else if row + 1 < rowCount {
            row += 1
            column = 0
        }
        select(to: AppUIRowPosition(row: row, column: column))
    }

    /// Extends the selection to the row above or below, as Shift with the up or down arrow does.
    func extendSelection(rows: Int) {
        guard let from = head else { return }
        select(to: AppUIRowPosition(row: from.row + rows, column: from.column))
    }

    /// Extends the selection to the start or the end of the row, as Shift with Home or End does.
    func extendSelectionToRowEdge(end: Bool) {
        guard let from = head else { return }
        select(to: AppUIRowPosition(row: from.row, column: end ? text(ofRow: from.row).length : 0))
    }

    // MARK: By words and to the ends of the document

    /// Where the word edge nearest from `column` in the direction is in a row, or nil when there is none that way in the row: the end of a word going
    /// forward, the start of a word going back, as Option with the arrows goes.
    private func wordEdge(inRow row: Int, from column: Int, forward: Bool) -> Int? {
        let line = text(ofRow: row)
        var edges: [Int] = []
        line.enumerateSubstrings(in: NSRange(location: 0, length: line.length), options: [.byWords, .substringNotRequired]) { _, range, _, _ in
            edges.append(forward ? NSMaxRange(range) : range.location)
        }
        return forward ? edges.first { $0 > column } : edges.last { $0 < column }
    }

    /// The place a move by a word from `from` ends at: the next word edge in the row, else the edge of the next row that way.
    private func wordPlace(from: AppUIRowPosition, forward: Bool) -> AppUIRowPosition {
        if let edge = wordEdge(inRow: from.row, from: from.column, forward: forward) {
            return AppUIRowPosition(row: from.row, column: edge)
        }
        let next = from.row + (forward ? 1 : -1)
        guard next >= 0, next < rowCount else {
            return AppUIRowPosition(row: from.row, column: forward ? text(ofRow: from.row).length : 0)
        }
        return AppUIRowPosition(row: next, column: forward ? 0 : text(ofRow: next).length)
    }

    /// Moves the caret, or extends the selection, by a word.
    func moveByWord(forward: Bool, extending: Bool) {
        guard let from = extending ? head : origin(towardEnd: forward) else { return }
        let there = wordPlace(from: from, forward: forward)
        if extending {
            select(to: there)
        } else {
            setCaret(there)
        }
    }

    /// Moves the caret, or extends the selection, to the first character of the document or the end of its last row.
    func moveToDocumentEdge(end: Bool, extending: Bool) {
        guard rowCount > 0 else { return }
        let there = end ? AppUIRowPosition(row: rowCount - 1, column: text(ofRow: rowCount - 1).length) : AppUIRowPosition(row: 0, column: 0)
        if extending {
            if head == nil {
                caret = there
            }
            select(to: there)
        } else {
            setCaret(there)
        }
    }

    #if canImport(AppKit)

        // MARK: The keys that move the caret

        /// The keys that move the caret, or with Shift extend the selection; true when `key` was one. Option with left or right goes by a word,
        /// Command with left or right to the edge of the row, and Command with up or down to the start or the end of the document.
        internal func moved(by key: NSEvent.SpecialKey?, extending: Bool, option: Bool, command: Bool) -> Bool {
            if command || option, movedByModifier(key, extending: extending, command: command) {
                return true
            }
            switch key {
            case .leftArrow: go(columns: -1, extending: extending)
            case .rightArrow: go(columns: 1, extending: extending)
            case .upArrow: go(rows: -1, extending: extending)
            case .downArrow: go(rows: 1, extending: extending)
            case .home: go(toEnd: false, extending: extending)
            case .end: go(toEnd: true, extending: extending)
            default: return false
            }
            return true
        }

        /// The arrows with Command (to the ends of the row and the document) or with Option (by a word); false for any other key.
        private func movedByModifier(_ key: NSEvent.SpecialKey?, extending: Bool, command: Bool) -> Bool {
            switch (key, command) {
            case (.leftArrow, true): go(toEnd: false, extending: extending)
            case (.rightArrow, true): go(toEnd: true, extending: extending)
            case (.upArrow, true): moveToDocumentEdge(end: false, extending: extending)
            case (.downArrow, true): moveToDocumentEdge(end: true, extending: extending)
            case (.leftArrow, false): moveByWord(forward: false, extending: extending)
            case (.rightArrow, false): moveByWord(forward: true, extending: extending)
            default: return false
            }
            return true
        }

        /// Moves the caret, or extends the selection, by characters, by rows, or to an edge of the row.
        private func go(columns: Int = 0, rows: Int = 0, toEnd: Bool? = nil, extending: Bool) {
            if let toEnd {
                if extending {
                    extendSelectionToRowEdge(end: toEnd)
                } else {
                    moveCaretToRowEdge(end: toEnd)
                }
            } else if rows != 0 {
                if extending {
                    extendSelection(rows: rows)
                } else {
                    moveCaret(rows: rows)
                }
            } else if extending {
                extendSelection(by: columns)
            } else {
                moveCaret(by: columns)
            }
        }
    #endif
}
