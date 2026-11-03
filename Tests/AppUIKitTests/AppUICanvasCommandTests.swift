import Testing
@testable import AppUIKit

/// The multi-finger taps of a touch screen (``AppUICanvas/Command``), after Procreate: two fingers undo, three redo, four toggle the interface.
@Suite("AppUICanvas commands")
struct AppUICanvasCommandTests {
    @Test(arguments: [(2, AppUICanvas.Command.undo), (3, .redo), (4, .toggleInterface)])
    func `a tap with two, three or four fingers is its command`(count: Int, command: AppUICanvas.Command) {
        #expect(AppUICanvas.Command(fingers: count) == command)
        #expect(command.fingers == count, "and the command knows its count")
    }

    @Test(arguments: [-1, 0, 1, 5, 10])
    func `any other number of fingers is no command`(count: Int) {
        #expect(AppUICanvas.Command(fingers: count) == nil)
    }

    @Test
    func `every command has its own count, so no two taps are the same tap`() {
        #expect(Set(AppUICanvas.Command.allCases.map(\.fingers)).count == AppUICanvas.Command.allCases.count)
    }
}
