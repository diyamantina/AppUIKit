#if canImport(UIKit) && !(canImport(AppKit) && !targetEnvironment(macCatalyst))
    import UIKit

    /// `NSColor`'s sRGB initializer and component readers, so color code written against AppKit's names reads and builds the same on UIKit. A color made here is
    /// in the extended sRGB space, which is the space `UIColor(red:green:blue:alpha:)` makes, and the readers answer what `getRed(_:green:blue:alpha:)` answers
    /// for it; a color that is not an RGB one (a pattern) reads as zero in every component and one for alpha, never as a guess.
    public extension UIColor {
        convenience init(srgbRed red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        }

        /// The red, green, blue and alpha of the color, or nil when it has no such components.
        private var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            return getRed(&red, green: &green, blue: &blue, alpha: &alpha) ? (red, green, blue, alpha) : nil
        }

        var redComponent: CGFloat {
            rgba?.red ?? 0
        }

        var greenComponent: CGFloat {
            rgba?.green ?? 0
        }

        var blueComponent: CGFloat {
            rgba?.blue ?? 0
        }

        var alphaComponent: CGFloat {
            rgba?.alpha ?? 1
        }
    }
#endif
