//
//  AppUICursor.swift
//  AppUIKit
//
//  A cross-platform cursor. On AppKit it sets the matching NSCursor; on UIKit,
//  where touch input has no pointer, it is a no-op. Lets a cross-platform view
//  show a resize cursor without an #if or a direct NSCursor reference.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#endif
import CoreGraphics

public enum AppUICursor {
    case arrow
    case pointingHand
    case resizeLeftRight
    case resizeUpDown

    public func set() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            nativeCursor.set()
        #endif
    }

    @MainActor
    public func addCursorRect(_ rect: CGRect, in view: AppUIView) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            view.addCursorRect(rect, cursor: nativeCursor)
        #endif
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        private var nativeCursor: NSCursor {
            switch self {
            case .arrow: NSCursor.arrow
            case .pointingHand: NSCursor.pointingHand
            case .resizeLeftRight: NSCursor.resizeLeftRight
            case .resizeUpDown: NSCursor.resizeUpDown
            }
        }
    #endif
}
