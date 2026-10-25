//
//  AppUIVectorIcon.swift
//  AppUIKit
//
//  A picture made of shapes, drawn at any size in one colour.
//

import CoreGraphics
import Foundation

/// A picture made of paths on a square grid, which a view draws as large as it likes in one colour: the outlines with a line of the width given, and the fillings
/// solid. It is what a row of a tree shows in place of a symbol of the system when whoever supplies the rows has drawn the picture itself.
public struct AppUIVectorIcon: Equatable, Sendable {
    /// One step of a path.
    public enum Step: Equatable, Sendable {
        case move(x: Double, y: Double)
        case line(x: Double, y: Double)
        /// A cubic curve to the last point, by two control points.
        case cubic(x1: Double, y1: Double, x2: Double, y2: Double, x: Double, y: Double)
        /// A line back to where the path began.
        case close
    }

    /// A path, drawn as an outline or as a filling.
    public struct Shape: Equatable, Sendable {
        public var isFilled: Bool
        public var steps: [Step]

        public init(isFilled: Bool, steps: [Step]) {
            self.isFilled = isFilled
            self.steps = steps
        }
    }

    /// The side of the square the shapes are placed on: a place is from 0 to this, from the left and from the top.
    public var grid: Double
    /// How wide the outlines are, in grid units. They are drawn with round ends and joins.
    public var width: Double
    public var shapes: [Shape]

    public init(grid: Double, width: Double, shapes: [Shape]) {
        self.grid = grid
        self.width = width
        self.shapes = shapes
    }

    /// The path of a shape with the grid placed on a square whose top left is `origin` and whose side is `side`.
    func path(of shape: Shape, origin: CGPoint, side: CGFloat) -> CGPath {
        let scale = side / CGFloat(grid)
        func place(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: origin.x + CGFloat(x) * scale, y: origin.y + CGFloat(y) * scale)
        }
        let path = CGMutablePath()
        for step in shape.steps {
            switch step {
            case let .move(x, y): path.move(to: place(x, y))
            case let .line(x, y): path.addLine(to: place(x, y))
            case let .cubic(x1, y1, x2, y2, x, y): path.addCurve(to: place(x, y), control1: place(x1, y1), control2: place(x2, y2))
            case .close: path.closeSubpath()
            }
        }
        return path
    }

    /// Draws the picture in `color` on the square of side `side` centred in `rect`, in a context whose y axis points down.
    func draw(in rect: CGRect, color: CGColor, context: CGContext) {
        let side = min(rect.width, rect.height)
        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
        context.saveGState()
        context.setFillColor(color)
        context.setStrokeColor(color)
        context.setLineWidth(CGFloat(width) * side / CGFloat(grid))
        context.setLineCap(.round)
        context.setLineJoin(.round)
        for shape in shapes {
            context.addPath(path(of: shape, origin: origin, side: side))
            if shape.isFilled {
                context.fillPath()
            } else {
                context.strokePath()
            }
        }
        context.restoreGState()
    }
}
