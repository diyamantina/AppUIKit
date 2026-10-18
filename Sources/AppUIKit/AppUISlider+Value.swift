import Foundation

public extension AppUISlider {
    /// Gives the slider a range and a value, and makes it report once, when the person lets go, not on every step of the drag: `isContinuous` is off on both frameworks.
    func appuiConfigure(range: ClosedRange<Double>, value: Double) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            minValue = range.lowerBound
            maxValue = range.upperBound
            isContinuous = false
        #elseif canImport(UIKit)
            minimumValue = Float(range.lowerBound)
            maximumValue = Float(range.upperBound)
            isContinuous = false
        #endif
        appuiValue = value
    }

    /// The value of the slider: `doubleValue` on AppKit, `value` on UIKit.
    var appuiValue: Double {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                return doubleValue
            #elseif canImport(UIKit)
                return Double(value)
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                doubleValue = newValue
            #elseif canImport(UIKit)
                value = Float(newValue)
            #endif
        }
    }

    /// Sends `action` to `target` when the value changes: the control's action on AppKit, the value-changed event on UIKit. Calling it again replaces the earlier target and
    /// action.
    func appuiSetValueAction(target: AnyObject?, action: Selector?) {
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
