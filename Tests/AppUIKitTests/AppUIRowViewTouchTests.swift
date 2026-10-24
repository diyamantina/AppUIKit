#if canImport(UIKit) && !canImport(AppKit)
    import Foundation
    import Testing
    import UIKit
    @testable import AppUIKit

    /// What a finger does to a row view, driven through the same entry points the recognizers call.
    @MainActor
    struct AppUIRowViewTouchTests {
        final class Rows: AppUIRowSource {
            let rowCount: Int
            init(rowCount: Int) {
                self.rowCount = rowCount
            }

            func rows(in range: Range<Int>) -> [AppUIRow] {
                (max(0, range.lowerBound) ..< min(rowCount, range.upperBound)).map { AppUIRow(text: "alpha beta \($0)", gutter: "\($0 + 1)") }
            }
        }

        private func makeView(rows: Int = 2000) -> (AppUIRowView, Rows) {
            let source = Rows(rowCount: rows)
            let view = AppUIRowView(frame: CGRect(x: 0, y: 0, width: 600, height: 400))
            view.gutterDigits = 5
            view.source = source
            return (view, source)
        }

        private func textPoint(_ view: AppUIRowView, row: Int, character: Int) -> CGPoint {
            CGPoint(x: view.gutterWidth + 6 + (Double(character) + 0.5) * view.characterWidth, y: view.top(ofRow: row) + view.rowHeight / 2)
        }

        @Test func `a flick goes on moving the rows, slows, and ends a distance the speed gives`() {
            let (view, source) = makeView()
            defer { withExtendedLifetime(source) {} }
            view.touchPanBegan(at: CGPoint(x: 100, y: 300))
            view.touchPanChanged(by: CGPoint(x: 0, y: -40), at: CGPoint(x: 100, y: 260))
            let released = view.position
            #expect(released == 40, "the rows follow the finger: it went up, the rows go down")
            view.touchPanEnded(velocity: CGPoint(x: 0, y: -2000), at: CGPoint(x: 100, y: 260))
            #expect(view.momentum != nil)
            var frames = 0
            while view.momentum != nil, frames < 10000 {
                view.advanceMomentum(by: 1.0 / 60)
                frames += 1
            }
            #expect(frames < 10000)
            let gone = view.position - released
            let expected = AppUIRowMomentum.reach(of: 2000) - AppUIRowMomentum.reach(of: AppUIRowMomentum.stopsBelow)
            #expect(abs(gone - expected) < 2, "went \(gone), the speed gives \(expected)")
        }

        @Test func `a flick up at the end of the rows ends at the end and a touch stops one`() {
            let (view, source) = makeView(rows: 60)
            defer { withExtendedLifetime(source) {} }
            view.touchPanBegan(at: CGPoint(x: 100, y: 300))
            view.touchPanEnded(velocity: CGPoint(x: 0, y: -50000), at: CGPoint(x: 100, y: 300))
            var frames = 0
            while view.momentum != nil, frames < 1000 {
                view.advanceMomentum(by: 1.0 / 60)
                frames += 1
            }
            #expect(view.position == view.maximumPosition, "it stops at the end and does not go past it")
            view.position = 0
            view.touchPanEnded(velocity: CGPoint(x: 0, y: -3000), at: .zero)
            #expect(view.momentum != nil)
            view.touchPanBegan(at: CGPoint(x: 100, y: 100))
            #expect(view.momentum == nil, "a finger put down stops the rows")
        }

        @Test func `a finger on the scroller takes the knob and moves the rows with it, from further in than a pointer needs`() throws {
            let (view, source) = makeView()
            defer { withExtendedLifetime(source) {} }
            let knob = try #require(view.knobRect)
            let x = view.bounds.width - 24
            #expect(x < view.bounds.width - AppUIRowView.scrollerHitWidth, "this is outside where a pointer would take hold")
            view.touchPanBegan(at: CGPoint(x: x, y: knob.midY))
            #expect(view.touchOnScroller)
            view.touchPanChanged(by: CGPoint(x: 0, y: 60), at: CGPoint(x: x, y: knob.midY + 60))
            let moved = view.position
            #expect(moved > 0, "the knob went down, and so did the rows")
            #expect(abs(moved / view.maximumPosition - 60 / (view.bounds.height - knob.height)) < 0.01)
            view.touchPanEnded(velocity: CGPoint(x: 0, y: 3000), at: CGPoint(x: x, y: knob.midY + 60))
            #expect(view.momentum == nil, "the scroller is not flicked")
            #expect(!view.touchOnScroller)
        }

        @Test func `holding a finger selects the word under it, moving it takes the selection along, and lifting ends it`() {
            let (view, source) = makeView()
            defer { withExtendedLifetime(source) {} }
            view.touchLongPress(.began, at: textPoint(view, row: 3, character: 1))
            #expect(view.selection == AppUIRowPosition(row: 3, column: 0) ... AppUIRowPosition(row: 3, column: 5), "alpha")
            view.touchLongPress(.changed, at: textPoint(view, row: 5, character: 8))
            #expect(view.selection?.upperBound.row == 5)
            view.touchLongPress(.ended, at: textPoint(view, row: 5, character: 8))
            #expect(view.pressCount == 1)
            #expect(view.selection != nil)
            #expect(view.selectedText()?.hasPrefix("alpha beta 3\nalpha beta 4\n") == true)
        }
    }
#endif
