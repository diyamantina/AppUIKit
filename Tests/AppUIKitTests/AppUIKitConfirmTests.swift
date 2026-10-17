import Testing
@testable import AppUIKit

/// The yes or no question: built with the title, the message and the two buttons it was given, the confirming one first, and never answered yes when it cannot be asked.
@MainActor
@Suite("AppUIKit confirmation")
struct AppUIKitConfirmTests {
    private let configuration = AppUIConfirmation.Configuration(title: "Send?", message: "It has your source.", confirmTitle: "Send", cancelTitle: "Keep")

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        @Test func `the alert has the title, the message and the confirming button first`() {
            let alert = AppUIConfirmation.make(configuration)
            #expect(alert.messageText == "Send?" && alert.informativeText == "It has your source.")
            #expect(alert.buttons.map(\.title) == ["Send", "Keep"])
        }

        @Test func `a question with no message has an empty line under the title`() {
            let alert = AppUIConfirmation.make(.init(title: "T", message: nil, confirmTitle: "Y", cancelTitle: "N"))
            #expect(alert.informativeText.isEmpty)
        }

        @Test func `a controller whose view is in no window answers no at once`() {
            let controller = AppUIViewController()
            var answers: [Bool] = []
            controller.appuiConfirm(title: "T", confirmTitle: "Y") { answers.append($0) }
            #expect(answers == [false])
        }

        @Test func `sharing a file from a view in no window copies its path`() {
            let view = AppUIView()
            AppUIKit.Sharing.share(fileURL: URL(fileURLWithPath: "/tmp/appui-share-test.zip"), from: view)
            #expect(AppUIPasteboard.general.string(forType: .string) == "/tmp/appui-share-test.zip")
        }
    #elseif canImport(UIKit)
        @Test func `the alert has the title, the message, a cancel and a default confirm`() {
            var answers: [Bool] = []
            let alert = AppUIConfirmation.make(configuration) { answers.append($0) }
            #expect(alert.title == "Send?" && alert.message == "It has your source.")
            #expect(alert.actions.map(\.title) == ["Keep", "Send"] && alert.preferredAction?.title == "Send")
        }
    #endif
}
