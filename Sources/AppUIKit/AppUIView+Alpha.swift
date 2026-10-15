import Foundation

public extension AppUIView {
    /// The opacity the view is drawn with, 0 to 1: `alphaValue` on AppKit, `alpha` on UIKit.
    var appuiAlpha: CGFloat {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                return alphaValue
            #elseif canImport(UIKit)
                return alpha
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                alphaValue = newValue
            #elseif canImport(UIKit)
                alpha = newValue
            #endif
        }
    }
}
