import Foundation

public extension AppUITextField {
    /// The text the field holds: `stringValue` on AppKit, `text` on UIKit (empty when it has none).
    var appuiString: String {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                return stringValue
            #elseif canImport(UIKit)
                return text ?? ""
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                stringValue = newValue
            #elseif canImport(UIKit)
                text = newValue
            #endif
        }
    }

    /// The text shown, dimmed, while the field is empty: `placeholderString` on AppKit, `placeholder` on UIKit.
    var appuiPlaceholder: String? {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                return placeholderString
            #elseif canImport(UIKit)
                return placeholder
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                placeholderString = newValue
            #elseif canImport(UIKit)
                placeholder = newValue
            #endif
        }
    }

    /// Whether the person is typing in the field now: it has a field editor on AppKit, it is the first responder on UIKit.
    var appuiIsEditing: Bool {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            return currentEditor() != nil
        #elseif canImport(UIKit)
            return isFirstResponder
        #endif
    }

    /// Ends the editing of the field now: its field editor is released on AppKit and it resigns as first responder on UIKit, so `appuiIsEditing` is false afterwards and an owner
    /// that skips
    /// a field while the person types in it refreshes it again. A field that is not in a window is not editing and nothing happens.
    func appuiEndEditing() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            if currentEditor() != nil {
                window?.makeFirstResponder(nil)
            }
        #elseif canImport(UIKit)
            if isFirstResponder {
                resignFirstResponder()
            }
        #endif
    }

    /// Sends `action` to `target` when the person has finished with the field: on the Return key and when the field loses focus. AppKit sends the field's one action on both once
    /// told to
    /// send it at the end of editing; UIKit has two events for them, `editingDidEndOnExit` (Return) and `editingDidEnd` (focus lost, which Return also causes), so a Return can
    /// send twice
    /// and the owner compares the value with what it already holds. Calling it again replaces the earlier target and action on both frameworks.
    func appuiSetCommitAction(target: AnyObject?, action: Selector?) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            self.target = target
            self.action = action
            (cell as? NSTextFieldCell)?.sendsActionOnEndEditing = true
        #elseif canImport(UIKit)
            removeTarget(nil, action: nil, for: [.editingDidEnd, .editingDidEndOnExit])
            if let action {
                addTarget(target, action: action, for: [.editingDidEnd, .editingDidEndOnExit])
            }
        #endif
    }
}
