//
//  AppUITreeView+Input.swift
//  AppUIKit
//
//  What a person does to a tree view: scroll it, drag its scroller, click a row or its chevron, and press the arrow keys.
//

import CoreGraphics
import Foundation

public extension AppUITreeView {
    // MARK: Places

    /// The row at a point of the view, or nil when there is none there.
    func rowIndex(at point: CGPoint) -> Int? {
        guard rowCount > 0, point.y >= 0, point.y < bounds.height else { return nil }
        let index = Int((position + Double(point.y)) / Double(rowHeight))
        return index >= 0 && index < rowCount ? index : nil
    }

    /// The top of a row in the view's own coordinates (negative above the view).
    func top(ofRow row: Int) -> CGFloat {
        CGFloat(Double(row) * Double(rowHeight) - position)
    }

    /// Whether a point is on the chevron of an expandable row.
    internal func isOnChevron(_ point: CGPoint, row: AppUITreeRow) -> Bool {
        let left = 10 + CGFloat(row.depth) * indentWidth
        return row.isExpandable && point.x >= left - 4 && point.x <= left + indentWidth + 4
    }

    // MARK: Scrolling

    func scroll(byY deltaY: CGFloat) {
        let before = position
        position += Double(deltaY)
        if position != before {
            onPositionChange?(position)
        }
    }

    func scroll(toRow row: Int, centered: Bool = false) {
        let target = Double(min(max(0, row), max(0, rowCount - 1))) * Double(rowHeight)
        position = centered ? target - Double(bounds.height - rowHeight) / 2 : target
        onPositionChange?(position)
    }

    /// Moves the least that shows the whole of `row`.
    func reveal(row: Int) {
        let target = Double(row) * Double(rowHeight)
        if target < position {
            position = target
        } else if target + Double(rowHeight) > position + Double(bounds.height) {
            position = target + Double(rowHeight) - Double(bounds.height)
        }
        onPositionChange?(position)
    }

    // MARK: The scroller

    internal var knobRect: CGRect? {
        let total = Double(rowCount) * Double(rowHeight)
        guard maximumPosition > 0, total > 0 else { return nil }
        let length = min(bounds.height, max(28, CGFloat(Double(bounds.height) / total) * bounds.height))
        let travel = bounds.height - length
        return CGRect(x: bounds.width - 10, y: travel * CGFloat(position / maximumPosition), width: 8, height: length)
    }

    internal func drawScroller(in context: CGContext) {
        guard let knob = knobRect else { return }
        context.setFillColor(AppUIKit.Colors.label.withAlphaComponent(scrollerDrag == nil ? 0.32 : 0.55).cgColor)
        context.addPath(CGPath(roundedRect: knob, cornerWidth: 4, cornerHeight: 4, transform: nil))
        context.fillPath()
    }

    // MARK: Pressing

    internal func handlePressBegan(at point: CGPoint) {
        if point.x >= bounds.width - Self.scrollerHitWidth, let knob = knobRect {
            if knob.contains(CGPoint(x: knob.midX, y: point.y)) {
                scrollerDrag = point.y - knob.minY
            } else {
                scroll(byY: (point.y < knob.minY ? -1 : 1) * bounds.height * 0.9)
            }
            redraw()
            return
        }
        guard let index = rowIndex(at: point), let row = row(index) else { return }
        if isOnChevron(point, row: row) || pressCount == 2 {
            onToggle?(index)
            selectedRow = index
            onSelect?(index)
        } else {
            selectedRow = index
            onSelect?(index)
        }
    }

    internal func handlePressMoved(at point: CGPoint) {
        guard let grab = scrollerDrag, let knob = knobRect else { return }
        let travel = bounds.height - knob.height
        guard travel > 0 else { return }
        position = Double(min(1, max(0, (point.y - grab) / travel))) * maximumPosition
        onPositionChange?(position)
    }

    internal func handlePressEnded() {
        scrollerDrag = nil
        redraw()
    }

    // MARK: Keys

    /// Moves the selected row by `delta` rows (the first or last when there is none) and shows it.
    func moveSelection(by delta: Int) {
        guard rowCount > 0 else { return }
        let from = selectedRow ?? (delta > 0 ? -1 : rowCount)
        let next = min(rowCount - 1, max(0, from + delta))
        selectedRow = next
        reveal(row: next)
        onSelect?(next)
    }

    /// The left arrow closes the selected row, and the right arrow opens it.
    func arrow(opening: Bool) {
        guard let index = selectedRow, let row = row(index), row.isExpandable, row.isExpanded != opening else { return }
        onToggle?(index)
    }
}
