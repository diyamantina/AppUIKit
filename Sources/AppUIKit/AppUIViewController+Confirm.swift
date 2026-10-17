import Foundation

public extension AppUIViewController {
    /// Asks the person a yes or no question and calls `completion` with the answer. AppKit shows an alert as a sheet of the view's window; UIKit presents an alert controller.
    /// The first button, `confirmTitle`, answers `true` and is the default; the second, `cancelTitle`, answers `false`. When the controller's view is in no window (AppKit)
    /// nothing can be shown and the completion is called with `false` at once, so a question that cannot be asked is never taken as a yes.
    ///
    /// - Parameters:
    ///   - title: the alert's title.
    ///   - message: the line under the title, or `nil`.
    ///   - confirmTitle: the title of the button that says yes; it is the default button.
    ///   - cancelTitle: the title of the button that says no.
    ///   - completion: called once, on the main actor, with the answer.
    func appuiConfirm(
        title: String,
        message: String? = nil,
        confirmTitle: String,
        cancelTitle: String = "Cancel",
        completion: @escaping @MainActor (Bool) -> Void
    ) {
        let configuration = AppUIConfirmation.Configuration(title: title, message: message, confirmTitle: confirmTitle, cancelTitle: cancelTitle)
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            guard let window = view.window else {
                completion(false)
                return
            }
            AppUIConfirmation.make(configuration).beginSheetModal(for: window) { response in
                MainActor.assumeIsolated {
                    completion(response == .alertFirstButtonReturn)
                }
            }
        #elseif canImport(UIKit)
            present(AppUIConfirmation.make(configuration, completion: completion), animated: true)
        #endif
    }
}

/// The alert `appuiConfirm` shows, built apart from showing it so its parts can be read.
enum AppUIConfirmation {
    struct Configuration {
        let title: String
        let message: String?
        let confirmTitle: String
        let cancelTitle: String
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        /// The alert, whose first button says yes and whose second says no.
        @MainActor
        static func make(_ configuration: Configuration) -> AppUIAlert {
            let alert = AppUIAlert()
            alert.messageText = configuration.title
            alert.informativeText = configuration.message ?? ""
            alert.addButton(withTitle: configuration.confirmTitle)
            alert.addButton(withTitle: configuration.cancelTitle)
            return alert
        }
    #elseif canImport(UIKit)
        @MainActor
        static func make(_ configuration: Configuration, completion: @escaping @MainActor (Bool) -> Void) -> AppUIAlertController {
            let alert = AppUIAlertController(title: configuration.title, message: configuration.message, preferredStyle: .alert)
            alert.addAction(AppUIAlertAction(title: configuration.cancelTitle, style: .cancel) { _ in completion(false) })
            let confirm = AppUIAlertAction(title: configuration.confirmTitle, style: .default) { _ in completion(true) }
            alert.addAction(confirm)
            alert.preferredAction = confirm
            return alert
        }
    #endif
}
