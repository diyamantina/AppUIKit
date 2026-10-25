//
//  AppUIRowView+Composition.swift
//  AppUIKit
//
//  What an input method does to a row view that can be edited: composes text at the caret, and commits it.
//

import CoreGraphics
import CoreText
import Foundation

public extension AppUIRowView {
    /// The text of a row.
    private func rowText(_ row: Int) -> NSString {
        guard row >= 0, row < rowCount else { return "" }
        prepare(row ..< row + 1)
        return (cache[row]?.row.text ?? "") as NSString
    }

    /// The row of the caret as the person sees it: its text with what is being composed in it.
    func composedText(ofRow row: Int) -> NSString {
        let text = rowText(row)
        guard let composition, composition.row == row else { return text }
        return text.replacingCharacters(in: NSRange(location: min(composition.column, text.length), length: 0), with: composition.text) as NSString
    }

    /// The line of a row with the composition in it, underlined, or nil when the row has none.
    internal func composedLine(of cached: CachedRow, row: Int) -> CTLine? {
        guard let composition, composition.row == row else { return nil }
        let line = NSMutableAttributedString(attributedString: attributed(cached.row))
        let marked = NSAttributedString(string: composition.text, attributes: [
            .font: font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): textColor.cgColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ])
        line.insert(marked, at: min(composition.column, line.length))
        return CTLineCreateWithAttributedString(line)
    }

    /// Selects `range` of the row of the caret, as an input method replacing text asks, when it is in the row; true when it was.
    @discardableResult
    private func selectInCaretRow(_ range: NSRange?) -> Bool {
        guard let range, let caret, range.location != NSNotFound, range.length > 0, range.location + range.length <= rowText(caret.row).length else { return false }
        let start = AppUIRowPosition(row: caret.row, column: range.location)
        let end = AppUIRowPosition(row: caret.row, column: range.location + range.length)
        selectionAnchor = start
        selection = start ... end
        self.caret = end
        return true
    }

    /// Begins or goes on composing: `text` is what the input method has so far and `selected` its insertion point or selection within it. A selection in the
    /// rows is replaced when composing begins, as typing replaces it. Empty text ends the composition without a commit. `replacing` is a range of the caret's row
    /// the input method wants taken out first (a word it is converting again).
    func setComposition(_ text: String, selected: NSRange, replacing: NSRange? = nil) {
        guard isEditable else { return }
        if text.isEmpty {
            composition = nil
            return
        }
        if composition == nil {
            selectInCaretRow(replacing)
            if selection != nil {
                onEdit?(.deleteBackward)
            }
            guard let caret else { return }
            composition = AppUIRowComposition(row: caret.row, column: caret.column, text: text, selected: selected)
        } else if var composing = composition {
            composing.text = text
            composing.selected = selected
            composition = composing
        }
        scrollCaretIntoView()
    }

    /// Ends the composition, giving the owner the text as it stands (when `commit`) as one insert, and nothing when it is thrown away.
    func endComposition(commit: Bool) {
        guard let composing = composition else { return }
        composition = nil
        if commit, !composing.text.isEmpty {
            onEdit?(.insert(composing.text))
        }
    }

    /// Takes text the input method has settled on: it replaces the composition, if there is one, and is given to the owner as an insert. Line breaks and tabs
    /// are the keys they are, `replacing` is a range of the caret's row to put it in place of (the accent menu replacing the letter before the caret).
    func commit(_ text: String, replacing: NSRange? = nil) {
        guard isEditable else { return }
        let composing = composition != nil
        composition = nil
        if !composing {
            selectInCaretRow(replacing)
        }
        guard !text.isEmpty else { return }
        switch text {
        case "\n": onEdit?(.newline)
        case "\t": onEdit?(.insert("  "))
        default: onEdit?(.insert(text))
        }
    }

    /// The rectangle, in the view's own coordinates, of a range of the caret's row as it is shown (with the composition in it): where an input method puts its
    /// candidates.
    func rect(ofComposedRange range: NSRange) -> CGRect {
        guard let caret, caret.row < rowCount else { return .zero }
        prepare(caret.row ..< caret.row + 1)
        guard let cached = cache[caret.row] else { return .zero }
        let line = composedLine(of: cached, row: caret.row) ?? cached.line
        let length = composedText(ofRow: caret.row).length
        let start = min(length, max(0, range.location))
        let end = min(length, max(start, range.location + range.length))
        let left = CTLineGetOffsetForStringIndex(line, start, nil)
        let right = CTLineGetOffsetForStringIndex(line, end, nil)
        let originX = gutterWidth + 6 - horizontalOffset
        return CGRect(x: originX + left, y: top(ofRow: caret.row), width: max(1.5, right - left), height: rowHeight)
    }
}
