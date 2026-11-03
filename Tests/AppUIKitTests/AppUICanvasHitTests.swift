import CACanvas
import CoreGraphics
import Testing
@testable import AppUIKit

/// `hit(at:)`: a mark beats the items under it, the topmost item comes first, nothing on the backdrop, and the same question under a zoom
/// and a pan. The expected points are worked out by hand from `view = scale * document + offset`.
@MainActor
@Suite("AppUICanvas hit")
struct AppUICanvasHitTests {
    private static func shown(viewport: CACanvas.Viewport) -> AppUICanvas {
        let canvas = AppUICanvasFixtures.canvas()
        // Item 1 covers document 80...120, item 2 (above it) 90...130; a handle lies at document (120, 120).
        let items = [AppUICanvasFixtures.box(1, x: 100, y: 100), AppUICanvasFixtures.box(2, x: 110, y: 110, zOrder: 1)]
        let mark = CACanvas.Mark(id: 9, point: CGPoint(x: 120, y: 120), size: 8, fill: AppUICanvasFixtures.black)
        canvas.surface.apply(items: items, overlay: CACanvas.Overlay(marks: [mark]), viewport: viewport)
        return canvas
    }

    @Test
    func `with no zoom the handle beats the items, the topmost item is first, and the backdrop is none`() {
        let canvas = Self.shown(viewport: CACanvas.Viewport())
        #expect(canvas.hit(at: CGPoint(x: 85, y: 85)) == .items([1]))
        #expect(canvas.hit(at: CGPoint(x: 100, y: 100)) == .items([2, 1]))
        #expect(canvas.hit(at: CGPoint(x: 120, y: 120)) == .mark(9))
        #expect(canvas.hit(at: CGPoint(x: 10, y: 10)) == .none)
    }

    @Test
    func `under zoom 2.5 and a pan the same things are found at the points the arithmetic gives`() {
        // view = 2.5 * document + (30, 20): item 1 spans x 230...330, y 220...320; item 2 x 255...355, y 245...345; the handle is at (330, 320).
        let canvas = Self.shown(viewport: CACanvas.Viewport(scale: 2.5, offset: CGPoint(x: 30, y: 20)))
        #expect(canvas.hit(at: CGPoint(x: 240, y: 230)) == .items([1]))
        #expect(canvas.hit(at: CGPoint(x: 300, y: 300)) == .items([2, 1]))
        #expect(canvas.hit(at: CGPoint(x: 340, y: 335)) == .items([2]))
        #expect(canvas.hit(at: CGPoint(x: 330, y: 320)) == .mark(9))
        #expect(canvas.hit(at: CGPoint(x: 10, y: 10)) == .none)
        // The document point (100, 100) is a hit with no zoom and a miss here: the view point is not the document point.
        #expect(canvas.hit(at: CGPoint(x: 100, y: 100)) == .none)
    }

    @Test
    func `a handle keeps its 28 point target at any zoom`() {
        let canvas = Self.shown(viewport: CACanvas.Viewport(scale: 2.5, offset: CGPoint(x: 30, y: 20)))
        // The target is 14 points from the handle's centre in every direction, in view points, however far the page is zoomed.
        #expect(canvas.hit(at: CGPoint(x: 343, y: 320)) == .mark(9))
        #expect(canvas.hit(at: CGPoint(x: 345, y: 320)) == .items([2]))
    }

    @Test
    func `a canvas with nothing shown answers none everywhere`() {
        let canvas = AppUICanvasFixtures.canvas()
        #expect(canvas.hit(at: .zero) == .none)
        #expect(canvas.hit(at: CGPoint(x: 300, y: 250)) == .none)
        #expect(canvas.hit(at: CGPoint(x: -50, y: 9000)) == .none)
    }
}
