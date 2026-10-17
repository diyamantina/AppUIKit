import Foundation
import Testing
@testable import AppUIKit

/// The message handed to the system: one recipient, the subject, the body first and then the file, and nothing when there is no file. The effect itself, opening the
/// person's mail app, is not run by a test, since it would open one.
@MainActor
@Suite("AppUIKit email")
struct AppUIKitEmailTests {
    @Test func `a message with a file hands over the body and then the file`() {
        let file = URL(fileURLWithPath: "/tmp/report.zip")
        let parts = AppUIKit.Email.prepared(AppUIEmailMessage(recipient: "a@example.com", subject: "Report", body: "Attached.", attachment: file))
        #expect(parts.recipients == ["a@example.com"] && parts.subject == "Report")
        #expect(parts.items.count == 2)
        #expect(parts.items[0] as? String == "Attached." && parts.items[1] as? URL == file)
    }

    @Test func `a message with no file hands over the body alone`() {
        let parts = AppUIKit.Email.prepared(AppUIEmailMessage(recipient: "a@example.com", subject: "S", body: "B"))
        #expect(parts.items.count == 1 && parts.items[0] as? String == "B")
    }

    @Test func `two messages are equal when every part is`() {
        let a = AppUIEmailMessage(recipient: "r", subject: "s", body: "b", attachment: nil)
        #expect(a == AppUIEmailMessage(recipient: "r", subject: "s", body: "b"))
        #expect(a != AppUIEmailMessage(recipient: "r", subject: "s", body: "other"))
    }
}
