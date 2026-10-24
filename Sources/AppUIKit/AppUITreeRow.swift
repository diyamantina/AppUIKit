//
//  AppUITreeRow.swift
//  AppUIKit
//
//  A row of a tree view.
//

import Foundation

/// One row of an ``AppUITreeView``: how far in it is, the symbol and words it shows, and whether it can be opened.
public struct AppUITreeRow: Equatable {
    public var depth: Int
    /// The name of an SF Symbol drawn before the title, or nil for none.
    public var symbol: String?
    public var title: String
    /// What is drawn at the right edge, in a smaller type.
    public var detail: String
    public var isExpandable: Bool
    public var isExpanded: Bool
    /// The row is being opened, which takes a while.
    public var isLoading: Bool

    public init(
        depth: Int, symbol: String? = nil, title: String, detail: String = "", isExpandable: Bool = false, isExpanded: Bool = false, isLoading: Bool = false
    ) {
        self.depth = depth
        self.symbol = symbol
        self.title = title
        self.detail = detail
        self.isExpandable = isExpandable
        self.isExpanded = isExpanded
        self.isLoading = isLoading
    }
}
