#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import Foundation
    import Testing
    @testable import AppUIKit

    /// Rows that say what they are, of a count a test chooses, so a view can be held to the rows it ought to show.
    @MainActor
    final class NumberedRows: AppUIRowSource {
        let rowCount: Int
        /// When true only the rows of even number have text, so a picture of the view says which rows it drew.
        let alternating: Bool

        init(rowCount: Int, alternating: Bool = false) {
            self.rowCount = rowCount
            self.alternating = alternating
        }

        func text(of row: Int) -> String {
            alternating && row % 2 == 1 ? "" : "row \(row) of text"
        }

        func rows(in range: Range<Int>) -> [AppUIRow] {
            (max(0, range.lowerBound) ..< min(rowCount, range.upperBound)).map { AppUIRow(text: text(of: $0), gutter: "\($0 + 1)") }
        }
    }

    @MainActor
    struct AppUIRowViewTests {
        private func makeView(rows: Int, alternating: Bool = false, size: CGSize = CGSize(width: 480, height: 200)) -> (AppUIRowView, NumberedRows) {
            let source = NumberedRows(rowCount: rows, alternating: alternating)
            let view = AppUIRowView(frame: CGRect(origin: .zero, size: size))
            view.textColor = .black
            view.canvasColor = .white
            view.gutterColor = .black
            view.selectionColor = .systemBlue
            view.gutterDigits = 9
            view.source = source
            return (view, source)
        }

        /// How many pixels of the band of rows `first` to `first + count` are darker than half, by a picture of the view.
        private func ink(in view: AppUIRowView, rows: Range<Int>) -> Int {
            guard let image = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return -1 }
            view.cacheDisplay(in: view.bounds, to: image)
            let scale = CGFloat(image.pixelsHigh) / view.bounds.height
            let gutter = Int(view.gutterWidth * scale)
            var count = 0
            let from = Int(view.top(ofRow: rows.lowerBound) * scale)
            let to = Int(view.top(ofRow: rows.upperBound) * scale)
            for pixelY in max(0, from) ..< min(image.pixelsHigh, to) {
                for pixelX in gutter ..< image.pixelsWide - Int(AppUIRowView.scrollerHitWidth * scale) {
                    if let color = image.colorAt(x: pixelX, y: pixelY)?.usingColorSpace(.deviceGray), color.whiteComponent < 0.5 {
                        count += 1
                    }
                }
            }
            return count
        }

        @Test func `the rows in view follow the position, and the position stops at both ends`() {
            let (view, source) = makeView(rows: 1000)
            defer { withExtendedLifetime(source) {} }
            let height = view.rowHeight
            view.position = Double(10 * height) + 3
            #expect(view.visibleRows.lowerBound == 10)
            #expect(view.visibleRows.upperBound == Int(((Double(10 * height) + 3 + 200) / Double(height)).rounded(.up)))
            view.position = -50
            #expect(view.position == 0)
            view.position = 1e12
            #expect(view.position == Double(1000 * height) - 200)
            #expect(view.visibleRows.upperBound == 1000)
        }

        @Test func `a file of thirty-seven million rows is placed to the row, at the start, the end and between`() {
            let rows = 37_753_149
            let (view, source) = makeView(rows: rows)
            defer { withExtendedLifetime(source) {} }
            let height = Double(view.rowHeight)
            for row in [0, 1, 16_777_215, 16_777_216, 16_777_217, 33_554_433, rows - 40] {
                view.position = Double(row) * height
                #expect(view.visibleRows.lowerBound == row, "row \(row)")
                #expect(view.rowPosition(at: CGPoint(x: 100, y: 1))?.row == row)
                #expect(abs(view.top(ofRow: row)) < 1, "row \(row) is drawn at the top, a small number")
            }
            view.position = .greatestFiniteMagnitude
            #expect(view.visibleRows.upperBound == rows)
            #expect(view.rowPosition(at: CGPoint(x: 100, y: 199))?.row == rows - 1)
        }

        @Test func `only the rows in view are drawn, at the places of their numbers`() {
            let (view, source) = makeView(rows: 37_753_149, alternating: true)
            defer { withExtendedLifetime(source) {} }
            let height = Double(view.rowHeight)
            // From an even row the first band has text and the second none; from an odd row it is the other way round.
            for first in [30_000_000, 30_000_001] {
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

        @Test func `a point names the row and the character under it`() throws {
            let (view, source) = makeView(rows: 100)
            defer { withExtendedLifetime(source) {} }
            let characterWidth = view.characterWidth
            view.position = Double(view.rowHeight) * 5
            let place = try #require(view.rowPosition(at: CGPoint(x: view.gutterWidth + 6 + characterWidth * 3.2, y: view.rowHeight * 2 + 1)))
            #expect(place.row == 7)
            #expect(place.column == 3)
            let past = try #require(view.rowPosition(at: CGPoint(x: 5000, y: 1)))
            #expect(past.column == view.source?.rows(in: 5 ..< 6).first.map { ($0.text as NSString).length })
            let empty = AppUIRowView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            #expect(empty.rowPosition(at: .zero) == nil)
        }

        @Test func `dragging across rows selects their text, and the text can be read back`() {
            let (view, source) = makeView(rows: 100)
            defer { withExtendedLifetime(source) {} }
            let characterWidth = view.characterWidth
            let rowHeight = view.rowHeight
            let left = view.gutterWidth + 6
            view.pressBegan(at: CGPoint(x: left + characterWidth * 4.2, y: rowHeight * 2 + 2))
            view.pressMoved(at: CGPoint(x: left + characterWidth * 6.2, y: rowHeight * 4 + 2))
            view.pressEnded(at: CGPoint(x: left + characterWidth * 6.2, y: rowHeight * 4 + 2))
            let expected = String(source.text(of: 2).dropFirst(4)) + "\n" + source.text(of: 3) + "\n" + String(source.text(of: 4).prefix(6))
            #expect(view.selectedText() == expected)
            // A backwards drag selects the same way.
            view.pressBegan(at: CGPoint(x: left + characterWidth * 6.2, y: rowHeight * 4 + 2))
            view.pressMoved(at: CGPoint(x: left + characterWidth * 4.2, y: rowHeight * 2 + 2))
            #expect(view.selectedText() == expected)
            view.pressEnded(at: .zero)
        }

        @Test func `a double click selects a word, a triple click a row, and a click that does not move says where it was`() {
            let (view, source) = makeView(rows: 100)
            defer { withExtendedLifetime(source) {} }
            let point = CGPoint(x: view.gutterWidth + 6 + view.characterWidth * 1.2, y: view.rowHeight * 3 + 2)
            var activated: [(AppUIRowPosition, Bool)] = []
            view.onActivate = { activated.append(($0, $1)) }
            view.pressCount = 2
            view.pressBegan(at: point)
            view.pressEnded(at: point)
            #expect(view.selectedText() == "row")
            view.pressCount = 3
            view.pressBegan(at: point)
            view.pressEnded(at: point)
            #expect(view.selectedText() == source.text(of: 3))
            #expect(activated.isEmpty, "a double click is not an activation")
            view.pressCount = 1
            view.pressedWithCommand = true
            view.pressBegan(at: point)
            view.pressEnded(at: point)
            #expect(activated.count == 1 && activated[0].0 == AppUIRowPosition(row: 3, column: 1) && activated[0].1)
            view.pressBegan(at: point)
            view.pressMoved(at: CGPoint(x: point.x + 40, y: point.y))
            view.pressEnded(at: point)
            #expect(activated.count == 1, "a drag is not an activation")
        }

        @Test func `the scroller is dragged, paged and absent when everything is in view`() throws {
            let (view, source) = makeView(rows: 100_000)
            defer { withExtendedLifetime(source) {} }
            let knob = try #require(view.knobRect)
            #expect(knob.minY == 0 && knob.height >= 28)
            view.pressBegan(at: CGPoint(x: view.bounds.width - 5, y: knob.midY))
            view.pressMoved(at: CGPoint(x: view.bounds.width - 5, y: view.bounds.height))
            view.pressEnded(at: CGPoint(x: view.bounds.width - 5, y: view.bounds.height))
            #expect(view.position == view.maximumPosition)
            let end = try #require(view.knobRect)
            #expect(abs(end.maxY - view.bounds.height) < 0.5)
            view.pressBegan(at: CGPoint(x: view.bounds.width - 5, y: 2))
            view.pressEnded(at: CGPoint(x: view.bounds.width - 5, y: 2))
            #expect(view.position < view.maximumPosition, "a click above the knob pages up")
            let (small, smallSource) = makeView(rows: 3)
            defer { withExtendedLifetime(smallSource) {} }
            #expect(small.knobRect == nil)
        }

        @Test func `the wheel and the keys move the view, and say so`() throws {
            let (view, source) = makeView(rows: 10000)
            defer { withExtendedLifetime(source) {} }
            var told: [Double] = []
            view.onPositionChange = { told.append($0) }
            let wheel = try #require(CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: -30, wheel2: 0, wheel3: 0).flatMap { NSEvent(cgEvent: $0) })
            view.scrollWheel(with: wheel)
            #expect(view.position == 30)
            #expect(told == [30])
            func key(_ special: Int, command: Bool = false) throws -> NSEvent {
                try #require(NSEvent.keyEvent(
                    with: .keyDown, location: .zero, modifierFlags: command ? [.command, .function] : [.function], timestamp: 0, windowNumber: 0, context: nil,
                    characters: String(UnicodeScalar(special) ?? " "), charactersIgnoringModifiers: String(UnicodeScalar(special) ?? " "), isARepeat: false, keyCode: 0
                ))
            }
            try view.keyDown(with: key(NSDownArrowFunctionKey))
            #expect(view.position == 30 + Double(view.rowHeight))
            try view.keyDown(with: key(NSPageDownFunctionKey))
            #expect(view.position == 30 + Double(view.rowHeight) + Double(view.bounds.height - view.rowHeight))
            try view.keyDown(with: key(NSDownArrowFunctionKey, command: true))
            #expect(view.position == view.maximumPosition)
            try view.keyDown(with: key(NSUpArrowFunctionKey, command: true))
            #expect(view.position == 0)
        }

        @Test func `the view tells assistive technology the text it shows, and a source that grows is taken again`() {
            let (view, source) = makeView(rows: 50)
            defer { withExtendedLifetime(source) {} }
            view.position = Double(view.rowHeight) * 4
            let value = view.accessibilityValue() as? String
            #expect(value?.hasPrefix("row 4 of text\nrow 5 of text") == true)
            let longer = NumberedRows(rowCount: 500)
            view.source = longer
            #expect(view.rowCount == 500)
            #expect(view.selectedText() == nil)
        }
    }
#endif
