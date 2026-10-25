//
//  AppUIIndentGuides.swift
//  AppUIKit
//
//  The vertical lines that show how deep a line is nested.
//

import CoreGraphics
import Foundation

/// The vertical lines drawn through the indentation of source text, one for each level a line is nested in, each level in a colour of its own, so that the
/// shape of the nesting can be followed down a screen of lines. This holds what is the same on every platform: how deep a line is, how deep a blank line is
/// taken to be, what unit the indentation is made in, and the colours.
public enum AppUIIndentGuides {
    /// The width of one level of indentation in spaces that the text seems to be written with: the smallest indentation among its first lines that have any
    /// (2 for most JSON and YAML, 4 for much else), from 2 to 8, and 2 when no line of those is indented.
    public static func detectUnit(in text: String, lines limit: Int = 400) -> Int {
        var smallest = Int.max
        var seen = 0
        for line in text.split(separator: "\n", maxSplits: limit, omittingEmptySubsequences: false).prefix(limit) {
            seen += 1
            let spaces = line.prefix { $0 == " " }.count
            if spaces > 0, spaces < line.count {
                smallest = min(smallest, spaces)
            }
        }
        return smallest == Int.max ? 2 : min(8, max(2, smallest))
    }

    /// How deep a line is in spaces: its leading spaces, with a tab counting as one level of `unit`. A line of nothing but whitespace has no depth of its own, so
    /// nil.
    public static func depth(of line: some StringProtocol, unit: Int) -> Int? {
        var depth = 0
        for character in line {
            switch character {
            case " ": depth += 1
            case "\t": depth += unit
            case "\r", "\n": return nil
            default: return depth
            }
        }
        return nil
    }

    /// How many guides a line of `depth` spaces has: one for each whole level before the text begins, so that none runs through the text itself.
    public static func levels(depth: Int, unit: Int) -> Int {
        unit > 0 ? depth / unit : 0
    }

    /// The depth a blank line is drawn at: the lesser of the nearest lines with text above and below it, so that a guide runs on through a gap that does not end
    /// the block, and stops where the block does.
    public static func blankDepth(above: Int?, below: Int?) -> Int {
        min(above ?? 0, below ?? 0)
    }

    /// The colours of the levels, from the outermost, as red, green and blue components of 0 to 1 for a light and for a dark background. They repeat after six.
    public static let palette: [(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat))] = [
        (light: (0.60, 0.30, 0.75), dark: (0.74, 0.50, 0.90)),
        (light: (0.80, 0.30, 0.30), dark: (0.93, 0.47, 0.47)),
        (light: (0.62, 0.55, 0.10), dark: (0.85, 0.78, 0.35)),
        (light: (0.20, 0.60, 0.35), dark: (0.45, 0.80, 0.58)),
        (light: (0.20, 0.45, 0.80), dark: (0.46, 0.67, 0.93)),
        (light: (0.80, 0.50, 0.15), dark: (0.93, 0.67, 0.38)),
    ]

    /// The colour of level `level` (counting from 0 at the outermost), as it is for the dark or the light background, at the strength guides are drawn.
    public static func color(level: Int, dark: Bool, alpha: CGFloat = 0.45) -> CGColor {
        let entry = palette[level % palette.count]
        let (red, green, blue) = dark ? entry.dark : entry.light
        return CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// A guide as a rectangle one device pixel wide whose left edge is on the pixel grid, `top` to `bottom` high: filled and not stroked, so that it is as sharp
    /// as the screen can make it at any scale, and so that the guides of rows that touch are one line.
    public static func rect(x: CGFloat, top: CGFloat, bottom: CGFloat, scale: CGFloat) -> CGRect {
        let pixel = 1 / max(1, scale)
        return CGRect(x: (x * max(1, scale)).rounded(.down) / max(1, scale), y: top, width: pixel, height: bottom - top)
    }

    /// What the guides of a text are drawn with: the width of a level, where the text begins, how wide a space is, the scale of the screen and the background.
    public struct Geometry {
        public var unit: Int
        public var origin: CGFloat
        public var characterWidth: CGFloat
        public var scale: CGFloat
        public var dark: Bool

        public init(unit: Int, origin: CGFloat, characterWidth: CGFloat, scale: CGFloat, dark: Bool) {
            self.unit = unit
            self.origin = origin
            self.characterWidth = characterWidth
            self.scale = scale
            self.dark = dark
        }
    }

    /// Fills the guides of one line: `levels` of them, level `k` (from 1) at `origin + (k - 1) * unit * characterWidth`, the left edge of its block of
    /// indentation, and in the colour of level `k - 1`, between `top` and `bottom`.
    public static func draw(levels: Int, top: CGFloat, bottom: CGFloat, geometry: Geometry, in context: CGContext) {
        guard levels > 0 else { return }
        context.saveGState()
        context.setShouldAntialias(false)
        for level in 1 ... levels {
            context.setFillColor(color(level: level - 1, dark: geometry.dark))
            let x = geometry.origin + CGFloat((level - 1) * geometry.unit) * geometry.characterWidth
            context.fill(rect(x: x, top: top, bottom: bottom, scale: geometry.scale))
        }
        context.restoreGState()
    }
}
