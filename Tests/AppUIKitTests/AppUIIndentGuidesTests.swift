import CoreGraphics
import Foundation
import Testing
@testable import AppUIKit

/// The lines through the indentation: how deep a line is, where a guide is, and what it is made of.
struct AppUIIndentGuidesTests {
    @Test func `the unit of the indentation is the smallest indentation among the first lines that have any, from 2 to 8, and 2 when none is indented`() {
        #expect(AppUIIndentGuides.detectUnit(in: "{\n  \"a\": {\n    \"b\": 1\n  }\n}\n") == 2)
        #expect(AppUIIndentGuides.detectUnit(in: "def f():\n    return 1\n") == 4)
        #expect(AppUIIndentGuides.detectUnit(in: "a\nb\n") == 2)
        #expect(AppUIIndentGuides.detectUnit(in: "a\n          b\n") == 8, "held to 8")
        #expect(AppUIIndentGuides.detectUnit(in: "a\n \nb\n") == 2, "a line of spaces alone is not an indentation")
    }

    @Test func `a line is as deep as its leading spaces, a tab is one level, and a blank line has no depth of its own`() {
        #expect(AppUIIndentGuides.depth(of: "    x", unit: 2) == 4)
        #expect(AppUIIndentGuides.depth(of: "\t\tx", unit: 2) == 4)
        #expect(AppUIIndentGuides.depth(of: "  \tx", unit: 4) == 6)
        #expect(AppUIIndentGuides.depth(of: "x", unit: 2) == 0)
        #expect(AppUIIndentGuides.depth(of: "    ", unit: 2) == nil)
        #expect(AppUIIndentGuides.depth(of: "", unit: 2) == nil)
    }

    @Test func `a line has a guide for each whole level before its text, and none runs through the text`() {
        #expect(AppUIIndentGuides.levels(depth: 0, unit: 2) == 0)
        #expect(AppUIIndentGuides.levels(depth: 1, unit: 2) == 0)
        #expect(AppUIIndentGuides.levels(depth: 4, unit: 2) == 2)
        #expect(AppUIIndentGuides.levels(depth: 5, unit: 2) == 2)
        #expect(AppUIIndentGuides.levels(depth: 8, unit: 4) == 2)
    }

    @Test func `a blank line is drawn as deep as the lesser of the lines with text above and below it`() {
        #expect(AppUIIndentGuides.blankDepth(above: 6, below: 4) == 4)
        #expect(AppUIIndentGuides.blankDepth(above: 2, below: 8) == 2)
        #expect(AppUIIndentGuides.blankDepth(above: nil, below: 4) == 0, "the end of the text ends the block")
        #expect(AppUIIndentGuides.blankDepth(above: 4, below: nil) == 0)
    }

    @Test(arguments: [1.0, 2.0, 3.0]) func `a guide is one device pixel wide with its left edge on the pixel grid, at any scale`(_ scale: Double) {
        let scale = CGFloat(scale)
        for x in stride(from: CGFloat(10), through: 20, by: 0.37) {
            let rect = AppUIIndentGuides.rect(x: x, top: 3, bottom: 9, scale: scale)
            #expect(abs(rect.width - 1 / scale) < 1e-9 && rect.height == 6)
            let pixels = rect.minX * scale
            #expect(abs(pixels - pixels.rounded()) < 1e-6, "x \(x) at scale \(scale) is on the grid")
            #expect(rect.minX <= x && x - rect.minX < 1 / scale + 1e-9, "no further than a pixel left of where it was asked for")
        }
    }

    @Test func `the levels have colours of their own, which repeat after six and differ between a light and a dark background`() {
        let colors = (0 ..< 6).map { AppUIIndentGuides.color(level: $0, dark: false) }
        #expect(Set(colors.map { $0.components ?? [] }.map { $0.map { String(format: "%.2f", $0) }.joined(separator: ",") }).count == 6)
        #expect(AppUIIndentGuides.color(level: 6, dark: false) == colors[0])
        #expect(AppUIIndentGuides.color(level: 0, dark: true) != colors[0])
    }
}
