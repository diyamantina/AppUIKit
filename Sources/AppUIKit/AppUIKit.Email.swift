//  AppUIKit.Email.swift
//  AppUIKit
//
//  Platform-adaptive composing of an email with an attachment, for AppKit and UIKit.

import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
#elseif canImport(UIKit)
    import MessageUI
    import UIKit
#endif

/// What goes in an email composed through ``AppUIKit/Email``: one recipient, a subject, a body, and a file to attach.
public struct AppUIEmailMessage: Equatable, Sendable {
    public let recipient: String
    public let subject: String
    public let body: String
    /// The file to attach, or `nil` for none.
    public let attachment: URL?

    public init(recipient: String, subject: String, body: String, attachment: URL? = nil) {
        self.recipient = recipient
        self.subject = subject
        self.body = body
        self.attachment = attachment
    }
}

public extension AppUIKit {
    /// Platform-adaptive composing of an email: a new message to one address with a subject, a body and a file attached, which the person reads and sends themselves.
    /// Nothing is sent from here; the message is opened in the person's mail app, which sends it when they choose to.
    enum Email {
        /// What the system is given for a message, apart from the system: the recipients, the subject, and the items, the body first and then the attachment, in the
        /// order the sharing service reads them (a string becomes the body, a file becomes an attachment). Held to its closed form by a test.
        public static func prepared(_ message: AppUIEmailMessage) -> (recipients: [String], subject: String, items: [Any]) {
            var items: [Any] = [message.body]
            if let attachment = message.attachment {
                items.append(attachment)
            }
            return ([message.recipient], message.subject, items)
        }

        /// Opens a new message in the person's mail app. Returns `false` when it cannot (no mail account is set up, or on UIKit nothing can present it), and the caller
        /// then offers another way to send the file, so the action is never inert.
        @MainActor
        @discardableResult
        public static func compose(_ message: AppUIEmailMessage, from anchor: AppUIView? = nil) -> Bool {
            let parts = prepared(message)
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                guard let service = NSSharingService(named: .composeEmail) else { return false }
                service.recipients = parts.recipients
                service.subject = parts.subject
                guard service.canPerform(withItems: parts.items) else { return false }
                service.perform(withItems: parts.items)
                return true
            #elseif canImport(UIKit)
                guard MFMailComposeViewController.canSendMail(), let presenter = AppUIMailPresentation.presenter(for: anchor) else { return false }
                let controller = MFMailComposeViewController()
                controller.setToRecipients(parts.recipients)
                controller.setSubject(parts.subject)
                controller.setMessageBody(message.body, isHTML: false)
                if let attachment = message.attachment {
                    // A message that was to carry a file is not sent without it: if the file cannot be read, the mail is not composed, and the caller is told so.
                    let data: Data
                    do {
                        data = try Data(contentsOf: attachment)
                    } catch {
                        return false
                    }
                    controller.addAttachmentData(data, mimeType: "application/zip", fileName: attachment.lastPathComponent)
                }
                AppUIMailPresentation.closeWhenFinished(controller)
                presenter.present(controller, animated: true)
                return true
            #endif
        }
    }
}

#if canImport(UIKit) && !(canImport(AppKit) && !targetEnvironment(macCatalyst))
    /// The UIKit side of composing an email: the view controller to present from, and the delegate that dismisses the compose screen when the person has sent the message
    /// or cancelled it and holds itself until then.
    @MainActor
    private final class AppUIMailPresentation: NSObject, MFMailComposeViewControllerDelegate {
        private static var live: [ObjectIdentifier: AppUIMailPresentation] = [:]

        static func closeWhenFinished(_ controller: MFMailComposeViewController) {
            let closer = AppUIMailPresentation()
            live[ObjectIdentifier(controller)] = closer
            controller.mailComposeDelegate = closer
        }

        /// The view controller that owns `anchor`, or the top one of the foreground scene.
        static func presenter(for anchor: AppUIView?) -> UIViewController? {
            var responder: UIResponder? = anchor
            while let current = responder {
                if let controller = current as? UIViewController {
                    return controller
                }
                responder = current.next
            }
            let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }
            var top = scene?.keyWindow?.rootViewController
            while let next = top?.presentedViewController {
                top = next
            }
            return top
        }

        /// UIKit calls its delegates on the main thread.
        nonisolated func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith _: MFMailComposeResult, error _: Error?) {
            MainActor.assumeIsolated {
                Self.live[ObjectIdentifier(controller)] = nil
                controller.dismiss(animated: true)
            }
        }
    }
#endif
