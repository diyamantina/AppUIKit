#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import CoreGraphics
    import Testing
    @testable import AppUIKit

    /// Events that AppKit would deliver, made by hand and sent through the window, become samples in order with the location in the view's
    /// own top-left points.
    @MainActor
    @Suite("AppUICanvas on AppKit")
    struct AppUICanvasAppKitEventTests {
        /// A window whose content is 400 by 300 with the canvas at (20, 30), 200 wide and 150 tall. The window's y axis points up, so the
        /// canvas's top edge is at window y 180.
        private struct Rig {
            let window: NSWindow
            let canvas: AppUICanvas

            init() {
                _ = NSApplication.shared
                window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 400, height: 300), styleMask: [.titled], backing: .buffered, defer: false)
                canvas = AppUICanvas()
                canvas.frame = CGRect(x: 20, y: 30, width: 200, height: 150)
                window.contentView?.addSubview(canvas)
                canvas.layoutSubtreeIfNeeded()
                // A window sends events only once it is on screen; at zero alpha nothing is seen of it.
                window.alphaValue = 0
                window.orderFront(nil)
            }

            /// The window point of a view point: x is shifted by the canvas's left edge, y runs from the canvas's top (180) downward.
            func windowPoint(_ view: CGPoint) -> CGPoint {
                CGPoint(x: 20 + view.x, y: 180 - view.y)
            }

            func event(_ type: NSEvent.EventType, at view: CGPoint, time: TimeInterval, flags: NSEvent.ModifierFlags = []) throws -> NSEvent {
                try #require(NSEvent.mouseEvent(
                    with: type, location: windowPoint(view), modifierFlags: flags, timestamp: time, windowNumber: window.windowNumber,
                    context: nil, eventNumber: 0, clickCount: 1, pressure: 1
                ))
            }
        }

        @Test(.timeLimit(.minutes(1)))
        func `a press, three drags and a release give five samples in order, in view points`() async throws {
            let rig = Rig()
            let points = [CGPoint(x: 50, y: 40), CGPoint(x: 60, y: 45), CGPoint(x: 70, y: 50), CGPoint(x: 80, y: 55), CGPoint(x: 80, y: 55)]
            let types: [NSEvent.EventType] = [.leftMouseDown, .leftMouseDragged, .leftMouseDragged, .leftMouseDragged, .leftMouseUp]
            for (index, type) in types.enumerated() {
                let flags: NSEvent.ModifierFlags = index == 0 ? [.shift] : [.option, .command]
                try rig.window.sendEvent(rig.event(type, at: points[index], time: 100 + Double(index), flags: flags))
            }
            let samples = await AppUICanvasFixtures.take(5, from: rig.canvas.samples)
            #expect(samples.map(\.phase) == [.began, .moved, .moved, .moved, .ended])
            #expect(samples.map(\.location) == points)
            #expect(samples.map(\.timestamp) == [100, 101, 102, 103, 104])
            #expect(samples.map(\.modifiers) == [[.shift], [.option, .command], [.option, .command], [.option, .command], [.option, .command]])
            #expect(samples.allSatisfy { $0.device == .mouse && $0.force == nil && !$0.isCoalesced && !$0.isPredicted })
        }

        @Test(.timeLimit(.minutes(1)))
        func `a pointer moving with no button down is a hover sample`() async throws {
            let rig = Rig()
            try rig.canvas.mouseMoved(with: rig.event(.mouseMoved, at: CGPoint(x: 10, y: 20), time: 5, flags: [.control]))
            let samples = await AppUICanvasFixtures.take(1, from: rig.canvas.samples)
            #expect(samples == [AppUICanvas.Sample(phase: .hovered, location: CGPoint(x: 10, y: 20), timestamp: 5, device: .mouse, modifiers: [.control])])
        }

        @Test
        func `every modifier key is read`() throws {
            let rig = Rig()
            let pairs: [(NSEvent.ModifierFlags, AppUICanvas.Modifiers)] = [
                (.capsLock, .capsLock), (.shift, .shift), (.control, .control), (.option, .option), (.command, .command),
                (.numericPad, .numericPad), (.function, .function),
            ]
            for (flag, expected) in pairs {
                #expect(try AppUICanvas.modifiers(of: rig.event(.leftMouseDown, at: .zero, time: 0, flags: [flag])) == expected)
            }
            #expect(try AppUICanvas.modifiers(of: rig.event(.leftMouseDown, at: .zero, time: 0)) == [])
        }

        @Test
        func `the canvas takes the first click and the focus`() throws {
            let rig = Rig()
            #expect(rig.canvas.acceptsFirstResponder)
            #expect(try rig.canvas.acceptsFirstMouse(for: rig.event(.leftMouseDown, at: .zero, time: 0)))
        }

        @Test(.timeLimit(.minutes(1)))
        func `a tablet point is a pen with its pressure`() async throws {
            let source = try #require(CGEventSource(stateID: .privateState))
            let down = try #require(CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: .zero, mouseButton: .left))
            down.setIntegerValueField(.mouseEventSubtype, value: Int64(NSEvent.EventSubtype.tabletPoint.rawValue))
            down.setDoubleValueField(.mouseEventPressure, value: 0.2)
            down.setDoubleValueField(.tabletEventPointPressure, value: 0.2)
            let rig = Rig()
            try rig.canvas.mouseDown(with: #require(NSEvent(cgEvent: down)))
            // The event holds a screen position, not a window's; the place is not asserted here, the device and the pressure are.
            let sample = try #require(await AppUICanvasFixtures.take(1, from: rig.canvas.samples).first)
            #expect(sample.device == .pencil)
            // The event stores the pressure in 8 bits (0.2 is 51 of 255, exact) and AppKit reads it as a Float, so the error is Float's, below 1e-6.
            let force = try #require(sample.force)
            #expect(abs(force - 0.2) < 1e-6)
        }

        @Test(.timeLimit(.minutes(1)))
        func `a canvas that leaves its window in the middle of a drag cancels the contact where it was`() async throws {
            let rig = Rig()
            try rig.window.sendEvent(rig.event(.leftMouseDown, at: CGPoint(x: 30, y: 30), time: 1))
            try rig.window.sendEvent(rig.event(.leftMouseDragged, at: CGPoint(x: 40, y: 35), time: 2))
            rig.canvas.removeFromSuperview()
            let samples = await AppUICanvasFixtures.take(3, from: rig.canvas.samples)
            #expect(samples.map(\.phase) == [.began, .moved, .cancelled])
            #expect(samples.last?.location == CGPoint(x: 40, y: 35))
        }

        @Test(.timeLimit(.minutes(1)))
        func `a precise scroll with Command held is a scroll that zooms, at the pointer in view points`() async throws {
            let rig = Rig()
            let cg = try #require(CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: -12, wheel2: 5, wheel3: 0))
            cg.flags = .maskCommand
            let event = try #require(NSEvent(cgEvent: cg))
            rig.canvas.scrollWheel(with: event)
            let step = try #require(await AppUICanvasNavigationFixtures.take(1, from: rig.canvas.navigation).first)
            guard case let .scroll(dx, dy, precise, zooms, _) = step else {
                Issue.record("not a scroll: \(step)")
                return
            }
            #expect(zooms)
            #expect(precise)
            #expect(dy == event.scrollingDeltaY && dx == event.scrollingDeltaX)
        }

        @Test(.timeLimit(.minutes(1)))
        func `a scroll with no modifier does not zoom`() async throws {
            let rig = Rig()
            let cg = try #require(CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: 3, wheel2: 0, wheel3: 0))
            try rig.canvas.scrollWheel(with: #require(NSEvent(cgEvent: cg)))
            let step = try #require(await AppUICanvasNavigationFixtures.take(1, from: rig.canvas.navigation).first)
            guard case let .scroll(_, _, _, zooms, _) = step else {
                Issue.record("not a scroll: \(step)")
                return
            }
            #expect(!zooms)
        }

        @Test(.timeLimit(.minutes(1)))
        func `a modifier key pressed in the middle of a drag is a sample between the drag's samples`() async throws {
            let rig = Rig()
            try rig.window.sendEvent(rig.event(.leftMouseDown, at: CGPoint(x: 30, y: 30), time: 1))
            let flags = try #require(NSEvent.keyEvent(
                with: .flagsChanged, location: .zero, modifierFlags: [.shift], timestamp: 2, windowNumber: rig.window.windowNumber,
                context: nil, characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: 56
            ))
            rig.canvas.flagsChanged(with: flags)
            try rig.window.sendEvent(rig.event(.leftMouseDragged, at: CGPoint(x: 40, y: 35), time: 3, flags: [.shift]))
            let samples = await AppUICanvasFixtures.take(3, from: rig.canvas.samples)
            #expect(samples.map(\.phase) == [.began, .modifiersChanged, .moved])
            #expect(samples[1].modifiers == [.shift])
            #expect(samples[1].location == CGPoint(x: 30, y: 30))
        }

        @Test(.timeLimit(.minutes(1)))
        func `a tablet point carries its tilt`() async throws {
            let source = try #require(CGEventSource(stateID: .privateState))
            let down = try #require(CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: .zero, mouseButton: .left))
            down.setIntegerValueField(.mouseEventSubtype, value: Int64(NSEvent.EventSubtype.tabletPoint.rawValue))
            down.setDoubleValueField(.tabletEventTiltX, value: 0.5)
            down.setDoubleValueField(.tabletEventTiltY, value: -0.25)
            let rig = Rig()
            try rig.canvas.mouseDown(with: #require(NSEvent(cgEvent: down)))
            let sample = try #require(await AppUICanvasFixtures.take(1, from: rig.canvas.samples).first)
            #expect(sample.device == .pencil)
            // The event stores a tilt in 16 bits (measured: 0.5 reads back 0.49998474), so the error is below one step of 2/65535, 3.1e-5.
            let tilt = try #require(sample.tilt)
            #expect(abs(tilt.x - 0.5) < 3.1e-5 && abs(tilt.y + 0.25) < 3.1e-5)
        }

        @Test
        func `a mouse has no tilt`() async throws {
            let rig = Rig()
            try rig.canvas.mouseDown(with: rig.event(.leftMouseDown, at: .zero, time: 1))
            let sample = try #require(await AppUICanvasFixtures.take(1, from: rig.canvas.samples).first)
            #expect(sample.tilt == nil)
        }

        @Test
        func `the Surface takes the scale of the window the canvas is in`() {
            let rig = Rig()
            #expect(rig.canvas.surface.displayScale == rig.window.backingScaleFactor)
        }

        @Test
        func `the view is flipped, so its top left is the Surface's top left`() {
            let rig = Rig()
            #expect(rig.canvas.isFlipped)
            #expect(rig.canvas.backingLayer.isGeometryFlipped)
        }
    }
#endif
