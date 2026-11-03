//
//  AppUICanvas.FrameHit.swift
//  AppUIKit
//
//  Where a pointer or a fingertip is on the frame of a selection, and so what a press there does.
//

import CACanvas
import CoreGraphics

public extension AppUICanvas {
    /// Where a pointer is on the frame of a selection, and so what a press there does: the way every drawing app divides it.
    enum FrameHit: Equatable, Sendable {
        /// On a handle or on an edge: a press resizes.
        case handle(FrameHandle)
        /// Just outside a corner, or on the rotation handle: a press rotates.
        case rotate
        /// Inside the frame: a press carries the selection.
        case body
        /// Anywhere else.
        case none

        /// Where the view point `view` is on `frame` (points of the document) under `viewport`, for a pointer of `device`.
        ///
        /// The handles come first, nearest wins and a corner beats a side. A side handle is offered only when its edge is at least four reaches long, so a small frame is not all
        /// handle. Then the
        /// rotation handle drawn above the middle of the top edge. Then the edges: a band across each, so a side is dragged anywhere along it. Then the inside of the frame is the
        /// body; outside it,
        /// within the rotate reach of a corner, is the rotate zone.
        public static func at(_ view: CGPoint, frame: CGRect, viewport: CACanvas.Viewport, device: Device = .mouse) -> FrameHit {
            let reach = FrameReach.of(device)
            let origin = viewport.viewPoint(frame.origin)
            let box = CGRect(x: origin.x, y: origin.y, width: frame.width * viewport.scale, height: frame.height * viewport.scale)
            func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
                hypot(a.x - b.x, a.y - b.y)
            }
            let offered = FrameHandle.allCases.filter { handle in
                if handle.isCorner {
                    return true
                }
                // A side handle needs room along its edge, and something to scale across it: a line has no top to drag.
                return handle.xSign == 0 ? box.width >= 4 * reach.handle && box.height > 0 : box.height >= 4 * reach.handle && box.width > 0
            }
            let near = offered
                .map { (handle: $0, gap: distance($0.point(in: box), view)) }
                .filter { $0.gap <= reach.handle }
                .min { ($0.gap, $0.handle.isCorner ? 0 : 1) < ($1.gap, $1.handle.isCorner ? 0 : 1) }
            if let near {
                return .handle(near.handle)
            }
            let rotation = CGPoint(x: box.midX, y: box.minY - 24 - (reach.handle - 7))
            if distance(rotation, view) <= reach.handle + 1 {
                return .rotate
            }
            let across = min(reach.edge, max(box.width, box.height) / 4)
            let bandX = min(reach.edge, box.width / 4), bandY = min(reach.edge, box.height / 4)
            let withinX = view.x >= box.minX - across && view.x <= box.maxX + across
            let withinY = view.y >= box.minY - across && view.y <= box.maxY + across
            if bandY > 0, withinX, abs(view.y - box.minY) <= bandY {
                return .handle(.top)
            }
            if bandY > 0, withinX, abs(view.y - box.maxY) <= bandY {
                return .handle(.bottom)
            }
            if bandX > 0, withinY, abs(view.x - box.minX) <= bandX {
                return .handle(.left)
            }
            if bandX > 0, withinY, abs(view.x - box.maxX) <= bandX {
                return .handle(.right)
            }
            if box.contains(view) {
                return .body
            }
            let corners = [CGPoint(x: box.minX, y: box.minY), CGPoint(x: box.maxX, y: box.minY), CGPoint(x: box.maxX, y: box.maxY), CGPoint(x: box.minX, y: box.maxY)]
            return corners.contains { distance($0, view) <= reach.rotate } ? .rotate : .none
        }
    }
}
