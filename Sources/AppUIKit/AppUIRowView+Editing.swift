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
}
