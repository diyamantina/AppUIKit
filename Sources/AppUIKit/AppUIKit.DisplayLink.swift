//
//  AppUIKit.DisplayLink.swift
//  AppUIKit
//
//  A cross-platform per-vsync callback. On UIKit a `CADisplayLink` is created
//  directly; on AppKit it is vended by the view (the macOS 14+ API), since a
//  display link there is bound to the screen the view is on. Both return the same
//  `CADisplayLink`, so callers add it to a run loop and invalidate it the same way.
//

import QuartzCore

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

public extension AppUIView {
    /// Makes a `CADisplayLink` that calls `selector` on `target` once per display
    /// refresh. The caller adds it to a run loop and invalidates it when done.
    func makeDisplayLink(target: Any, selector: Selector) -> CADisplayLink {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            return displayLink(target: target, selector: selector)
        #else
            return CADisplayLink(target: target, selector: selector)
        #endif
    }
}
