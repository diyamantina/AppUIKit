//
//  AppUIRowPosition.swift
//  AppUIKit
//
//  A place in the text of a row view.
//

import Foundation

/// A place in the text of a row view: a row and a UTF-16 offset in its text.
public struct AppUIRowPosition: Comparable, Hashable {
    public var row: Int
    public var column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.row, lhs.column) < (rhs.row, rhs.column)
    }
}
