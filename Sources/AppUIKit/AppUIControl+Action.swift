import Foundation

public extension AppUIControl {
    /// Sends `action` to `target` when the control is used: a click on AppKit (the control's one target and action), the primary action on UIKit (a tap on a button, a change of a
    /// segmented control's selection, the `primaryActionTriggered` event). Calling it again replaces the earlier target and action on both frameworks.
    func appuiSetPrimaryAction(target: AnyObject?, action: Selector?) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            self.target = target
            self.action = action
        #elseif canImport(UIKit)
            removeTarget(nil, action: nil, for: .primaryActionTriggered)
            if let action {
                addTarget(target, action: action, for: .primaryActionTriggered)
            }
        #endif
    }

    /// The tooltip of the control: `NSView.toolTip` on AppKit and `UIControl.toolTip` on UIKit (shown for a pointer on iPadOS).
    var appuiToolTip: String? {
        get { toolTip }
        set { toolTip = newValue }
    }
}
