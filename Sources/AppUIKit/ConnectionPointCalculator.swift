// ConnectionPointCalculator.swift
// AppUIKit
//
// Connection-point math for node-based UIs, RTL-aware via semantic leading and
// trailing edges.

import Foundation

/// Utilities for calculating connection points in node-based UIs.
/// These properly handle RTL by using semantic "leading" and "trailing" concepts.
public struct ConnectionPointCalculator {
    public let layoutDirection: LayoutDirection

    /// Creates a calculator with the specified layout direction.
    /// Use `LayoutDirectionManager.currentDirection` from a MainActor context to get the current direction.
    public init(layoutDirection: LayoutDirection = .leftToRight) {
        self.layoutDirection = layoutDirection
    }

    /// Creates a calculator using the current application layout direction.
    /// Must be called from MainActor context.
    @MainActor
    public static func current() -> ConnectionPointCalculator {
        ConnectionPointCalculator(layoutDirection: LayoutDirectionManager.currentDirection)
    }

    /// Returns the output connection point for a node (trailing edge, vertically centered).
    /// In LTR this is the right edge, in RTL this is the left edge.
    public func outputPoint(for frame: CGRect) -> CGPoint {
        CGPoint(
            x: layoutDirection.trailingX(of: frame),
            y: frame.midY
        )
    }

    /// Returns the input connection point for a node (leading edge, vertically centered).
    /// In LTR this is the left edge, in RTL this is the right edge.
    public func inputPoint(for frame: CGRect) -> CGPoint {
        CGPoint(
            x: layoutDirection.leadingX(of: frame),
            y: frame.midY
        )
    }

    /// Returns control points for a bezier curve connecting two nodes.
    /// The curve properly handles RTL by flowing in the correct direction.
    public func bezierControlPoints(from startPoint: CGPoint, to endPoint: CGPoint) -> (cp1: CGPoint, cp2: CGPoint) {
        let deltaX = abs(endPoint.x - startPoint.x)
        let controlOffset = max(deltaX * 0.5, 50)

        let cp1: CGPoint
        let cp2: CGPoint

        if layoutDirection.isRTL {
            // In RTL, connections flow right-to-left
            cp1 = CGPoint(x: startPoint.x - controlOffset, y: startPoint.y)
            cp2 = CGPoint(x: endPoint.x + controlOffset, y: endPoint.y)
        } else {
            // In LTR, connections flow left-to-right
            cp1 = CGPoint(x: startPoint.x + controlOffset, y: startPoint.y)
            cp2 = CGPoint(x: endPoint.x - controlOffset, y: endPoint.y)
        }

        return (cp1, cp2)
    }
}
