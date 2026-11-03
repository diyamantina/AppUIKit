#if !(canImport(AppKit) && !targetEnvironment(macCatalyst)) && canImport(UIKit)
    import Testing
    import UIKit
    @testable import AppUIKit

    /// The UIKit half of the canvas's input: the hardware keyboard by HID usage, and the multi-finger taps. These run on an iOS simulator. The recognizers' own recognition of real
    /// touches
    /// needs a device or a UI test; what is proven here is that they are installed with the right counts and that a recognized tap makes its command.
    @MainActor
    @Suite("AppUICanvas on UIKit")
    struct AppUICanvasUIKitInputTests {
        /// A tap recognizer that says it has ended, so its action can be driven without a touch.
        private final class EndedTap: UITapGestureRecognizer {
            override var state: UIGestureRecognizer.State {
                get { .ended }
                set {}
            }
        }

        @Test(arguments: [
            (UIKeyboardHIDUsage.keyboardLeftArrow, AppUICanvas.KeyKind.arrow(.left)), (.keyboardRightArrow, .arrow(.right)), (.keyboardDownArrow, .arrow(.down)), (
                .keyboardUpArrow,
                .arrow(.up)
            ),
            (.keyboardDeleteOrBackspace, .delete), (.keyboardDeleteForward, .delete), (.keyboardEscape, .escape), (.keyboardTab, .tab),
            (.keyboardReturnOrEnter, .return), (.keypadEnter, .return), (.keyboardSpacebar, .space),
        ])
        func `a HID usage is the key it names`(usage: UIKeyboardHIDUsage, kind: AppUICanvas.KeyKind) {
            #expect(AppUICanvas.keyKind(forHIDUsage: usage) == kind)
        }

        @Test
        func `a letter is no key of the canvas`() {
            #expect(AppUICanvas.keyKind(forHIDUsage: .keyboardA) == nil)
        }

        @Test
        func `the canvas has a tap recognizer for two, three and four fingers`() {
            let canvas = AppUICanvasFixtures.canvas()
            let counts = (canvas.gestureRecognizers ?? []).compactMap { ($0 as? UITapGestureRecognizer)?.numberOfTouchesRequired }.sorted()
            #expect(counts == [2, 3, 4])
        }

        @Test(.timeLimit(.minutes(1)), arguments: [(2, AppUICanvas.Command.undo), (3, .redo), (4, .toggleInterface)])
        func `a recognized tap makes its command`(fingers: Int, command: AppUICanvas.Command) async {
            let canvas = AppUICanvasFixtures.canvas()
            let tap = EndedTap()
            tap.numberOfTouchesRequired = fingers
            canvas.multiTapped(tap)
            var iterator = canvas.commands.makeAsyncIterator()
            #expect(await iterator.next() == command)
        }
    }
#endif
