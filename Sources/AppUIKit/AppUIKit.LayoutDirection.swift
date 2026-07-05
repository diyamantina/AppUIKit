// AppUIKit.LayoutDirection.swift
// AppUIKit
//
// Cross-platform RTL (Right-to-Left) layout support utilities.
// Provides unified API for handling layout direction in AppKit and UIKit.
// Detection lives in LayoutDirectionManager; node-connection math in
// ConnectionPointCalculator; direction-aware SF Symbols in DirectionalSymbols.

import Foundation

// MARK: - Layout Direction

public extension AppUIKit {
    /// Represents the layout direction for UI content.
    enum LayoutDirection: Sendable {
        case leftToRight
        case rightToLeft

        /// Returns true if this is a right-to-left direction.
        public var isRTL: Bool {
            self == .rightToLeft
        }

        /// Returns true if this is a left-to-right direction.
        public var isLTR: Bool {
            self == .leftToRight
        }

        /// Returns the opposite direction.
        public var flipped: LayoutDirection {
            isRTL ? .leftToRight : .rightToLeft
        }
    }
}

/// Backwards compatibility alias
public typealias LayoutDirection = AppUIKit.LayoutDirection

// MARK: - Platform View Extensions

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    public extension NSView {
        /// The effective layout direction for this view.
        var effectiveLayoutDirection: LayoutDirection {
            LayoutDirectionManager.direction(for: self)
        }

        /// Configures the view for the current layout direction.
        /// Call this in viewDidLoad or after adding subviews.
        func configureForLayoutDirection() {
            // NSView automatically handles RTL through userInterfaceLayoutDirection
            // But subclasses may need additional configuration
            needsLayout = true
        }
    }

    public extension NSViewController {
        /// The effective layout direction for this view controller's view.
        var effectiveLayoutDirection: LayoutDirection {
            view.effectiveLayoutDirection
        }

        /// Configures the view controller for the current layout direction.
        func configureForLayoutDirection() {
            view.configureForLayoutDirection()
        }
    }

#elseif canImport(UIKit)
    public extension UIView {
        /// The effective layout direction for this view.
        var effectiveLayoutDirection: LayoutDirection {
            LayoutDirectionManager.direction(for: self)
        }

        /// Configures the view for automatic RTL flipping.
        /// Call this after setting up the view hierarchy.
        func configureForLayoutDirection() {
            // .unspecified allows the system to determine based on locale
            semanticContentAttribute = .unspecified
            setNeedsLayout()
        }

        /// Forces the view to use a specific layout direction.
        func forceLayoutDirection(_ direction: LayoutDirection) {
            semanticContentAttribute = direction.isRTL ? .forceRightToLeft : .forceLeftToRight
            setNeedsLayout()
        }

        /// Forces the view to ignore layout direction (always LTR).
        /// Use for elements that should never flip, like playback controls.
        func forceLTR() {
            semanticContentAttribute = .playback
            setNeedsLayout()
        }

        /// Forces the view to use spatial semantics (never flip).
        /// Use for elements with fixed spatial meaning, like maps.
        func forceSpatial() {
            semanticContentAttribute = .spatial
            setNeedsLayout()
        }
    }

    public extension UIViewController {
        /// The effective layout direction for this view controller's view.
        var effectiveLayoutDirection: LayoutDirection {
            view.effectiveLayoutDirection
        }

        /// Configures the view controller's view for automatic RTL flipping.
        func configureForLayoutDirection() {
            view.configureForLayoutDirection()
        }

        /// Forces the view controller to use a specific layout direction.
        func forceLayoutDirection(_ direction: LayoutDirection) {
            view.forceLayoutDirection(direction)
        }
    }

    public extension UIStackView {
        /// Configures the stack view for proper RTL behavior.
        /// This ensures items are arranged correctly based on layout direction.
        func configureForRTL() {
            semanticContentAttribute = .unspecified

            // Horizontal stacks need semantic content attribute to flip
            if axis == .horizontal {
                // The stack view will automatically reverse item order in RTL
                // when semanticContentAttribute is .unspecified
            }
        }
    }
#endif

// MARK: - Geometry Utilities

public extension LayoutDirection {
    /// Flips an X coordinate within a given width for RTL.
    /// Use for manual drawing operations that need to respect layout direction.
    func flipX(_ x: CGFloat, in width: CGFloat) -> CGFloat {
        isRTL ? width - x : x
    }

    /// Flips a point horizontally within a given width for RTL.
    func flipPoint(_ point: CGPoint, in width: CGFloat) -> CGPoint {
        CGPoint(x: flipX(point.x, in: width), y: point.y)
    }

    /// Flips a rect horizontally within a given width for RTL.
    func flipRect(_ rect: CGRect, in width: CGFloat) -> CGRect {
        guard isRTL else { return rect }
        return CGRect(
            x: width - rect.maxX,
            y: rect.origin.y,
            width: rect.width,
            height: rect.height
        )
    }

    /// Returns the leading edge X coordinate for a rect.
    /// In LTR this is minX, in RTL this is maxX.
    func leadingX(of rect: CGRect) -> CGFloat {
        isRTL ? rect.maxX : rect.minX
    }

    /// Returns the trailing edge X coordinate for a rect.
    /// In LTR this is maxX, in RTL this is minX.
    func trailingX(of rect: CGRect) -> CGFloat {
        isRTL ? rect.minX : rect.maxX
    }

    // Returns the leading inset from a set of edge insets.
    #if canImport(UIKit)
        func leadingInset(from insets: UIEdgeInsets) -> CGFloat {
            isRTL ? insets.right : insets.left
        }

        /// Returns the trailing inset from a set of edge insets.
        func trailingInset(from insets: UIEdgeInsets) -> CGFloat {
            isRTL ? insets.left : insets.right
        }
    #endif

    // Returns directional edge insets from standard edge insets.
    #if canImport(UIKit)
        func directionalInsets(from insets: UIEdgeInsets) -> NSDirectionalEdgeInsets {
            NSDirectionalEdgeInsets(
                top: insets.top,
                leading: leadingInset(from: insets),
                bottom: insets.bottom,
                trailing: trailingInset(from: insets)
            )
        }
    #endif
}

// MARK: - Image Flipping

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    public extension NSImage {
        /// Returns a horizontally flipped copy of the image for RTL support.
        func flippedHorizontally() -> NSImage {
            let flipped = NSImage(size: size)
            flipped.lockFocus()

            let transform = NSAffineTransform()
            transform.translateX(by: size.width, yBy: 0)
            transform.scaleX(by: -1, yBy: 1)
            transform.concat()

            draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .sourceOver, fraction: 1.0)

            flipped.unlockFocus()
            return flipped
        }

        /// Returns this image or a flipped version based on layout direction.
        func imageForLayoutDirection(_ direction: AppUIKit.LayoutDirection) -> NSImage {
            direction.isRTL ? flippedHorizontally() : self
        }
    }

#elseif canImport(UIKit)
    public extension UIImage {
        /// Returns a horizontally flipped copy of the image for RTL support.
        func flippedHorizontally() -> UIImage {
            guard let cgImage else { return self }
            return UIImage(cgImage: cgImage, scale: scale, orientation: .upMirrored)
        }

        /// Returns this image or a flipped version based on layout direction.
        func imageForLayoutDirection(_ direction: AppUIKit.LayoutDirection) -> UIImage {
            direction.isRTL ? flippedHorizontally() : self
        }

        /// Returns an image configured to flip automatically in RTL.
        func imageWithRTLSupport() -> UIImage {
            imageFlippedForRightToLeftLayoutDirection()
        }
    }
#endif
