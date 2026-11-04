#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import CoreGraphics
    import Testing
    @testable import AppUIKit

    /// The X key (hardware code 7) is held like Space: while it is down every report of the canvas carries `Modifiers.marquee`, its press and release are reported as a change of
    /// modifiers at the
    /// pointer's last place, a repeat changes nothing, Command or Control with it is the system's, and a canvas that stops being the key view lets go.
    @MainActor
    @Suite("AppUICanvas X key")
    struct AppUICanvasMarqueeKeyTests {
        private func key(_ code: UInt16, down: Bool = true, repeats: Bool = false, flags: NSEvent.ModifierFlags = []) throws -> NSEvent {
            try #require(NSEvent.keyEvent(
                with: down ? .keyDown : .keyUp, location: .zero, modifierFlags: flags, timestamp: 1, windowNumber: 0, context: nil, characters: "", charactersIgnoringModifiers: "",
                isARepeat: repeats, keyCode: code
            ))
        }

        private func next(_ canvas: AppUICanvas, count: Int) async -> [AppUICanvas.Sample] {
            var iterator = canvas.samples.makeAsyncIterator()
            var found: [AppUICanvas.Sample] = []
            for _ in 0 ..< count {
                if let sample = await iterator.next() {
                    found.append(sample)
                }
            }
            return found
        }

        @Test(.timeLimit(.minutes(1)))
        func `the key is held until it comes up, each change is one report, a repeat is none, and no key event reaches the key stream`() async throws {
            let canvas = AppUICanvasFixtures.canvas()
            canvas.lastLocation = CGPoint(x: 12, y: 7)
            try canvas.keyDown(with: key(7))
            #expect(canvas.isMarqueeHeld)
            try canvas.keyDown(with: key(7, repeats: true))
            try canvas.keyUp(with: key(7, down: false))
            #expect(!canvas.isMarqueeHeld)
            let reports = await next(canvas, count: 2)
            #expect(reports.map(\.phase) == [.modifiersChanged, .modifiersChanged])
            #expect(reports.map(\.modifiers) == [[.marquee], []], "down adds the bit, up takes it away, the repeat made no report")
            #expect(reports.allSatisfy { $0.location == CGPoint(x: 12, y: 7) })
        }

        @Test(.timeLimit(.minutes(1)))
        func `a Command or Control with the key is left to the responder chain, a Shift with it is the key itself, and losing the key view lets go`() async throws {
            let canvas = AppUICanvasFixtures.canvas()
            try canvas.keyDown(with: key(7, flags: .command))
            try canvas.keyDown(with: key(7, flags: .control))
            #expect(!canvas.isMarqueeHeld)
            try canvas.keyDown(with: key(7, flags: .shift))
            #expect(canvas.isMarqueeHeld)
            _ = canvas.resignFirstResponder()
            #expect(!canvas.isMarqueeHeld)
            let reports = await next(canvas, count: 2)
            #expect(reports.map(\.modifiers) == [[.marquee], []])
        }
    }
#endif
