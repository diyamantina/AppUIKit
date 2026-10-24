//
//  AppUIRowSource.swift
//  AppUIKit
//
//  What supplies the rows of a row view.
//

import Foundation

/// Where a row view gets its rows. It is asked for the rows in view and a few beyond, a window at a time, so a source can hold a file of any size and
/// read from it.
@MainActor
public protocol AppUIRowSource: AnyObject {
    /// How many rows there are in all.
    var rowCount: Int { get }
    /// The rows of `range`; fewer when the range runs past the last.
    func rows(in range: Range<Int>) -> [AppUIRow]
}
