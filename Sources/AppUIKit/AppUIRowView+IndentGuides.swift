//
//  AppUIRowView+IndentGuides.swift
//  AppUIKit
//
//  The guides through the indentation of the rows.
//

import CoreGraphics
import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

extension AppUIRowView {
    /// How many device pixels make a point on the screen the view is on.
    var deviceScale: CGFloat {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        #else
            contentScaleFactor
        #endif
    }

    private var isDark: Bool {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        #else
            traitCollection.userInterfaceStyle == .dark
        #endif
    }

    /// How deep the text of a row is, in spaces, or the depth a blank row is drawn at, from the rows near it that are in the cache.
    private func guideDepth(ofRow row: Int, unit: Int) -> Int {
        guard let cached = cache[row] else { return 0 }
        if let own = AppUIIndentGuides.depth(of: cached.row.text, unit: unit) {
            return own
        }
        func nearest(_ step: Int) -> Int? {
            var other = row + step
            while other >= 0, other < rowCount, let near = cache[other], abs(other - row) <= 64 {
                if let depth = AppUIIndentGuides.depth(of: near.row.text, unit: unit) {
                    return depth
                }
                other += step
            }
            return nil
        }
        return AppUIIndentGuides.blankDepth(above: nearest(-1), below: nearest(1))
    }

    /// Draws the guides of one row, from its top to its bottom, so that those of the rows above and below join them.
    func drawIndentGuides(ofRow row: Int, top: CGFloat, textLeft: CGFloat, in context: CGContext) {
        guard let unit = indentGuideUnit, unit > 0 else { return }
        let levels = AppUIIndentGuides.levels(depth: guideDepth(ofRow: row, unit: unit), unit: unit)
        context.saveGState()
        context.clip(to: CGRect(x: textLeft, y: top, width: max(0, bounds.width - textLeft - Self.scrollerHitWidth), height: rowHeight))
        let geometry = AppUIIndentGuides.Geometry(
            unit: unit, origin: textLeft + 6 - horizontalOffset, characterWidth: characterWidth, scale: deviceScale, dark: isDark
        )
        AppUIIndentGuides.draw(levels: levels, top: top, bottom: top + rowHeight, geometry: geometry, in: context)
        context.restoreGState()
    }
}
