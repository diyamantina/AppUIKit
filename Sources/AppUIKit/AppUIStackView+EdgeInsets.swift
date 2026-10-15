import Foundation

public extension AppUIStackView {
    /// The space the stack keeps between its edges and its arranged views: `edgeInsets` on AppKit; on UIKit the layout margins, which setting this makes the arrangement
    /// respect (`isLayoutMarginsRelativeArrangement`).
    var appuiEdgeInsets: AppUIEdgeInsets {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                return edgeInsets
            #elseif canImport(UIKit)
                return layoutMargins
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                edgeInsets = newValue
            #elseif canImport(UIKit)
                layoutMargins = newValue
                isLayoutMarginsRelativeArrangement = true
            #endif
        }
    }
}
