//
//  AppUITreeSource.swift
//  AppUIKit
//
//  What supplies the rows of a tree view.
//

import Foundation

/// Where a tree view gets its rows: how many there are, and the row at a place. It is asked only for the rows in view, so the rows can be as many as
/// a file has nodes and be made when they are asked for.
@MainActor
public protocol AppUITreeSource: AnyObject {
    var rowCount: Int { get }
    func row(at index: Int) -> AppUITreeRow?
}
