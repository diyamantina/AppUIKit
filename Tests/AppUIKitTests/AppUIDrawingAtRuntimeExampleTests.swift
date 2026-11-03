#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import Testing
    @testable import AppUIKit

    /// The Drawing at runtime article's stroke example, kept here so it is compiled and run: the press handlers
    /// only record a point and mark the small rectangle that changed; the drawing happens in `draw(_:)`.
    private final class StrokeView: AppUIInteractiveView {
        private(set) var points: [CGPoint] = []
        let lineWidth: CGFloat = 4
        /// A point closer than this to the previous one (squared, in points) is skipped.
        let minimumDistanceSquared: CGFloat = 4

        /// The bounding box of a segment, grown by half the line width: with round caps and joins nothing the
        /// segment paints lies outside it.
        static func dirtyRect(from start: CGPoint, to end: CGPoint, lineWidth: CGFloat) -> CGRect {
            CGRect(x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y))
                .insetBy(dx: -lineWidth / 2, dy: -lineWidth / 2)
        }

        override func pressBegan(at point: CGPoint) {
            points = [point]
            setNeedsDisplay(Self.dirtyRect(from: point, to: point, lineWidth: lineWidth))
        }

        override func pressMoved(at point: CGPoint) {
            guard let last = points.last else {
                return
            }
            let dx = point.x - last.x
            let dy = point.y - last.y
            guard dx * dx + dy * dy >= minimumDistanceSquared else {
                return
            }
            points.append(point)
            setNeedsDisplay(Self.dirtyRect(from: last, to: point, lineWidth: lineWidth))
        }

        override func draw(_: CGRect) {
            guard let context = AppUIKit.currentCGContext(), let first = points.first, points.count > 1 else {
                return
            }
            context.setStrokeColor(CGColor(gray: 0, alpha: 1))
            context.setLineWidth(lineWidth)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.move(to: first)
            for point in points.dropFirst() {
                context.addLine(to: point)
            }
            context.strokePath()
        }
    }

    /// The article's hit-testing helper: the presentation tree when there is one, mapped back to the model layer.
    private func hitLayer(at point: CGPoint, in root: CALayer) -> CALayer? {
        (root.presentation() ?? root).hitTest(point)?.model()
    }

    @MainActor
    struct AppUIDrawingAtRuntimeExampleTests {
        @Test func `the hit-testing helper finds the child under a point and nothing outside the tree`() {
            let root = CALayer()
            root.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            let child = CALayer()
            child.frame = CGRect(x: 10, y: 10, width: 20, height: 20)
            root.addSublayer(child)
            #expect(hitLayer(at: CGPoint(x: 15, y: 15), in: root) === child)
            #expect(hitLayer(at: CGPoint(x: 50, y: 50), in: root) === root)
            #expect(hitLayer(at: CGPoint(x: 150, y: 50), in: root) == nil)
        }

        @Test func `the dirty rectangle of a segment is its bounding box grown by half the line width`() {
            let rect = StrokeView.dirtyRect(from: CGPoint(x: 30, y: 10), to: CGPoint(x: 10, y: 20), lineWidth: 4)
            #expect(rect == CGRect(x: 8, y: 8, width: 24, height: 14))
            let dot = StrokeView.dirtyRect(from: CGPoint(x: 5, y: 5), to: CGPoint(x: 5, y: 5), lineWidth: 4)
            #expect(dot == CGRect(x: 3, y: 3, width: 4, height: 4))
        }

        @Test func `a press records points and skips one too close to the last`() {
            let view = StrokeView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            view.pressBegan(at: CGPoint(x: 5, y: 20))
            view.pressMoved(at: CGPoint(x: 6, y: 20))
            view.pressMoved(at: CGPoint(x: 35, y: 20))
            #expect(view.points == [CGPoint(x: 5, y: 20), CGPoint(x: 35, y: 20)])
        }

        @Test func `the stroke is drawn by draw and not by the press handler`() throws {
            let view = StrokeView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            view.pressBegan(at: CGPoint(x: 5, y: 20))
            view.pressMoved(at: CGPoint(x: 35, y: 20))
            let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
            view.cacheDisplay(in: view.bounds, to: bitmap)
            let scale = CGFloat(bitmap.pixelsWide) / view.bounds.width
            let onStroke = try #require(bitmap.colorAt(x: Int(20 * scale), y: Int(20 * scale)))
            let offStroke = bitmap.colorAt(x: Int(20 * scale), y: Int(5 * scale))
            #expect(onStroke.alphaComponent > 0.9)
            #expect((offStroke?.alphaComponent ?? 0) < 0.1)
        }

        /// `AppUIInteractiveView` overrides `scrollWheel(with:)`, and AppKit reports a class that does as not
        /// compatible with responsive scrolling; `AppUITopLeftView` does not override it and stays compatible.
        /// The article's section on scrolling rests on this.
        @Test func `the interactive view gives up responsive scrolling and the top-left view keeps it`() {
            #expect(AppUITopLeftView.isCompatibleWithResponsiveScrolling)
            #expect(!AppUIInteractiveView.isCompatibleWithResponsiveScrolling)
        }
    }
#endif
