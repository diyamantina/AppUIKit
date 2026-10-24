//
//  AppUIRowView+Input.swift
//  AppUIKit
//
//  What a person does to a row view: scroll it, drag its scroller, click and drag across its text, press keys, copy.
//

import CoreGraphics
import CoreText
import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

public extension AppUIRowView {
    internal static let scrollerHitWidth: CGFloat = 14

    // MARK: Places

    /// The row and offset in its text at a point of the view; nil when there are no rows.
    func rowPosition(at point: CGPoint) -> AppUIRowPosition? {
        guard rowCount > 0 else { return nil }
        let row = min(rowCount - 1, max(0, Int((position + Double(point.y)) / Double(rowHeight))))
        prepare(row ..< row + 1)
        guard let cached = cache[row] else { return AppUIRowPosition(row: row, column: 0) }
        let length = (cached.row.text as NSString).length
        let index = CTLineGetStringIndexForPosition(cached.line, CGPoint(x: point.x - gutterWidth - 6 + horizontalOffset, y: 0))
        return AppUIRowPosition(row: row, column: index == kCFNotFound ? length : min(length, max(0, index)))
    }

    /// The top of a row in the view's own coordinates (negative above the view).
    func top(ofRow row: Int) -> CGFloat {
        CGFloat(Double(row) * Double(rowHeight) - position)
    }

    // MARK: Scrolling

    /// Moves by points as a wheel or a trackpad does, and by points across.
    func scroll(byY deltaY: CGFloat, x deltaX: CGFloat = 0) {
        let before = position
        position += Double(deltaY)
        let room = max(0, widestRow + 16 - (bounds.width - gutterWidth - Self.scrollerHitWidth))
        horizontalOffset = min(room, max(0, horizontalOffset + deltaX))
        redraw()
        if position != before {
            onPositionChange?(position)
        }
    }

    /// Scrolls so that `row` is at the top of the view, or in the middle of it.
    func scroll(toRow row: Int, centered: Bool = false) {
        let target = Double(min(max(0, row), max(0, rowCount - 1))) * Double(rowHeight)
        position = centered ? target - Double(bounds.height - rowHeight) / 2 : target
        onPositionChange?(position)
    }

    // MARK: The scroller

    /// The knob of the scroller, or nil when everything is in view.
    internal var knobRect: CGRect? {
        let total = Double(rowCount) * Double(rowHeight)
        guard maximumPosition > 0, total > 0 else { return nil }
        let length = min(bounds.height, max(28, CGFloat(Double(bounds.height) / total) * bounds.height))
        let travel = bounds.height - length
        return CGRect(x: bounds.width - 10, y: travel * CGFloat(position / maximumPosition), width: 8, height: length)
    }

    /// The height from the top of the view, in points, of the mark of a row: the rows laid along the height, as the knob is.
    internal func markY(ofRow row: Int) -> CGFloat {
        guard rowCount > 0 else { return 0 }
        return CGFloat(Double(min(max(0, row), rowCount - 1)) / Double(rowCount) * Double(bounds.height))
    }

    /// Draws the marks under the knob. Marks that fall on the same line of pixels are drawn once, so a hundred thousand matches cost a few hundred strokes.
    internal func drawMarks(in context: CGContext) {
        guard !marks.isEmpty, rowCount > 0 else { return }
        var seen = Set<Int>()
        context.setFillColor(AppUIKit.Colors.label.withAlphaComponent(0.45).cgColor)
        for mark in marks where !mark.emphasized {
            let y = markY(ofRow: mark.row)
            guard seen.insert(Int(y)).inserted else { continue }
            context.fill(CGRect(x: bounds.width - 10, y: y.rounded(.down), width: 8, height: 2))
        }
        context.setFillColor(AppUIKit.Colors.accent.cgColor)
        for mark in marks where mark.emphasized {
            context.fill(CGRect(x: bounds.width - 12, y: markY(ofRow: mark.row).rounded(.down) - 1, width: 12, height: 3))
        }
    }

    internal func drawScroller(in context: CGContext) {
        guard let knob = knobRect else { return }
        drawMarks(in: context)
        context.setFillColor(AppUIKit.Colors.label.withAlphaComponent(scrollerDrag == nil ? 0.32 : 0.55).cgColor)
        context.addPath(CGPath(roundedRect: knob, cornerWidth: 4, cornerHeight: 4, transform: nil))
        context.fillPath()
    }

    private func dragScroller(to y: CGFloat) {
        guard let knob = knobRect, let grab = scrollerDrag else { return }
        let travel = bounds.height - knob.height
        guard travel > 0 else { return }
        position = Double(min(1, max(0, (y - grab) / travel))) * maximumPosition
        onPositionChange?(position)
    }

    // MARK: Pressing

    internal func handlePressBegan(at point: CGPoint, scrollerWidth: CGFloat = AppUIRowView.scrollerHitWidth) {
        pressMoved = false
        if point.x >= bounds.width - scrollerWidth, let knob = knobRect {
            if knob.contains(CGPoint(x: knob.midX, y: point.y)) {
                scrollerDrag = point.y - knob.minY
            } else {
                scroll(byY: (point.y < knob.minY ? -1 : 1) * bounds.height * 0.9)
            }
            redraw()
            return
        }
        guard let place = rowPosition(at: point) else { return }
        selectionAnchor = place
        selection = nil
        redraw()
        onSelectionChange?()
        switch pressCount {
        case 2: select(word: place)
        case 3...: select(rowAt: place.row)
        default: break
        }
    }

    internal func handlePressMoved(at point: CGPoint) {
        if scrollerDrag != nil {
            dragScroller(to: point.y)
            return
        }
        guard let anchor = selectionAnchor else { return }
        pressMoved = true
        if point.y < 0 {
            scroll(byY: max(-60, point.y / 2))
        } else if point.y > bounds.height {
            scroll(byY: min(60, (point.y - bounds.height) / 2))
        }
        guard let head = rowPosition(at: CGPoint(x: point.x, y: min(max(point.y, 0), bounds.height - 1))) else { return }
        selection = head == anchor ? nil : min(anchor, head) ... max(anchor, head)
        redraw()
        onSelectionChange?()
    }

    internal func handlePressEnded(at point: CGPoint) {
        defer {
            scrollerDrag = nil
            redraw()
        }
        guard !pressMoved, scrollerDrag == nil, point.x < bounds.width - Self.scrollerHitWidth, pressCount == 1, let place = rowPosition(at: point) else { return }
        onActivate?(place, pressedWithCommand)
    }

    internal func select(word place: AppUIRowPosition) {
        guard let cached = cache[place.row] else { return }
        let text = cached.row.text as NSString
        func isWord(_ index: Int) -> Bool {
            guard index >= 0, index < text.length, let scalar = Unicode.Scalar(text.character(at: index)) else { return false }
            return CharacterSet.alphanumerics.contains(scalar) || "_-$".unicodeScalars.contains(scalar)
        }
        var start = min(place.column, text.length)
        var end = start
        while isWord(start - 1) {
            start -= 1
        }
        while isWord(end) {
            end += 1
        }
        guard end > start else { return }
        selectionAnchor = AppUIRowPosition(row: place.row, column: start)
        selection = AppUIRowPosition(row: place.row, column: start) ... AppUIRowPosition(row: place.row, column: end)
        redraw()
        onSelectionChange?()
    }

    internal func select(rowAt row: Int) {
        guard let cached = cache[row] else { return }
        selectionAnchor = AppUIRowPosition(row: row, column: 0)
        selection = AppUIRowPosition(row: row, column: 0) ... AppUIRowPosition(row: row, column: (cached.row.text as NSString).length)
        redraw()
        onSelectionChange?()
    }

    // MARK: Selected text

    /// The text of the selection, or nil when nothing is selected or it holds more than `limit` characters.
    func selectedText(limit: Int = 50_000_000) -> String? {
        guard let selection, let source else { return nil }
        var output = ""
        var row = selection.lowerBound.row
        while row <= selection.upperBound.row {
            let end = min(selection.upperBound.row + 1, row + 256)
            let rows = source.rows(in: row ..< end)
            guard !rows.isEmpty else { break }
            for (offset, found) in rows.enumerated() {
                let number = row + offset
                let text = found.text as NSString
                let start = number == selection.lowerBound.row ? min(text.length, selection.lowerBound.column) : 0
                let stop = number == selection.upperBound.row ? min(text.length, selection.upperBound.column) : text.length
                output += text.substring(with: NSRange(location: start, length: max(0, stop - start)))
                if number < selection.upperBound.row {
                    output += "\n"
                }
            }
            if output.utf8.count > limit {
                return nil
            }
            row += rows.count
        }
        return output
    }

    /// Selects a range of the text, or nothing, as an owner does when it has chosen what the person should see selected.
    func select(_ range: ClosedRange<AppUIRowPosition>?) {
        selection = range
        selectionAnchor = range?.lowerBound
        redraw()
        onSelectionChange?()
    }

    /// Selects everything.
    func selectEverything() {
        guard rowCount > 0, let last = source?.rows(in: rowCount - 1 ..< rowCount).first else { return }
        let first = AppUIRowPosition(row: 0, column: 0)
        selectionAnchor = first
        selection = first ... AppUIRowPosition(row: rowCount - 1, column: (last.text as NSString).length)
        redraw()
        onSelectionChange?()
    }

    func copySelection() {
        if let text = selectedText() {
            AppUIKit.Pasteboard.copy(text)
        }
    }

    /// The text of the rows in view, which is what assistive technology and tests read.
    var visibleText: String {
        let visible = visibleRows
        prepare(visible)
        return visible.compactMap { cache[$0]?.row.text }.joined(separator: "\n")
    }
}
