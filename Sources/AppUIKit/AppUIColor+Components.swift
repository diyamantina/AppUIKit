import Foundation

public extension AppUIColor {
    /// The red, green, blue and alpha of the colour in sRGB, each 0 to 1, the same on both frameworks: AppKit converts to the sRGB space first, UIKit reads the components. `nil`
    /// for a colour that has none (a pattern).
    var appuiSRGBComponents: (red: Double, green: Double, blue: Double, alpha: Double)? {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            guard let srgb = usingColorSpace(.sRGB) else { return nil }
            return (Double(srgb.redComponent), Double(srgb.greenComponent), Double(srgb.blueComponent), Double(srgb.alphaComponent))
        #elseif canImport(UIKit)
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
            return (Double(red), Double(green), Double(blue), Double(alpha))
        #endif
    }
}
