# The canvas view

One view that shows a canvas surface and reports the pointer, the same on AppKit and UIKit.

## Overview

``AppUICanvas`` is a layer-backed ``AppUIView`` that hosts one `CACanvas.Surface` from the CAControls package. The surface only
displays: one host layer for each object, keyed by a stable id, with an overlay of marks and bands and a viewport over all. This
view is the part that takes input. The dependency points one way: Core Animation, then CAControls, then AppUIKit, then the
application. The view knows nothing of any application, and the surface knows nothing of events.

The host shows its document through ``AppUICanvas/surface`` with `apply(items:overlay:viewport:)`. The view does not wrap that call.

```swift
let canvas = AppUICanvas()
canvas.surface.apply(items: items, overlay: .init(), viewport: .init())

Task { @MainActor in
    for await sample in canvas.samples {
        // began, moved, ended, cancelled, hovered
    }
}

switch canvas.hit(at: point) {
case .mark(let id): break      // a handle
case .items(let ids): break    // topmost first
case .none: break              // the backdrop
}
```

## The samples

``AppUICanvas/samples`` is one ordered stream with one consumer. The view yields into it from the event handlers, synchronously, in the
order the system delivers events, and creates no task for an event: a task for each event gives up the order, and the tests hold a
control that shows it doing so. The buffer is unbounded, so nothing is dropped when the consumer is slower than the pointer; the cost is
that a canvas nobody iterates keeps what it has seen until it is released, so the host starts its loop when it creates the canvas.

A ``AppUICanvas/Sample`` has a phase, a location, a timestamp, a device, an optional force, altitude and azimuth, the modifier keys, and
whether it is coalesced or predicted. The location is in the view's own points with the origin at the top left on both platforms
(the view is flipped on AppKit), so a point of the stream can be given straight to ``AppUICanvas/hit(at:)`` and to the viewport.

On UIKit one event carries more than one touch. The samples of an event come in this order: the coalesced touches, which are the
movements UIKit folded into the event; the event's own touch; then the predicted touches. UIKit's folded list ends with the event's own
touch, so that one is not given twice. A touch that begins is alone, and only a moving event carries predicted touches. A predicted
sample is a guess for the next frame: draw it, never commit it. The rule lives once, in a function both platforms call, and is held by
tests that write the touches as plain values, because a `UITouch` cannot be made in a test.

## Navigation and modifier keys

``AppUICanvas/navigation`` is a second ordered stream with one consumer, of ``AppUICanvas/Navigation`` steps in view points: a scroll (a
trackpad in points or a wheel in lines, with `zooms` true while Command or Option is held), a pinch step with its factor, and a smart zoom.
The view does no arithmetic with them; the host decides what a pan or a zoom is. On UIKit the first contact draws, and a second one cancels
it and the gesture becomes a pinch or a two-finger pan (``AppUICanvas/ContactTracker`` holds the rule on plain values).

A change of the modifier keys is a sample with the ``AppUICanvas/Phase/modifiersChanged`` phase, at the pointer's last place, in the same
stream as the pointer, so Shift pressed in the middle of a drag arrives in its order. It needs the canvas to be the first responder.

## Where things are

``AppUICanvas/hit(at:)`` asks the surface's marks first, because a handle beats the object under it, then its items, topmost first. The
surface tests against what is on screen (the presentation layers), through the viewport, with the 28 point target of a mark and the 4
point slop of a stroke measured in view points at any zoom.

## The display scale

The surface's display scale follows the window: `viewDidChangeBackingProperties` and the window change on AppKit, the trait collection
and the window change on UIKit. When it changes, the view sets it on the surface and calls `settleScale()`, so shapes take the new contents
scale and bitmaps are asked for again at the new scale. A scale that has not changed asks for nothing.

## Layout

Layout fits the surface to the view's bounds with actions off, so a resize moves nothing through an animation. A test puts the surface on a
headless render stage, resizes the view and compares the presentation layer with the model; a plain layer put through the same change is the
control that shows the test can fail.

## One file for each platform

The AppKit fork is `AppUICanvas+AppKit.swift` and the UIKit fork is `AppUICanvas+UIKit.swift`; each is guarded whole, and no other file
of the canvas names an event, a gesture or a platform conditional. A test reads the sources and holds this. Events never go into
CAControls, which has a gate of its own for the same rule.

## What is not here

- Zoom and pan arithmetic: the viewport is the host's to set. The view only reports the steps (see below).
- Accessibility elements for the items.
- A text field for editing text on the canvas.
- A right-button event. A secondary button goes to the next responder.

## Limits of what the platforms say

- **AppKit and UIKit do not tell a mouse from a trackpad.** A pointer is ``AppUICanvas/Device/mouse``. ``AppUICanvas/Device/trackpad`` is
  what UIKit reports for an indirect touch that is not a pointer.
- **Pen force and tilt.** The force is a fraction from 0 to 1 on both platforms (on UIKit the touch's force over its maximum possible
  force). On AppKit the tablet's tilt components are given as they come (`Sample/tilt`), because no tablet was at hand to check the
  direction convention against. On UIKit the force, altitude and azimuth of the Pencil are read. A finger and a mouse have no force here.
- **Hover on UIKit** is the pointer's, as a mouse; Pencil hover is not told apart from it.
- **Not run on a device.** The UIKit path is compiled and its tests run on the simulator; no real finger, Pencil or pointer has driven it.
