import Foundation

public extension AppUIViewController {
    /// Asks the person for one line of text and calls `completion` with it, or with `nil` when they cancel. AppKit shows an alert as a sheet of the view's window with a text field
    /// as its
    /// accessory; UIKit presents an alert controller with one text field. The text is passed as typed (not trimmed), and the field's text is returned even when it is empty: what
    /// an empty
    /// answer means is the caller's. When the controller's view is in no window (AppKit) nothing can be shown and the completion is called with `nil` at once.
    ///
    /// - Parameters:
    ///   - title: the alert's title.
    ///   - message: the line under the title, or `nil`.
    ///   - placeholder: the field's placeholder.
    ///   - initialText: the text the field starts with.
    ///   - confirmTitle: the title of the button that accepts; it is the default button.
    ///   - cancelTitle: the title of the button that refuses.
    ///   - fieldIdentifier: the accessibility identifier of the text field, or `nil`.
    ///   - completion: called once, on the main actor, with the text or `nil`.
    func appuiPromptForText(
        title: String,
        message: String? = nil,
        placeholder: String? = nil,
        initialText: String = "",
        confirmTitle: String,
        cancelTitle: String = "Cancel",
        fieldIdentifier: String? = nil,
        completion: @escaping @MainActor (String?) -> Void
    ) {
        let configuration = AppUITextPrompt.Configuration(
            title: title, message: message, placeholder: placeholder, initialText: initialText, confirmTitle: confirmTitle, cancelTitle: cancelTitle,
            fieldIdentifier: fieldIdentifier
        )
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            guard let window = view.window else {
                completion(nil)
                return
            }
            let prompt = AppUITextPrompt.make(configuration)
            prompt.alert.beginSheetModal(for: window) { response in
                MainActor.assumeIsolated {
                    completion(response == .alertFirstButtonReturn ? prompt.field.stringValue : nil)
                }
            }
        #elseif canImport(UIKit)
            let alert = AppUITextPrompt.make(configuration, completion: completion)
            present(alert, animated: true)
        #endif
    }
}

/// The alert `appuiPromptForText` shows, built apart from showing it so its parts can be read.
enum AppUITextPrompt {
    /// What the alert says and carries.
    struct Configuration {
        let title: String
        let message: String?
        let placeholder: String?
        let initialText: String
        let confirmTitle: String
        let cancelTitle: String
        let fieldIdentifier: String?
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        /// The alert and its text field, whose first button accepts and whose second refuses.
        struct Prompt {
            let alert: AppUIAlert
            let field: AppUITextField
        }

        @MainActor
        static func make(_ configuration: Configuration) -> Prompt {
            let alert = AppUIAlert()
            alert.messageText = configuration.title
            alert.informativeText = configuration.message ?? ""
            alert.addButton(withTitle: configuration.confirmTitle)
            alert.addButton(withTitle: configuration.cancelTitle)
            let field = AppUITextField(frame: AppUIRect(x: 0, y: 0, width: 260, height: 24))
            field.appuiString = configuration.initialText
            field.appuiPlaceholder = configuration.placeholder
            if let identifier = configuration.fieldIdentifier {
                field.setAXIdentifier(identifier)
            }
            alert.accessoryView = field
            alert.window.initialFirstResponder = field
            return Prompt(alert: alert, field: field)
        }
    #elseif canImport(UIKit)
        @MainActor
        static func make(_ configuration: Configuration, completion: @escaping @MainActor (String?) -> Void) -> AppUIAlertController {
            let alert = AppUIAlertController(title: configuration.title, message: configuration.message, preferredStyle: .alert)
            alert.addTextField { field in
                field.appuiString = configuration.initialText
                field.appuiPlaceholder = configuration.placeholder
                if let identifier = configuration.fieldIdentifier {
                    field.setAXIdentifier(identifier)
                }
            }
            alert.addAction(AppUIAlertAction(title: configuration.cancelTitle, style: .cancel) { _ in completion(nil) })
            let confirm = AppUIAlertAction(title: configuration.confirmTitle, style: .default) { [weak alert] _ in completion(alert?.textFields?.first?.appuiString) }
            alert.addAction(confirm)
            alert.preferredAction = confirm
            return alert
        }
    #endif
}
