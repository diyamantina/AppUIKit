import CACanvas
import CAWitness
import CoreGraphics
import QuartzCore
import Testing
@testable import AppUIKit

/// What layout and the display scale do to the Surface. The witness is `CAWitness.Stage`: a headless render of the layer tree whose presentation
/// layers show what is on screen. A plain layer put through the same change is the control that proves the test can fail.
@MainActor
@Suite("AppUICanvas layout and scale")
struct AppUICanvasLayoutTests {
    private static func everyLayer(under layer: CALayer) -> [CALayer] {
        [layer] + (layer.sublayers ?? []).flatMap(everyLayer(under:))
    }

    @Test
    func `layout sizes the Surface to the view`() {
        let canvas = AppUICanvasFixtures.canvas(width: 320, height: 200)
        #expect(canvas.surface.bounds == CGRect(x: 0, y: 0, width: 320, height: 200))
        #expect(canvas.surface.position == CGPoint(x: 160, y: 100))
        AppUICanvasFixtures.resize(canvas, to: CGSize(width: 500, height: 400))
        #expect(canvas.surface.bounds == CGRect(x: 0, y: 0, width: 500, height: 400))
        #expect(canvas.surface.position == CGPoint(x: 250, y: 200))
        #expect(canvas.surface.superlayer === canvas.backingLayer)
    }

    @Test
    func `a layout change leaves no animation on the Surface or any host, and the Stage shows the model`() throws {
        let stage = try CAWitness.Stage(width: 800, height: 800)
        let canvas = AppUICanvasFixtures.canvas(width: 300, height: 300)
        canvas.surface.apply(
            items: [AppUICanvasFixtures.box(1, x: 100, y: 100), AppUICanvasFixtures.box(2, x: 200, y: 150)],
            overlay: CACanvas.Overlay(marks: [CACanvas.Mark(id: 5, point: CGPoint(x: 100, y: 100))]),
            viewport: CACanvas.Viewport(scale: 2, offset: CGPoint(x: 10, y: 10))
        )
        // The view's own layer belongs to the view; the Surface is the part under test, so it is shown on the stage while the view lays it out.
        stage.root.addSublayer(canvas.surface)
        stage.settle()
        AppUICanvasFixtures.resize(canvas, to: CGSize(width: 700, height: 600))
        stage.settle()
        let surface = stage.observe(canvas.surface)
        #expect(surface.model == CGPoint(x: 350, y: 300), "the layout reached the Surface")
        #expect(surface.showsModel)
        for layer in Self.everyLayer(under: canvas.surface) {
            #expect((layer.animationKeys() ?? []).isEmpty, "\(type(of: layer)) was animated by the layout")
        }
    }

    @Test
    func `a plain layer put through the same change animates: the control that proves the test can fail`() throws {
        let stage = try CAWitness.Stage(width: 800, height: 800)
        let plain = CALayer()
        plain.bounds = CGRect(x: 0, y: 0, width: 300, height: 300)
        plain.position = CGPoint(x: 150, y: 150)
        stage.root.addSublayer(plain)
        stage.settle()
        plain.bounds = CGRect(x: 0, y: 0, width: 700, height: 600)
        plain.position = CGPoint(x: 350, y: 300)
        stage.settle()
        #expect(!stage.observe(plain).showsModel)
    }

    @Test
    func `a change of the display scale asks the bitmaps again at the new scale, and a repeat does not`() {
        let canvas = AppUICanvasFixtures.canvas()
        var asked: [CGFloat] = []
        canvas.surface.imageProvider = { _, scale in
            asked.append(scale)
            return nil
        }
        var item = AppUICanvasFixtures.box(1, x: 100, y: 100)
        item.content = .bitmap(key: 7)
        canvas.surface.apply(items: [item], overlay: CACanvas.Overlay(), viewport: CACanvas.Viewport(scale: 2.5))
        asked.removeAll()
        // The window the canvas is in sets the scale; a different one is what a move to another screen brings.
        let moved = canvas.surface.displayScale + 1
        canvas.apply(displayScale: moved)
        #expect(canvas.surface.displayScale == moved)
        #expect(asked == [moved * 2.5], "display scale times zoom")
        canvas.apply(displayScale: moved)
        #expect(asked == [moved * 2.5], "an unchanged scale asks for nothing")
        canvas.apply(displayScale: 0)
        #expect(canvas.surface.displayScale == moved, "a scale of 0 is no scale and is ignored")
    }
}
