import Foundation

public extension AppUIColorWell {
    /// The colour of the well: `color` on AppKit, `selectedColor` on UIKit (which has none until one is chosen, so a missing one reads as black).
    var appuiColor: AppUIColor {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                return color
            #elseif canImport(UIKit)
                return selectedColor ?? .black
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                color = newValue
            #elseif canImport(UIKit)
                selectedColor = newValue
            #endif
        }
    }

    /// Sends `action` to `target` when the person chooses a colour: the control's action on AppKit, the value-changed event on UIKit. Calling it again replaces the earlier target
    /// and action.
    func appuiSetColorAction(target: AnyObject?, action: Selector?) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            self.target = target
            self.action = action
        #elseif canImport(UIKit)
            removeTarget(nil, action: nil, for: .valueChanged)
            if let action {
                addTarget(target, action: action, for: .valueChanged)
            }
        #endif
    }
}
