import Testing
@testable import AppUIKit

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
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
    }
#endif
