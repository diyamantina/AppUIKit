#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import CoreGraphics
    import Testing
    @testable import AppUIKit

    /// The keys of the canvas (``AppUICanvas/Key``) and the pan by Space and a drag: a key by its hardware code, so any keyboard layout gives the same, and a drag with Space held
    /// is a pan that
    /// makes no sample.
    @MainActor
    @Suite("AppUICanvas keys and pan")
    struct AppUICanvasKeyTests {
        private func key(_ code: UInt16, down: Bool = true, repeats: Bool = false, flags: NSEvent.ModifierFlags = []) throws -> NSEvent {
            try #require(NSEvent.keyEvent(
                with: down ? .keyDown : .keyUp, location: .zero, modifierFlags: flags, timestamp: 1, windowNumber: 0, context: nil, characters: "", charactersIgnoringModifiers: "",
                isARepeat: repeats, keyCode: code
            ))
        }

        private func mouse(_ type: NSEvent.EventType, _ x: Double, _ y: Double) throws -> NSEvent {
            try #require(NSEvent.mouseEvent(
                with: type, location: CGPoint(x: x, y: y), modifierFlags: [], timestamp: 1, windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 1
            ))
        }

        /// A middle button event as the system makes it: from a Core Graphics event, which carries the button number 2 (`NSEvent.mouseEvent` gives 0 to every other-button type).
        private func middle(_ type: CGEventType, _ x: Double, _ y: Double) throws -> NSEvent {
            let made = try #require(CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: CGPoint(x: x, y: y), mouseButton: .center))
            return try #require(NSEvent(cgEvent: made))
        }

        private func next<Element: Sendable>(_ stream: AsyncStream<Element>) async -> Element? {
            var iterator = stream.makeAsyncIterator()
            return await iterator.next()
        }

        @Test(.timeLimit(.minutes(1)), arguments: [
            (UInt16(123), AppUICanvas.KeyKind.arrow(.left)), (124, .arrow(.right)), (125, .arrow(.down)), (126, .arrow(.up)),
            (51, .delete), (117, .delete), (53, .escape), (48, .tab), (36, .return), (76, .return), (49, .space),
        ])
        func `a hardware key code is the key it names`(code: UInt16, kind: AppUICanvas.KeyKind) async throws {
            let canvas = AppUICanvasFixtures.canvas()
            try canvas.keyDown(with: key(code, flags: [.shift, .command]))
            let pressed = try #require(await next(canvas.keys))
            #expect(pressed.kind == kind && pressed.isDown && !pressed.isRepeat)
            #expect(pressed.modifiers == [.shift, .command], "the modifier keys travel with it")
        }

        @Test(.timeLimit(.minutes(1)))
        func `a held key's repeat says so, and a key that is not one of these is left to the responder chain`() async throws {
            let canvas = AppUICanvasFixtures.canvas()
            try canvas.keyDown(with: key(0)) // the letter A: no key of the canvas
            try canvas.keyDown(with: key(124, repeats: true))
            let pressed = try #require(await next(canvas.keys))
            #expect(pressed.kind == .arrow(.right) && pressed.isRepeat, "the first key in the stream is the arrow: the letter made none")
        }

        @Test(.timeLimit(.minutes(1)))
        func `the space bar is held until it comes up, and the canvas lets go of it when it stops being the key view`() async throws {
            let canvas = AppUICanvasFixtures.canvas()
            #expect(!canvas.isSpaceHeld)
            try canvas.keyDown(with: key(49))
            #expect(canvas.isSpaceHeld)
            try canvas.keyDown(with: key(49, repeats: true))
            #expect(canvas.isSpaceHeld, "a repeat changes nothing")
            try canvas.keyUp(with: key(49, down: false))
            #expect(!canvas.isSpaceHeld)
            try canvas.keyDown(with: key(49))
            _ = canvas.resignFirstResponder()
            #expect(!canvas.isSpaceHeld, "a canvas that is no longer the key view cannot see the key come up")
            var iterator = canvas.keys.makeAsyncIterator()
            var downs: [Bool] = []
            for _ in 0 ..< 5 {
                if let event = await iterator.next() {
                    downs.append(event.isDown)
                }
            }
            #expect(downs == [true, true, false, true, false], "down, repeat, up, down, and the release the loss of focus makes")
        }

        @Test(.timeLimit(.minutes(1)))
        func `a drag with space held is a pan that follows the pointer and makes no sample`() async throws {
            let canvas = AppUICanvasFixtures.canvas()
            try canvas.keyDown(with: key(49))
            try canvas.mouseDown(with: mouse(.leftMouseDown, 100, 100))
            try canvas.mouseDragged(with: mouse(.leftMouseDragged, 110, 95))
            try canvas.mouseDragged(with: mouse(.leftMouseDragged, 115, 95))
            try canvas.mouseUp(with: mouse(.leftMouseUp, 115, 95))
            var iterator = canvas.navigation.makeAsyncIterator()
            let first = try #require(await iterator.next()), second = try #require(await iterator.next())
            guard case let .scroll(dx1, dy1, precise1, zooms1, _) = first, case let .scroll(dx2, dy2, _, _, _) = second else {
                Issue.record("not scrolls: \(first) \(second)")
                return
            }
            #expect(precise1 && !zooms1)
            #expect(dx1 != 0 && dx1 + dx2 == 15 || dx1 + dx2 == -15, "the two steps add up to the pointer's travel along x: \(dx1) \(dx2)")
            #expect(dy1 + dy2 == 0 || abs(dy1 + dy2) == 5, "and along y: \(dy1) \(dy2)")
            try canvas.keyUp(with: key(49, down: false))
            // After space comes up a press is a stroke again: the first sample in the stream is that press, not one of the drag.
            try canvas.mouseDown(with: mouse(.leftMouseDown, 50, 50))
            let sample = try #require(await next(canvas.samples))
            #expect(sample.phase == .began, "no sample was made while space was held")
        }

        @Test(.timeLimit(.minutes(1)))
        func `the middle button pans too`() async throws {
            let canvas = AppUICanvasFixtures.canvas()
            try canvas.otherMouseDown(with: middle(.otherMouseDown, 100, 100))
            try canvas.otherMouseDragged(with: middle(.otherMouseDragged, 130, 100))
            try canvas.otherMouseUp(with: middle(.otherMouseUp, 130, 100))
            let step = try #require(await next(canvas.navigation))
            guard case let .scroll(dx, _, _, _, _) = step else {
                Issue.record("not a scroll: \(step)")
                return
            }
            #expect(abs(dx) == 30)
        }
    }
#endif
