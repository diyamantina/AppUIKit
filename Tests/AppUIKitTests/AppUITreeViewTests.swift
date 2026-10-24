#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import Foundation
    import Testing
    @testable import AppUIKit

    /// Rows that say what they are: every third row is one level in, every second can be opened.
    @MainActor
    final class NumberedTree: AppUITreeSource {
        let rowCount: Int
        let alternating: Bool
        var expanded: Set<Int> = []

        init(rowCount: Int, alternating: Bool = false) {
            self.rowCount = rowCount
            self.alternating = alternating
        }

        func row(at index: Int) -> AppUITreeRow? {
            guard index >= 0, index < rowCount else { return nil }
            if alternating {
                return AppUITreeRow(depth: 0, title: index % 2 == 1 ? "" : "row \(index) of the tree")
            }
            return AppUITreeRow(
                depth: index % 3, symbol: "doc", title: "row \(index)", detail: "\(index) keys", isExpandable: index % 2 == 0, isExpanded: expanded.contains(index)
            )
        }
    }

    @MainActor
    struct AppUITreeViewTests {
        private func makeView(rows: Int, alternating: Bool = false) -> (AppUITreeView, NumberedTree) {
            let source = NumberedTree(rowCount: rows, alternating: alternating)
            let view = AppUITreeView(frame: CGRect(x: 0, y: 0, width: 360, height: 240))
            view.textColor = .black
            view.canvasColor = .white
            view.source = source
            return (view, source)
        }

        private func ink(in view: AppUITreeView, rows: Range<Int>) -> Int {
            guard let image = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return -1 }
            view.cacheDisplay(in: view.bounds, to: image)
            let scale = CGFloat(image.pixelsHigh) / view.bounds.height
            var count = 0
            for pixelY in max(0, Int(view.top(ofRow: rows.lowerBound) * scale)) ..< min(image.pixelsHigh, Int(view.top(ofRow: rows.upperBound) * scale)) {
                for pixelX in 0 ..< image.pixelsWide - Int(AppUITreeView.scrollerHitWidth * scale) {
                    if let color = image.colorAt(x: pixelX, y: pixelY)?.usingColorSpace(.deviceGray), color.whiteComponent < 0.5 {
                        count += 1
                    }
                }
            }
            return count
        }

        @Test func `a tree of millions of rows is placed to the row, and only the rows in view are asked for`() {
            let rows = 1_766_772
            let (view, source) = makeView(rows: rows)
            defer { withExtendedLifetime(source) {} }
            let height = Double(view.rowHeight)
            for row in [0, 1, 1_000_000, rows - 12] {
                view.position = Double(row) * height
                #expect(view.visibleRows.lowerBound == row)
                #expect(view.rowIndex(at: CGPoint(x: 50, y: 1)) == row)
                #expect(abs(view.top(ofRow: row)) < 1)
            }
            view.position = .greatestFiniteMagnitude
            #expect(view.visibleRows.upperBound == rows)
            #expect(view.visibleText.split(separator: "\n").count == view.visibleRows.count)
        }

        @Test func `rows are drawn at the places of their numbers`() {
            let (view, source) = makeView(rows: 5_000_000, alternating: true)
            defer { withExtendedLifetime(source) {} }
            let height = Double(view.rowHeight)
            for first in [3_000_000, 3_000_001] {
                view.position = Double(first) * height
                let firstBand = ink(in: view, rows: first ..< first + 1)
                let secondBand = ink(in: view, rows: first + 1 ..< first + 2)
                if first % 2 == 0 {
                    #expect(firstBand > 30 && secondBand == 0, "row \(first): \(firstBand), \(secondBand)")
                } else {
                    #expect(firstBand == 0 && secondBand > 30, "row \(first): \(firstBand), \(secondBand)")
                }
            }
        }

        @Test func `a click chooses a row, the chevron of a row that can be opened opens it, and a double click does too`() {
            let (view, source) = makeView(rows: 100)
            defer { withExtendedLifetime(source) {} }
            var chosen: [Int] = []
            var toggled: [Int] = []
            view.onSelect = { chosen.append($0) }
            view.onToggle = { toggled.append($0) }
            let height = view.rowHeight
            // Row 4 is expandable at depth 1: its chevron is at 10 + indentWidth.
            let chevron = CGPoint(x: 10 + view.indentWidth + 4, y: height * 4 + 3)
            let body = CGPoint(x: 200, y: height * 4 + 3)
            view.pressBegan(at: body)
            view.pressEnded(at: body)
            #expect(chosen == [4] && toggled.isEmpty && view.selectedRow == 4)
            view.pressBegan(at: chevron)
            view.pressEnded(at: chevron)
            #expect(toggled == [4])
            view.pressCount = 2
            view.pressBegan(at: body)
            view.pressEnded(at: body)
            #expect(toggled == [4, 4])
            // Row 5 cannot be opened: neither its chevron place nor a single click opens it.
            view.pressCount = 1
            let notExpandable = CGPoint(x: 10 + CGFloat(5 % 3) * view.indentWidth + 4, y: height * 5 + 3)
            view.pressBegan(at: notExpandable)
            #expect(toggled == [4, 4] && view.selectedRow == 5)
            #expect(view.rowIndex(at: CGPoint(x: 10, y: -1)) == nil)
        }

        @Test func `the arrow keys move the choice, open and close it, and the choice stays in view`() throws {
            let (view, source) = makeView(rows: 1000)
            defer { withExtendedLifetime(source) {} }
            var chosen: [Int] = []
            var toggled: [Int] = []
            view.onSelect = { chosen.append($0) }
            view.onToggle = { toggled.append($0) }
            func key(_ special: Int, command: Bool = false) throws -> NSEvent {
                try #require(NSEvent.keyEvent(
                    with: .keyDown, location: .zero, modifierFlags: command ? [.command, .function] : [.function], timestamp: 0, windowNumber: 0, context: nil,
                    characters: String(UnicodeScalar(special) ?? " "), charactersIgnoringModifiers: String(UnicodeScalar(special) ?? " "), isARepeat: false, keyCode: 0
                ))
            }
            try view.keyDown(with: key(NSDownArrowFunctionKey))
            try view.keyDown(with: key(NSDownArrowFunctionKey))
            #expect(chosen == [0, 1] && view.selectedRow == 1)
            // Row 1 cannot be opened; row 2 can: the right arrow opens it, and once it is open the left arrow closes it.
            try view.keyDown(with: key(NSRightArrowFunctionKey))
            #expect(toggled.isEmpty)
            try view.keyDown(with: key(NSDownArrowFunctionKey))
            try view.keyDown(with: key(NSRightArrowFunctionKey))
            #expect(toggled == [2])
            source.expanded = [2]
            view.reload()
            try view.keyDown(with: key(NSRightArrowFunctionKey))
            try view.keyDown(with: key(NSLeftArrowFunctionKey))
            #expect(toggled == [2, 2])
            try view.keyDown(with: key(NSDownArrowFunctionKey, command: true))
            #expect(view.selectedRow == 999 && view.visibleRows.upperBound == 1000)
            try view.keyDown(with: key(NSUpArrowFunctionKey, command: true))
            #expect(view.selectedRow == 0 && view.position == 0)
            for _ in 0 ..< 30 {
                try view.keyDown(with: key(NSDownArrowFunctionKey))
            }
            #expect(view.visibleRows.contains(view.selectedRow ?? -1))
        }

        @Test func `the wheel and the scroller move the view, and the scroller is absent when everything is in view`() throws {
            let (view, source) = makeView(rows: 100_000)
            defer { withExtendedLifetime(source) {} }
            let wheel = try #require(CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: -40, wheel2: 0, wheel3: 0).flatMap { NSEvent(cgEvent: $0) })
            view.scrollWheel(with: wheel)
            #expect(view.position == 40)
            let knob = try #require(view.knobRect)
            view.pressBegan(at: CGPoint(x: view.bounds.width - 5, y: knob.midY))
            view.pressMoved(at: CGPoint(x: view.bounds.width - 5, y: view.bounds.height))
            view.pressEnded(at: .zero)
            #expect(view.position == view.maximumPosition)
            let (small, smallSource) = makeView(rows: 3)
            defer { withExtendedLifetime(smallSource) {} }
            #expect(small.knobRect == nil)
        }

        @Test func `a reload keeps the place and the choice, and a shorter source brings the place back`() {
            let (view, source) = makeView(rows: 1000)
            defer { withExtendedLifetime(source) {} }
            view.position = 5000
            view.selectedRow = 300
            view.reload()
            #expect(view.position == 5000 && view.selectedRow == 300)
            let shorter = NumberedTree(rowCount: 10)
            view.source = shorter
            #expect(view.position == view.maximumPosition)
            withExtendedLifetime(shorter) {}
        }

        @Test func `the rows in view are what assistive technology reads`() {
            let (view, source) = makeView(rows: 50)
            defer { withExtendedLifetime(source) {} }
            let value = view.accessibilityValue() as? String
            #expect(value?.hasPrefix("row 0\t0 keys\nrow 1\t1 keys") == true)
        }
    }
#endif
