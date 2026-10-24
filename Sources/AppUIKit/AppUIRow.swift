//
//  AppUIRow.swift
//  AppUIKit
//
//  A row a row view draws.
//

import Foundation

/// One row of a row view: its text, the label in the gutter beside it (a line number, nil for the slice of a long line that goes on), and the runs of color.
public struct AppUIRow {
    public var text: String
    public var gutter: String?
    public var runs: [AppUIRowRun]

    public init(text: String, gutter: String? = nil, runs: [AppUIRowRun] = []) {
        self.text = text
        self.gutter = gutter
        self.runs = runs
    }
}
