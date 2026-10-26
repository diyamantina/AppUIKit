//
//  AppUIKit.LinkActivation.swift
//  AppUIKit
//
//  Whether a plain click or tap follows a link in text. The one place AppKit and UIKit differ here, so a
//  cross-platform view asks and has no #if of its own. A free function, and not a member of `AppUIKit`, so
//  that a client whose own namespace is called AppUIKit can still reach it.
//

/// Whether a plain click or tap follows a link written in text. On the Mac a plain click puts the caret
/// there and following a link takes the Command key; with touch there is no modifier and no caret to
/// put, so a tap follows it.
public func appuiPlainClickFollowsLinks() -> Bool {
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        false
    #else
        true
    #endif
}
