import Testing
@testable import AppUIKit

/// The text field helpers and the prompt for one line of text, which a shared chrome is written against: what the field holds reads back on the framework it ran on, and the prompt
/// is built with the title, the buttons, the placeholder, the starting text and the identifier it was given.
@MainActor
@Suite("AppUIKit text field and text prompt")
struct AppUIKitTextPromptTests {
    /// A target that counts the actions it receives.
    @MainActor
    private final class Receiver: NSObject {
        private(set) var count = 0
        @objc func fire(_: Any?) {
            count += 1
        }
    }

    @Test func `a text field reads back the text and the placeholder it is given`() {
        let field = AppUITextField()
        #expect(field.appuiString == "")
        field.appuiString = "Hello"
        field.appuiPlaceholder = "Text"
        #expect(field.appuiString == "Hello")
        #expect(field.appuiPlaceholder == "Text")
        field.appuiString = ""
        #expect(field.appuiString == "")
    }

    @Test func `a text field that is in no window is not being edited`() {
        #expect(!AppUITextField().appuiIsEditing)
    }

    @Test func `a text field sends its commit action to one target, and a later target replaces it`() {
        let field = AppUITextField()
        let first = Receiver(), second = Receiver()
        field.appuiSetCommitAction(target: first, action: #selector(Receiver.fire(_:)))
        field.appuiSetCommitAction(target: second, action: #selector(Receiver.fire(_:)))
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            #expect(field.target === second)
            #expect(field.action == #selector(Receiver.fire(_:)))
            #expect((field.cell as? NSTextFieldCell)?.sendsActionOnEndEditing == true)
        #elseif canImport(UIKit)
            let ends = field.actions(forTarget: second, forControlEvent: .editingDidEnd) ?? []
            let exits = field.actions(forTarget: second, forControlEvent: .editingDidEndOnExit) ?? []
            #expect(ends == ["fire:"] && exits == ["fire:"])
            #expect(field.actions(forTarget: first, forControlEvent: .editingDidEnd) == nil, "the first target is no longer reached")
            #expect(field.allTargets == [second])
        #endif
    }

    private var configuration: AppUITextPrompt.Configuration {
        AppUITextPrompt.Configuration(
            title: "New Text", message: "Type the line", placeholder: "Text", initialText: "Hi", confirmTitle: "Add", cancelTitle: "Cancel", fieldIdentifier: "prompt_field"
        )
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        @Test func `the prompt is an alert whose first button accepts and whose accessory is the field`() {
            let prompt = AppUITextPrompt.make(configuration)
            #expect(prompt.alert.messageText == "New Text")
            #expect(prompt.alert.informativeText == "Type the line")
            #expect(prompt.alert.buttons.map(\.title) == ["Add", "Cancel"])
            #expect(prompt.alert.accessoryView === prompt.field)
            #expect(prompt.field.appuiString == "Hi")
            #expect(prompt.field.appuiPlaceholder == "Text")
            #expect(prompt.field.accessibilityIdentifier() == "prompt_field")
        }

        @Test func `a prompt asked of a controller in no window answers cancelled at once`() {
            let controller = AppUIViewController()
            controller.view = AppUIView()
            var answers: [String?] = []
            controller.appuiPromptForText(title: "New Text", confirmTitle: "Add") { answers.append($0) }
            #expect(answers.count == 1)
            #expect(answers.first == .some(nil))
        }

        @Test func `a prompt shown as a sheet answers the field's text when the first button is chosen and nil when the second is`() async {
            let window = AppUIWindow(contentRect: AppUIRect(x: 0, y: 0, width: 300, height: 200), styleMask: [.titled], backing: .buffered, defer: false)
            let controller = AppUIViewController()
            controller.view = AppUIView(frame: AppUIRect(x: 0, y: 0, width: 300, height: 200))
            window.contentViewController = controller
            var answers: [String?] = []
            controller.appuiPromptForText(title: "New Text", placeholder: "Text", initialText: "Hi", confirmTitle: "Add") { answers.append($0) }
            let sheet = window.attachedSheet
            #expect(sheet != nil, "the alert is a sheet of the window")
            if let sheet {
                window.endSheet(sheet, returnCode: .alertFirstButtonReturn)
            }
            await Task.yield()
            #expect(answers == ["Hi"])
            controller.appuiPromptForText(title: "New Text", initialText: "Gone", confirmTitle: "Add") { answers.append($0) }
            if let sheet = window.attachedSheet {
                window.endSheet(sheet, returnCode: .alertSecondButtonReturn)
            }
            await Task.yield()
            #expect(answers.count == 2 && answers[1] == nil)
        }
    #elseif canImport(UIKit)
        @Test func `the prompt is an alert with one field and a cancel action and a default accept action`() {
            var answers: [String?] = []
            let alert = AppUITextPrompt.make(configuration) { answers.append($0) }
            #expect(alert.title == "New Text")
            #expect(alert.message == "Type the line")
            #expect(alert.actions.map(\.title) == ["Cancel", "Add"])
            #expect(alert.actions.map(\.style) == [.cancel, .default])
            #expect(alert.preferredAction?.title == "Add")
            let field = alert.textFields?.first
            #expect(alert.textFields?.count == 1)
            #expect(field?.appuiString == "Hi")
            #expect(field?.appuiPlaceholder == "Text")
            #expect(field?.accessibilityIdentifier == "prompt_field")
            #expect(answers.isEmpty)
        }
    #endif
}
