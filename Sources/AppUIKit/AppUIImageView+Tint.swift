import Foundation

public extension AppUIImageView {
    /// The colour a template image (an SF Symbol) is drawn in: `contentTintColor` on AppKit, `tintColor` on UIKit.
    var appuiContentTintColor: AppUIColor? {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                return contentTintColor
            #elseif canImport(UIKit)
                return tintColor
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                contentTintColor = newValue
            #elseif canImport(UIKit)
                tintColor = newValue
            #endif
        }
    }
}
