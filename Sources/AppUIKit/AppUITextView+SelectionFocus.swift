//
//  AppUITextView+SelectionFocus.swift
//  AppUIKit
//
//  Whether a text view draws its selection when it is not the one being typed in.
//

/// Whether a text view draws its selection while it is not the one being typed in. A Mac draws it (in a quiet color); a touch screen draws it only while the text view
/// holds the keyboard, so a text chosen from another place, such as an outline on another page of a phone, shows nothing of the choice unless it is drawn another way.
public func appuiShowsSelectionWithoutFocus() -> Bool {
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        true
    #else
        false
    #endif
}
