#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import Foundation
    import Testing
    @testable import AppUIKit

    /// Rows that can be typed in: the keys that move the caret, the keys that are given to the owner, and the caret being drawn.
    @MainActor
    struct AppUIRowViewEditingTests {
        final class Lines: AppUIRowSource {
            var texts: [String]
            init(_ texts: [String]) {
                self.texts = texts
            }

            var rowCount: Int {
                texts.count
            }

            func rows(in range: Range<Int>) -> [AppUIRow] {
                (max(0, range.lowerBound) ..< min(texts.count, range.upperBound)).map { AppUIRow(text: texts[$0], gutter: "\($0 + 1)") }
            }
        }

        private func makeView(_ texts: [String]) -> (AppUIRowView, Lines) {
            let source = Lines(texts)
            let view = AppUIRowView(frame: CGRect(x: 0, y: 0, width: 480, height: 200))
            view.gutterDigits = 3
            view.source = source
            view.isEditable = true
            return (view, source)
        }

        private func key(_ characters: String, special: NSEvent.SpecialKey? = nil, in view: AppUIRowView) {
            let text = special.flatMap { UnicodeScalar(UInt32($0.rawValue)).map { String(Character($0)) } } ?? characters
            if let event = NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, characters: text, charactersIgnoringModifiers: text,
                isARepeat: false, keyCode: 0
            ) {
                view.keyDown(with: event)
            }
        }

        @Test func `a click puts the caret there, and arrows move it over characters, over the ends of rows and between rows`() {
            let (view, source) = makeView(["abc", "", "e\u{301}f😀g"])
            defer { withExtendedLifetime(source) {} }
            view.setCaret(AppUIRowPosition(row: 0, column: 1))
            #expect(view.caret == AppUIRowPosition(row: 0, column: 1))
            key("", special: .rightArrow, in: view)
            key("", special: .rightArrow, in: view)
            #expect(view.caret == AppUIRowPosition(row: 0, column: 3))
            key("", special: .rightArrow, in: view)
            #expect(view.caret == AppUIRowPosition(row: 1, column: 0), "over the end of a row to the start of the next")
            key("", special: .rightArrow, in: view)
            #expect(view.caret == AppUIRowPosition(row: 2, column: 0))
            key("", special: .rightArrow, in: view)
            #expect(view.caret == AppUIRowPosition(row: 2, column: 2), "e and its accent are one character")
            key("", special: .rightArrow, in: view)
            key("", special: .rightArrow, in: view)
            #expect(view.caret == AppUIRowPosition(row: 2, column: 5), "the emoji is one character of two UTF-16 units")
            key("", special: .leftArrow, in: view)
            #expect(view.caret == AppUIRowPosition(row: 2, column: 3))
            key("", special: .upArrow, in: view)
            #expect(view.caret == AppUIRowPosition(row: 1, column: 0), "up keeps the column as far as the row goes")
            key("", special: .upArrow, in: view)
            #expect(view.caret == AppUIRowPosition(row: 0, column: 0))
            key("", special: .leftArrow, in: view)
            #expect(view.caret == AppUIRowPosition(row: 0, column: 0), "nothing before the first")
            key("", special: .end, in: view)
            #expect(view.caret == AppUIRowPosition(row: 0, column: 3))
            key("", special: .home, in: view)
            #expect(view.caret == AppUIRowPosition(row: 0, column: 0))
        }

        @Test func `typed text and the keys that edit are given to the owner, and keys that are not text are not`() {
            let (view, source) = makeView(["abc"])
            defer { withExtendedLifetime(source) {} }
            var got: [AppUIRowEdit] = []
            view.onEdit = { got.append($0) }
            view.setCaret(AppUIRowPosition(row: 0, column: 0))
            key("x", in: view)
            key("é", in: view)
            key("", special: .delete, in: view)
            key("", special: .deleteForward, in: view)
            key("\r", special: .carriageReturn, in: view)
            key("", special: .tab, in: view)
            key("\u{1B}", in: view)
            #expect(got == [.insert("x"), .insert("é"), .deleteBackward, .deleteForward, .newline, .insert("  ")])
            view.isEditable = false
            key("y", in: view)
            #expect(got.count == 6, "a view that is not editable gives nothing")
        }

        @Test func `an arrow with a selection goes to the end of it that it points to and clears it`() {
            let (view, source) = makeView(["abcdef"])
            defer { withExtendedLifetime(source) {} }
            view.select(AppUIRowPosition(row: 0, column: 2) ... AppUIRowPosition(row: 0, column: 4))
            key("", special: .rightArrow, in: view)
            #expect(view.selection == nil && view.caret == AppUIRowPosition(row: 0, column: 4))
            view.select(AppUIRowPosition(row: 0, column: 2) ... AppUIRowPosition(row: 0, column: 4))
            key("", special: .leftArrow, in: view)
            #expect(view.caret == AppUIRowPosition(row: 0, column: 2))
        }

        @Test func `the caret is held to the rows, scrolled into view, and drawn`() {
            let (view, source) = makeView((0 ..< 500).map { "row \($0)" })
            defer { withExtendedLifetime(source) {} }
            view.appearance = NSAppearance(named: .aqua)
            view.textColor = .black
            view.canvasColor = .white
            view.setCaret(AppUIRowPosition(row: 9999, column: 9999))
            #expect(view.caret == AppUIRowPosition(row: 499, column: 7), "past the end is the end")
            #expect(view.visibleRows.contains(499), "and it is in view")
            view.setCaret(AppUIRowPosition(row: 3, column: 2))
            #expect(view.visibleRows.contains(3))
            func ink(withCaret: Bool) -> Int {
                view.isEditable = withCaret
                guard let image = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return -1 }
                view.cacheDisplay(in: view.bounds, to: image)
                let scale = CGFloat(image.pixelsHigh) / view.bounds.height
                let x = Int((view.gutterWidth + 6 + CGFloat(2) * view.characterWidth) * scale)
                let top = Int(view.top(ofRow: 3) * scale)
                var dark = 0
                for y in top ..< top + Int(view.rowHeight * scale) {
                    for dx in -1 ... 2 where image.colorAt(x: x + dx, y: y)?.usingColorSpace(.deviceGray).map({ $0.whiteComponent < 0.5 }) == true {
                        dark += 1
                    }
                }
                return dark
            }
            #expect(ink(withCaret: true) > ink(withCaret: false), "a line is drawn at the caret")
        }
    }
#endif
