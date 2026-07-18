import Testing
@testable import AppUIKit

/// AppUIKit is mostly type aliases (checked by the fact that the controls and editors compile against it),
/// so these tests pin the few things that carry real logic: the platform flags, the version, and that the
/// semantic accessors resolve to real platform values rather than trapping.
@Suite("AppUIKit namespace")
struct AppUIKitTests {
    @Test func `exactly one imperative UI framework is active`() {
        // The platform branches are mutually exclusive by construction; this proves the build picked one.
        #expect(isAppKit != isUIKit)
    }

    @Test func `the version is set`() {
        #expect(!AppUIKit.version.isEmpty)
    }

    @Test func `semantic colors resolve to distinct platform colors`() {
        #expect(AppUIKit.Colors.label != AppUIKit.Colors.background)
        #expect(AppUIKit.Colors.accent != AppUIKit.Colors.separator)
        #expect(AppUIKit.Colors.keyboardFocusIndicator != AppUIKit.Colors.separator)
    }

    @Test func `a monospaced-digit font honours the requested size`() {
        #expect(AppUIKit.Fonts.monospacedDigit(size: 17).pointSize == 17)
    }

    @MainActor
    @Test func `top-left views expose the current appearance`() {
        _ = AppUITopLeftView().appuiIsDarkAppearance
    }

    @MainActor
    @Test func `semantic layer colors resolve against a view appearance`() {
        let view = AppUIView()
        view.appuiApplyLayerBackgroundColor(AppUIKit.Colors.background)
        view.appuiApplyLayerBorderColor(AppUIKit.Colors.separator)

        #expect(view.appuiBackgroundColor != nil)
        #expect(view.appuiBorderColor != nil)
    }

    @MainActor
    @Test func `cursor rect helper is callable from cross-platform controls`() {
        let view = AppUIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        AppUICursor.pointingHand.addCursorRect(view.bounds, in: view)
    }

    @MainActor
    @Test func `accessibility identifiers apply through one cross-framework call`() {
        let view = AppUIView()
        view.setAXIdentifier("appuikit.accessibility.probe")

        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            #expect(view.accessibilityIdentifier() == "appuikit.accessibility.probe")
        #elseif canImport(UIKit)
            #expect(view.accessibilityIdentifier == "appuikit.accessibility.probe")
        #endif
    }

    @MainActor
    @Test func `sharing from a detached view falls back to pasteboard`() {
        let text = "share-fallback-\(AppUIKit.version)"

        AppUIKit.Sharing.share(text: text, from: AppUIView())

        #expect(AppUIKit.Pasteboard.paste() == text)
    }

    /// The regression this guards: `deltaX * 0.5` first in `max` leaks NaN through (Swift's
    /// `max`/`min` both return their first argument on a failed NaN comparison, and every
    /// comparison with NaN fails). An infinite endpoint -- reachable via `abs(.infinity -
    /// .infinity)`, itself NaN, from a node-graph document whose stored frame carries an
    /// infinity -- poisoned `controlOffset` and both bezier control points with it.
    @Test func `bezier control points clamp instead of leaking NaN from an infinite endpoint`() {
        let calculator = ConnectionPointCalculator(layoutDirection: .leftToRight)
        let points = calculator.bezierControlPoints(
            from: CGPoint(x: CGFloat.infinity, y: 0),
            to: CGPoint(x: CGFloat.infinity, y: 0)
        )
        #expect(!points.cp1.x.isNaN && !points.cp2.x.isNaN)
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        /// The regression this guards: `NSImage(size: .zero).lockFocus()` raises an uncaught
        /// `NSImageCacheException` ("because it is size zero") that terminates the process. A
        /// zero-size `NSImage` is easy to reach from externally-authored data (the default
        /// `NSImage()` init, or a malformed image file whose decoded representation is
        /// degenerate), and this API is public and generic over any `NSImage`.
        @Test func `flipping a zero-size image does not crash`() {
            let empty = NSImage(size: .zero)
            let flipped = empty.flippedHorizontally()
            #expect(flipped === empty)
        }
    #endif

    #if canImport(SwiftUI)
        @Test func `the SwiftUI view representable alias can be conformed to`() {
            _ = RepresentableProbe()
        }
    #endif
}

#if canImport(SwiftUI)
    private struct RepresentableProbe: AppUIViewRepresentable {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            func makeNSView(context _: Context) -> AppUIView {
                AppUIView()
            }

            func updateNSView(_: AppUIView, context _: Context) {}
        #elseif canImport(UIKit)
            func makeUIView(context _: Context) -> AppUIView {
                AppUIView()
            }

            func updateUIView(_: AppUIView, context _: Context) {}
        #endif
    }
#endif
