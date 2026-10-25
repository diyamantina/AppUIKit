//
//  AppUIRowComposition.swift
//  AppUIKit
//
//  Text that an input method is still composing.
//

import Foundation

/// Text an input method has put at the caret and not yet turned into the text it stands for: kana typed in Japanese before they become characters, the
/// pinyin of Chinese, the jamo of Korean, an accent waiting for its letter. It is shown in the row, underlined, where it will be; the owner of the rows hears
/// nothing of it until it is committed, and then of the committed text only, as one insert.
public struct AppUIRowComposition: Equatable, Sendable {
    /// The row it is in.
    public var row: Int
    /// Where in the row's text it begins, in UTF-16 units.
    public var column: Int
    public var text: String
    /// The part of the composition the input method has selected, or where its insertion point is when the length is zero, in UTF-16 units from the start of
    /// the composition.
    public var selected: NSRange

    public init(row: Int, column: Int, text: String, selected: NSRange) {
        self.row = row
        self.column = column
        self.text = text
        self.selected = selected
    }

    /// The length of the composition, in UTF-16 units.
    public var length: Int {
        (text as NSString).length
    }
}
