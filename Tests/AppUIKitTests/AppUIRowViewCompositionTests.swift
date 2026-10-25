#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import Foundation
    import Testing
    @testable import AppUIKit

    /// Input methods on the Mac: text composed at the caret is shown in the row, underlined, and reaches the owner of the rows once, when it is settled.
    @MainActor
    struct AppUIRowViewCompositionTests {
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

        private static let none = NSRange(location: NSNotFound, length: 0)

        private func makeView(_ texts: [String]) -> (AppUIRowView, Lines) {
            let source = Lines(texts)
            let view = AppUIRowView(frame: CGRect(x: 0, y: 0, width: 480, height: 200))
            view.gutterDigits = 3
            view.textColor = .black
            view.canvasColor = .white
            view.source = source
            view.isEditable = true
            return (view, source)
        }

        private func ink(_ view: AppUIRowView, row: Int) -> Int {
            guard let image = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return -1 }
            view.cacheDisplay(in: view.bounds, to: image)
            let scale = CGFloat(image.pixelsHigh) / view.bounds.height
            var count = 0
            let top = Int(view.top(ofRow: row) * scale)
            for pixelY in max(0, top) ..< min(image.pixelsHigh, top + Int(view.rowHeight * scale)) {
                for pixelX in Int((view.gutterWidth + 4) * scale) ..< image.pixelsWide - 20 {
                    if let color = image.colorAt(x: pixelX, y: pixelY)?.usingColorSpace(.deviceGray), color.whiteComponent < 0.5 {
                        count += 1
                    }
                }
            }
            return count
        }

        @Test func `text being composed is marked, shown in the row at the caret, and not given to the owner until it is settled`() {
            let (view, source) = makeView(["abcd"])
            defer { withExtendedLifetime(source) {} }
            var got: [AppUIRowEdit] = []
            view.onEdit = { got.append($0) }
            view.setCaret(AppUIRowPosition(row: 0, column: 2))
            #expect(!view.hasMarkedText() && view.markedRange().location == NSNotFound)
            view.setMarkedText("にほ", selectedRange: NSRange(location: 2, length: 0), replacementRange: Self.none)
            #expect(view.hasMarkedText() && view.markedRange() == NSRange(location: 2, length: 2))
            #expect(view.selectedRange() == NSRange(location: 4, length: 0), "the insertion point of the input method, in the row as it is shown")
            #expect(view.composedText(ofRow: 0) as String == "abにほcd")
            #expect(got.isEmpty, "the owner hears nothing of it yet")
            view.setMarkedText("日本", selectedRange: NSRange(location: 2, length: 0), replacementRange: Self.none)
            #expect(view.markedRange() == NSRange(location: 2, length: 2) && view.composedText(ofRow: 0) as String == "ab日本cd")
            view.insertText("日本", replacementRange: Self.none)
            #expect(got == [.insert("日本")], "settled, once")
            #expect(!view.hasMarkedText())
        }

        @Test func `the composition is drawn: the row has more ink with it, and none of it is left after it is thrown away`() {
            let (view, source) = makeView(["abcd"])
            defer { withExtendedLifetime(source) {} }
            view.setCaret(AppUIRowPosition(row: 0, column: 4))
            let before = ink(view, row: 0)
            view.setMarkedText("WWWW", selectedRange: NSRange(location: 4, length: 0), replacementRange: Self.none)
            let during = ink(view, row: 0)
            #expect(during > before + 100, "\(before) before, \(during) during: the wide letters and the line under them")
            view.doCommand(by: #selector(NSResponder.cancelOperation(_:)))
            #expect(!view.hasMarkedText() && ink(view, row: 0) == before)
        }

        @Test func `unmarking settles the text as it stands, an empty composition is nothing, and a click settles it before the caret moves`() {
            let (view, source) = makeView(["abcd", "efgh"])
            defer { withExtendedLifetime(source) {} }
            var got: [AppUIRowEdit] = []
            view.onEdit = { got.append($0) }
            view.setCaret(AppUIRowPosition(row: 0, column: 1))
            view.setMarkedText("é", selectedRange: NSRange(location: 1, length: 0), replacementRange: Self.none)
            view.unmarkText()
            #expect(got == [.insert("é")] && !view.hasMarkedText())
            view.setMarkedText("k", selectedRange: NSRange(location: 1, length: 0), replacementRange: Self.none)
            view.setMarkedText("", selectedRange: NSRange(location: 0, length: 0), replacementRange: Self.none)
            #expect(!view.hasMarkedText() && got == [.insert("é")], "taking all of it back is not an edit")
            view.setMarkedText("か", selectedRange: NSRange(location: 1, length: 0), replacementRange: Self.none)
            view.pressCount = 1
            view.handlePressBegan(at: CGPoint(x: view.gutterWidth + 6 + 40, y: view.top(ofRow: 1) + view.rowHeight / 2))
            #expect(got == [.insert("é"), .insert("か")] && !view.hasMarkedText(), "settled where it was composed, and then the caret moved")
        }

        @Test func `a selection is replaced when composing begins, as typing replaces it`() {
            let (view, source) = makeView(["abcdef"])
            defer { withExtendedLifetime(source) {} }
            var got: [AppUIRowEdit] = []
            // The owner takes out what is selected and puts the caret where it was.
            view.onEdit = { edit in
                got.append(edit)
                if edit == .deleteBackward {
                    view.setCaret(AppUIRowPosition(row: 0, column: 1))
                }
            }
            view.setCaret(AppUIRowPosition(row: 0, column: 1))
            view.selectEverything()
            view.setMarkedText("n", selectedRange: NSRange(location: 1, length: 0), replacementRange: Self.none)
            #expect(got == [.deleteBackward])
            #expect(view.markedRange() == NSRange(location: 1, length: 1))
        }

        @Test func `text settled with a range to replace is put over it (the accent menu replaces the letter before the caret)`() {
            let (view, source) = makeView(["abcd"])
            defer { withExtendedLifetime(source) {} }
            var got: [AppUIRowEdit] = []
            view.onEdit = { got.append($0) }
            view.setCaret(AppUIRowPosition(row: 0, column: 3))
            view.insertText("ç", replacementRange: NSRange(location: 2, length: 1))
            #expect(got == [.insert("ç")])
            #expect(
                view.selection == AppUIRowPosition(row: 0, column: 2) ... AppUIRowPosition(row: 0, column: 3),
                "the letter it replaces is selected, so that the insert replaces it"
            )
        }

        @Test func `what the input system asks of the text is answered from the row of the caret as it is shown`() throws {
            let (view, source) = makeView(["abcd"])
            defer { withExtendedLifetime(source) {} }
            view.setCaret(AppUIRowPosition(row: 0, column: 2))
            view.setMarkedText("xy", selectedRange: NSRange(location: 0, length: 2), replacementRange: Self.none)
            #expect(view.selectedRange() == NSRange(location: 2, length: 2))
            var actual = NSRange()
            let text = try #require(view.attributedSubstring(forProposedRange: NSRange(location: 1, length: 100), actualRange: &actual))
            #expect(text.string == "bxycd" && actual == NSRange(location: 1, length: 5))
            let rect = view.rect(ofComposedRange: NSRange(location: 2, length: 2))
            #expect(rect.width > view.characterWidth && rect.height == view.rowHeight && rect.minX > view.gutterWidth)
            #expect(view.validAttributesForMarkedText().isEmpty)
        }

        @Test func `commands from the input system are the keys they stand for`() {
            let (view, source) = makeView(["abcd"])
            defer { withExtendedLifetime(source) {} }
            var got: [AppUIRowEdit] = []
            view.onEdit = { got.append($0) }
            view.doCommand(by: #selector(NSResponder.insertNewline(_:)))
            view.doCommand(by: #selector(NSResponder.deleteBackward(_:)))
            view.doCommand(by: #selector(NSResponder.deleteForward(_:)))
            view.doCommand(by: #selector(NSResponder.insertTab(_:)))
            view.doCommand(by: #selector(NSResponder.moveLeft(_:)))
            #expect(got == [.newline, .deleteBackward, .deleteForward, .insert("  ")])
        }

        @Test func `rows that cannot be edited take no composition`() {
            let (view, source) = makeView(["abcd"])
            defer { withExtendedLifetime(source) {} }
            view.setCaret(AppUIRowPosition(row: 0, column: 1))
            view.isEditable = false
            view.setMarkedText("k", selectedRange: NSRange(location: 1, length: 0), replacementRange: Self.none)
            #expect(!view.hasMarkedText())
            view.isEditable = true
            view.setMarkedText("k", selectedRange: NSRange(location: 1, length: 0), replacementRange: Self.none)
            view.isEditable = false
            #expect(!view.hasMarkedText(), "turning editing off throws the composition away")
        }
    }
#endif
