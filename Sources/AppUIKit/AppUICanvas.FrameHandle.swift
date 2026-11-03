//
//  AppUICanvas.FrameHandle.swift
//  AppUIKit
//

import CoreGraphics

public extension AppUICanvas {
    /// One of the eight resize handles of a selection's frame, clockwise from the top left.
    enum FrameHandle: Int, CaseIterable, Sendable {
        case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left

        /// Which way the handle moves the frame along x: -1 the left edge, 1 the right edge, 0 neither (a handle of the top or the bottom edge).
        public var xSign: Double {
            switch self {
            case .topLeft, .left, .bottomLeft: -1
            case .top, .bottom: 0
            case .topRight, .right, .bottomRight: 1
            }
        }

        /// Which way the handle moves the frame along y, the y axis pointing down: -1 the top edge, 1 the bottom edge, 0 neither.
        public var ySign: Double {
            switch self {
            case .topLeft, .top, .topRight: -1
            case .left, .right: 0
            case .bottomLeft, .bottom, .bottomRight: 1
            }
        }

        /// The handle across the frame: the one that stays put when this one is dragged.
        public var opposite: FrameHandle {
            switch self {
            case .topLeft: .bottomRight
            case .top: .bottom
            case .topRight: .bottomLeft
            case .right: .left
            case .bottomRight: .topLeft
            case .bottom: .top
            case .bottomLeft: .topRight
            case .left: .right
            }
        }

        /// Whether the handle is on a corner.
        public var isCorner: Bool {
            xSign != 0 && ySign != 0
        }

        /// Where the handle is on a frame.
        public func point(in frame: CGRect) -> CGPoint {
            CGPoint(x: frame.midX + CGFloat(xSign) * frame.width / 2, y: frame.midY + CGFloat(ySign) * frame.height / 2)
        }

        /// The pointer shape over the handle: an arrow along the way it drags.
        public var cursor: Cursor {
            switch self {
            case .left, .right: .resizeHorizontal
            case .top, .bottom: .resizeVertical
            case .topLeft, .bottomRight: .resizeDiagonalDown
            case .topRight, .bottomLeft: .resizeDiagonalUp
            }
        }
    }
}
