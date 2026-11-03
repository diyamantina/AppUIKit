import CACanvas
import CoreGraphics
import Foundation
@testable import AppUIKit

/// The things the canvas tests build: boxes to show and a canvas of a known size.
@MainActor
enum AppUICanvasFixtures {
    static let black = CGColor(gray: 0, alpha: 1)

    /// A filled square of `side` points whose centre is at `(x, y)` in document space.
    static func box(_ id: UInt64, x: CGFloat, y: CGFloat, side: CGFloat = 40, zOrder: Int = 0) -> CACanvas.Item {
        let local = CGRect(x: 0, y: 0, width: side, height: side)
        let vector = CACanvas.Vector(path: CGPath(rect: local, transform: nil), fill: black)
        return CACanvas.Item(id: id, bounds: local, position: CGPoint(x: x, y: y), zOrder: zOrder, content: .vector(vector))
    }

    /// A canvas of this size whose layout has run.
    static func canvas(width: CGFloat = 600, height: CGFloat = 500) -> AppUICanvas {
        let canvas = AppUICanvas()
        resize(canvas, to: CGSize(width: width, height: height))
        return canvas
    }

    /// Sizes the canvas the way a host does and runs the layout it asks for.
    static func resize(_ canvas: AppUICanvas, to size: CGSize) {
        canvas.frame = CGRect(origin: .zero, size: size)
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            canvas.layoutSubtreeIfNeeded()
        #else
            canvas.layoutIfNeeded()
        #endif
    }

    /// The first `count` samples of the stream. The stream has them already when this is called, or the test fails by its time limit.
    static func take(_ count: Int, from stream: AsyncStream<AppUICanvas.Sample>) async -> [AppUICanvas.Sample] {
        var taken: [AppUICanvas.Sample] = []
        var iterator = stream.makeAsyncIterator()
        while taken.count < count, let next = await iterator.next() {
            taken.append(next)
        }
        return taken
    }
}
