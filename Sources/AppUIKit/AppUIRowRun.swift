//
//  AppUIRowRun.swift
//  AppUIKit
//
//  A run of color in a row.
//

import Foundation

/// A run of a row's text drawn in its own color, by UTF-16 offsets of the row's text.
public struct AppUIRowRun {
    public var range: Range<Int>
    public var color: AppUIColor
    /// Draws a line under the run, as a link is.
    public var underline: Bool

    public init(range: Range<Int>, color: AppUIColor, underline: Bool = false) {
        self.range = range
        self.color = color
        self.underline = underline
    }
}
