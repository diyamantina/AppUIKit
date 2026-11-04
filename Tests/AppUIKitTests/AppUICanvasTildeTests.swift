#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import CoreGraphics
    import Testing
    @testable import AppUIKit

    /// The grave accent and tilde key (hardware code 50) is held like Space: a press reports where the pointer is, a repeat is not a press, the release is reported, and Command or
    /// Control with
    /// it is the system's.
    @MainActor
    @Suite("AppUICanvas tilde key")
    struct AppUICanvasTildeTests {
        private func key(_ code: UInt16, down: Bool = true, repeats: Bool = false, flags: NSEvent.ModifierFlags = []) throws -> NSEvent {
            try #require(NSEvent.keyEvent(
                with: down ? .keyDown : .keyUp, location: .zero, modifierFlags: flags, timestamp: 1, windowNumber: 0, context: nil, characters: "", charactersIgnoringModifiers: "",
                isARepeat: repeats, keyCode: code
            ))
        }

        private func collect(_ canvas: AppUICanvas, count: Int) async -> [AppUICanvas.Key] {
            var iterator = canvas.keys.makeAsyncIterator()
            var keys: [AppUICanvas.Key] = []
            for _ in 0 ..< count {
                if let next = await iterator.next() {
                    keys.append(next)
                }
            }
            return keys
        }

        @Test(.timeLimit(.minutes(1)))
        func `the key is held until it comes up, a repeat is not a press, and the press carries the pointer's place`() async throws {
            let canvas = AppUICanvasFixtures.canvas()
            canvas.lastLocation = CGPoint(x: 40, y: 25)
            #expect(!canvas.isTildeHeld)
            try canvas.keyDown(with: key(50))
            #expect(canvas.isTildeHeld)
            try canvas.keyDown(with: key(50, repeats: true))
            try canvas.keyUp(with: key(50, down: false))
            #expect(!canvas.isTildeHeld)
            try canvas.keyDown(with: key(0))
            try canvas.keyDown(with: key(124))
            let keys = await collect(canvas, count: 3)
            #expect(keys.map(\.kind) == [.tilde, .tilde, .arrow(.right)], "the repeat made no key: down, up, then the arrow")
            #expect(keys.map(\.isDown) == [true, false, true])
            #expect(keys[0].location == CGPoint(x: 40, y: 25) && keys[1].location == nil)
        }

        @Test(.timeLimit(.minutes(1)))
        func `a Command or Control with the key is left to the responder chain, and a canvas that stops being the key view lets go`() async throws {
            let canvas = AppUICanvasFixtures.canvas()
            try canvas.keyDown(with: key(50, flags: .command))
            try canvas.keyDown(with: key(50, flags: .control))
            #expect(!canvas.isTildeHeld, "the system's key to cycle windows")
            try canvas.keyDown(with: key(50, flags: .shift))
            #expect(canvas.isTildeHeld, "Shift is the key itself: tilde")
            _ = canvas.resignFirstResponder()
            #expect(!canvas.isTildeHeld)
            let keys = await collect(canvas, count: 2)
            #expect(keys.map(\.isDown) == [true, false] && keys.allSatisfy { $0.kind == .tilde }, "down, then the release the canvas made")
        }
    }
#endif
