import Testing
@testable import AppUIKit

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    /// The pointer shape of the canvas: a canvas has the arrow until the host sets another.
    @MainActor
    @Suite("AppUICanvas cursor")
    struct AppUICanvasCursorTests {
        @Test
        func `a new canvas has the arrow and the host's shape is kept`() {
            let canvas = AppUICanvasFixtures.canvas()
            #expect(canvas.cursor == .arrow)
            for shape in AppUICanvas.Cursor.allCases {
                canvas.cursor = shape
                #expect(canvas.cursor == shape)
            }
        }

        @Test
        func `the arrow is no cursor rectangle and every other shape is one`() {
            #expect(AppUICanvas.nativeCursor(.arrow) == nil)
            for shape in AppUICanvas.Cursor.allCases where shape != .arrow {
                #expect(AppUICanvas.nativeCursor(shape) != nil, "\(shape) has a system cursor")
            }
            #expect(AppUICanvas.nativeCursor(.openHand) === NSCursor.openHand && AppUICanvas.nativeCursor(.resizeHorizontal) === NSCursor.resizeLeftRight)
        }

        @Test
        func `the rotate cursor is made once and has its hot spot at the middle`() throws {
            let first = try #require(AppUICanvas.nativeCursor(.rotate))
            #expect(first === AppUICanvas.nativeCursor(.rotate), "one object for every request")
            #expect(first.hotSpot == NSPoint(x: first.image.size.width / 2, y: first.image.size.height / 2))
        }
    }
#endif
