# Drawing at runtime

Draw custom content live on AppKit and UIKit: what to turn off, what to redraw, what costs a frame, and how to tell.

## Overview

This article is for a developer who uses AppUIKit to draw content that changes while the person works: a stroke
that grows under a finger or a pointer, a shape being dragged, a canvas being scrolled and zoomed. It puts the
knowledge in the order a builder needs it, from the first surprise (a change that fades in when it should simply
appear) to the last (how to know a change made it faster).

Each lesson carries its source and one of two status words:

- term **VERIFIED (macOS)**: shown by a test run on macOS, named in the lesson. The tests of this package's
  own types are in its test target; the tests of implicit actions on layers move to the CAControls package with
  the layer types (see below). Nothing here has been run on UIKit yet; a UIKit half of a lesson stays at the status
  of its source.
- term **STATED BY SOURCE**: an Apple session or Apple's documentation says it; it was read, not yet tested here.

A WWDC session is named by year and number (2012-506 is WWDC 2012 session 506, Optimizing 2D Graphics and
Animation Performance). Line numbers are the lines of that session's transcript in the project's library of WWDC
transcripts. Apple documentation is named by its page on developer.apple.com.

## Two tiers: display layers below, interactive wrappers here

The work is split in two, and the dependency points one way: Core Animation, then the CAControls package, then
AppUIKit.

- **CAControls, the display tier.** Core Animation layer types that only show: a layer base with its implicit
  actions off, a display layer tree, object layers, handle, selection and guide layers, and helpers for
  hit-testing what is on screen. They take no events and know nothing of AppUIKit, of views or of a model.
- **AppUIKit, the interactive tier.** AppUIKit depends on CAControls and wraps its layers in views that take
  events, such as a canvas view. The wrapper owns the view, the events and the mapping from what was hit to what
  it means; the layers stay display only.

The first wrapper is ``AppUICanvas``, over the canvas surface of CAControls; <doc:TheCanvasView> says what it does and where
its limits are. This article explains why the types are built the way they are.

### How a wrapper adds events and hit-testing to a display layer

The display layer does not know it is interactive. The wrapper does four things around it:

1. **It hosts the layer tree.** The wrapper is a view (an ``AppUIInteractiveView``, or a view of its own) that adds
   the display tree as sublayers of its backing layer (``AppUITopLeftView/backingLayer`` on both frameworks). The
   layers it adds are its own, so their implicit actions are off for the keys they change (see the next section).
2. **It takes the events.** Presses, drags and gestures arrive at the view, in the view's coordinates. Nothing is
   drawn there: the handler finds what was hit, updates the state, and marks what changed (see "Never draw from an
   event handler").
3. **It hit-tests what is on screen.** While a layer animates, its model values are where it is going, not where
   it is. Ask the presentation tree: `layer.presentation()` returns the layer as it currently appears, and its
   `hitTest(_:)` searches the presentation tree; `model()` leads back to the layer you own
   ([`CALayer.presentation()`](https://developer.apple.com/documentation/quartzcore/calayer/presentation()); STATED
   BY SOURCE). `hitTest(_:)` takes a point in the coordinate system of the receiver's superlayer and tests bounds
   rectangles
   ([`CALayer.hitTest(_:)`](https://developer.apple.com/documentation/quartzcore/calayer/hittest(_:)); STATED BY
   SOURCE), so a shape that is not its rectangle (a stroke, an ellipse) is tested against its own path after the
   rectangle has matched.
4. **It maps the hit to a meaning.** The wrapper keeps the table from a layer to the identity of what it shows,
   and reports an intent with that identity (select, move, resize). The layer carries no identity a model could
   depend on and no handler.

```swift
// `root` is the display tree; `point` is in the coordinates of root's superlayer, which is what hitTest(_:) expects.
// Before the first commit there is no presentation layer, and the model tree is what is shown.
func hitLayer(at point: CGPoint, in root: CALayer) -> CALayer? {
    (root.presentation() ?? root).hitTest(point)?.model()
}
```

This helper is compiled and run by `AppUIDrawingAtRuntimeExampleTests` on macOS (a point inside a child finds the
child, a point outside the tree finds nothing).

The split is what keeps the display tier testable by pixels and the interactive tier testable by events, each
without the other.

## Turn off the implicit animations you did not ask for

A property change on a Core Animation layer is animated from the old value to the new one unless something says
otherwise. For a drawing surface that is wrong: a redrawn layer fades from its old image to its new one, which
shows as ghosting behind the newest part of a stroke and a fade when the canvas is cleared, and it costs time
(2012-506, lines 353-366). Whether a change animates depends on who made the layer:

| Layer | Animates a property change? | Status |
|---|---|---|
| The layer AppKit makes for a layer-backed `AppUIView` (`wantsLayer = true`) | No | VERIFIED (macOS); STATED BY SOURCE: 2012-217, lines 455-461 |
| A layer you create and add as a sublayer of a layer-backed view | Yes | VERIFIED (macOS) |
| The root layer you give a layer-hosting view (`layer = yours`, then `wantsLayer = true`) | Yes | VERIFIED (macOS); STATED BY SOURCE: 2012-217, lines 656-676, AppKit leaves a hosted layer alone |
| A self-drawing layer redrawn with `setNeedsDisplay()` | Yes, its `contents` | VERIFIED (macOS); STATED BY SOURCE: 2012-506, lines 353-366 |
| The layer behind a UIKit view (`AppUIView.layer` on iOS) | No | STATED BY SOURCE: 2014-221, line 665 |
| A standalone layer on UIKit | Yes | STATED BY SOURCE: 2014-221, line 665 |

The tests (eight, run on macOS on 2026-11-03) move to CAControls with the layer types. AppKit turns implicit animations back on for a
view's layer only when asked, through the animator proxy or `NSAnimationContext.allowsImplicitAnimation`
(2012-217, lines 455-461 and 1025-1048; STATED BY SOURCE).

There are three ways to turn the actions off for a layer you create. All three are VERIFIED (macOS) by the same
tests, and Apple's documentation describes all three: the lookup order in
[`CALayer.action(forKey:)`](https://developer.apple.com/documentation/quartzcore/calayer/action(forkey:)), the
`NSNull` that ends the search, and
[`CATransaction.setDisableActions(_:)`](https://developer.apple.com/documentation/quartzcore/catransaction/setdisableactions(_:)).

**For a layer class you own, return `nil` from `action(forKey:)` for the keys you change live.** This is the fix
in the finger painting demo of 2012-506 (lines 380-408): the session's layer returns `nil` for `contents`, which
means "go directly to the new value", and asks `super` for every other key. After it the strokes are smooth,
there is no ghosting on drawing or on clear, and the app samples input faster (lines 412-420).

```swift
final class LiveLayer: CALayer {
    private static let keysChangedLive: Set<String> = ["contents", "position", "bounds", "opacity", "path"]

    override func action(forKey event: String) -> (any CAAction)? {
        if Self.keysChangedLive.contains(event) {
            return nil
        }
        return super.action(forKey: event)
    }
}
```

**For a layer you do not subclass, put `NSNull` in its `actions` for those keys.**

```swift
let overlay = CAShapeLayer()
overlay.actions = ["path": NSNull(), "position": NSNull(), "bounds": NSNull()]
```

**For one batch of changes, disable actions in an explicit transaction.**

```swift
CATransaction.begin()
CATransaction.setDisableActions(true)
selectionLayer.position = newPosition
selectionLayer.bounds = newBounds
CATransaction.commit()
```

Prefer the first two for a live surface: they belong to the layer, so no call site can forget them. Keep the
transaction for a change made once, such as removing a layer. With UIKit, prefer the implicit transaction to
explicit ones in general, because an explicit transaction changes when the commit happens (2011-121, lines
781-800; STATED BY SOURCE).

> Important: A test of implicit actions must put the layer in a window's layer tree. In this package's tests a
> layer outside a window showed no animation keys after any change, so a test that skipped the window would pass
> without testing anything. VERIFIED (macOS) by the negative control of the same tests.

## Never draw from an event handler

An event handler (a press, a drag, a gesture recognizer's action) has no drawing context. Update the state, mark
the view as needing display, and draw in `draw(_:)` when the system asks (2011-129, lines 370-410 and 1429-1447;
STATED BY SOURCE). Marking costs almost nothing: it "just flips a single bit on the view". The one exception is an
offscreen image context, opened and closed in the same scope (lines 438-470).

With AppUIKit the press handlers of ``AppUIInteractiveView`` are the event handlers and
``AppUIKit/AppUIKit/currentCGContext()`` reaches the context inside `draw(_:)` on both frameworks:

```swift
final class StrokeView: AppUIInteractiveView {
    private var points: [CGPoint] = []
    private let lineWidth: CGFloat = 4
    private let minimumDistanceSquared: CGFloat = 4

    static func dirtyRect(from start: CGPoint, to end: CGPoint, lineWidth: CGFloat) -> CGRect {
        CGRect(x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y))
            .insetBy(dx: -lineWidth / 2, dy: -lineWidth / 2)
    }

    override func pressBegan(at point: CGPoint) {
        points = [point]
        setNeedsDisplay(Self.dirtyRect(from: point, to: point, lineWidth: lineWidth))
    }

    override func pressMoved(at point: CGPoint) {
        guard let last = points.last else { return }
        let dx = point.x - last.x
        let dy = point.y - last.y
        guard dx * dx + dy * dy >= minimumDistanceSquared else { return }
        points.append(point)
        setNeedsDisplay(Self.dirtyRect(from: last, to: point, lineWidth: lineWidth))
    }

    override func draw(_: CGRect) {
        guard let context = AppUIKit.currentCGContext(), let first = points.first, points.count > 1 else { return }
        context.setStrokeColor(CGColor(gray: 0, alpha: 1))
        context.setLineWidth(lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.move(to: first)
        for point in points.dropFirst() {
            context.addLine(to: point)
        }
        context.strokePath()
    }
}
```

This example is compiled and run by `AppUIDrawingAtRuntimeExampleTests` on macOS: the dirty rectangle, the
skipped point, and the pixels of the drawn stroke are checked. Skipping a point too close to the last one is
from 2012-506 (lines 725-730). Set up state that does not change (colors, color spaces, reusable paths) once,
outside `draw(_:)` (2012-506, lines 489-509; STATED BY SOURCE).

## Redraw only what changed

`setNeedsDisplay()` invalidates the whole view. `setNeedsDisplay(_:)` with the rectangle that changed clips the
context to it, so the same drawing code paints only there, with nothing to change in `draw(_:)` (2012-506, lines
466-484; STATED BY SOURCE). The session's dirty rectangle is the bounding box of the previous and current point
grown by half the line width (lines 711-718), and the demo held 60 frames per second with it (line 775). The
spelling `setNeedsDisplay(_:)` is the same on `NSView` and `UIView`, so the call is written once.

With round caps and joins half the line width is enough. A miter join reaches further, up to the miter limit
times half the line width; grow the rectangle by that when joins are mitered (an inference from Core Graphics
geometry, not a statement of the session).

On AppKit, `draw(_:)` can do better than its one rectangle: `getRectsBeingDrawn(_:count:)` returns the separate
rectangles being drawn, and `needsToDraw(_:)` says whether an object's bounds meet any of them, so a canvas of
many objects draws only those that intersect (2013-215, lines 48-109; Apple's
[`NSView.draw(_:)`](https://developer.apple.com/documentation/appkit/nsview/draw(_:)) says the same; STATED BY
SOURCE). Several invalidations in one turn of the run loop are joined into one dirty rectangle (2013-215). With
layer-backed views each view keeps its own dirty region: invalidating a parent does not invalidate its children
(2012-217, lines 320-334).

Two debugging notes from 2012-506: the flash tool for updated regions does not respect the clip, so to see what is
really drawn, outline `context.boundingBoxOfClipPath` in red inside `draw(_:)` (lines 577-591); and a whole-view
`setNeedsDisplay()` redraws the full Retina image on every frame even when the content underneath is cached.

## Flatten what is committed, draw only the new part

A path of a few thousand points becomes slow to stroke again and again. Draw the finished part of the stroke once
into a bitmap, draw that bitmap, and stroke only the newest segment on top; the session flattens after 100 to 200
points and reports a frame rate that no longer depends on how many points the stroke has (2012-506, lines
514-527 and 546-566; STATED BY SOURCE). The same reasoning holds for a canvas of many objects: what is committed
is content, drawn once; what is moving is an overlay, redrawn each frame.

## Performance and implicit animations

Most of a frame's cost is in work nobody asked for. In the order a canvas meets them:

- **Implicit animations.** Every redraw of a layer that still animates `contents` pays for a cross-fade (above).
- **Offscreen passes.** A corner radius with `masksToBounds`, a mask, a shadow without `shadowPath`, and group
  opacity each make the GPU render a subtree offscreen and composite it back, on every frame of a drag (2011-121,
  lines 811-904 and 980-1013; 2014-419, lines 599-683). Give a shadow a `shadowPath` (Apple's
  [Core Animation Programming Guide, Improving Animation Performance](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/ImprovingAnimationPerformance/ImprovingAnimationPerformance.html)
  says the same), set `allowsGroupOpacity` to false when a layer with children does not need it (2014-419, lines
  404-414), and clip an image with a rounded path while drawing it rather than with the layer's corner radius
  (2011-129, line 712). STATED BY SOURCE.
- **Rasterizing what changes.** `shouldRasterize` caches a layer as a bitmap, which pays only when the bitmap is
  reused on the next frame; on a layer whose content changes every frame it adds work. Use it for static content
  that moves, scales or fades, and set `rasterizationScale` to the screen's scale (2012-506, lines 822-868;
  2011-121, lines 937-965; 2014-419, lines 384-402). STATED BY SOURCE.
- **Blending.** An opaque layer composites faster. Say so with `isOpaque` on the view, which AppKit passes to the
  layer, and only when it is true (2013-215, lines 237-248; 2012-506, lines 155-156). Text is font-smoothed only
  when drawn into an opaque area (2012-217, lines 1118-1146). STATED BY SOURCE; Apple's guide above adds that
  `opaque` does not hide the alpha of an image set directly as `contents`.
- **Layer count and depth.** Committing walks the layer tree; keep it flat (2014-419, lines 89-139). On AppKit,
  `wantsLayer` on a view gives every subview a layer; `canDrawSubviewsIntoLayer` draws them into one, and a hidden
  view still costs composition, so remove hundreds of hidden views rather than hide them (2013-215, lines
  511-593). STATED BY SOURCE.
- **The AppKit redraw policy.** For a layer-backed view set `layerContentsRedrawPolicy` to `.onSetNeedsDisplay`
  so a frame change does not redraw and Core Animation can animate it, and call `setNeedsDisplay` yourself when the
  content changes (2013-215, lines 317-344). AppUIKit's own row and tree views do this. STATED BY SOURCE.
- **`drawsAsynchronously`.** Records the drawing and renders it in parallel; it helps with large fills, images
  and shading and is off by default because it is not always a win (2012-506, lines 1010-1102). Measure it.
  STATED BY SOURCE.

## Keep the main run loop free, and let the scroll view scroll

Events are handled on the main run loop; a slow handler makes the next events wait (2012-235, lines 890-911). Core
Animation groups every layer change of one turn of the run loop into one implicit transaction and commits it at
the end of the turn, so a main thread that blocks shows nothing (2011-121, lines 694-777). The live path, from the
event to the model to the layer change, holds no file access, no network and no full render; heavy rendering goes
to a background queue and its result is applied on the main thread, keeping the previous image until the new one is
ready. STATED BY SOURCE.

On AppKit, scrolling and zooming a canvas belong to `NSScrollView` (``AppUIScrollView``), which gives responsive
scrolling: the scroll view tracks the trackpad on a background thread over content drawn ahead of the visible area,
so it stays smooth while `draw(_:)` is slow (2013-215, lines 661-736). STATED BY SOURCE, with one part VERIFIED:

- A scroll view, clip view or document view that overrides `scrollWheel(with:)` is not adopted for responsive
  scrolling unless its class answers true to `isCompatibleWithResponsiveScrolling` (2013-215, lines 1411-1425;
  Apple's
  [`isCompatibleWithResponsiveScrolling`](https://developer.apple.com/documentation/appkit/nsview/iscompatiblewithresponsivescrolling)).
  ``AppUIInteractiveView`` overrides `scrollWheel(with:)` to report ``AppUIInteractiveView/scrolled(by:)``, and
  AppKit reports it as not compatible; ``AppUITopLeftView`` stays compatible. VERIFIED (macOS) by
  `AppUIDrawingAtRuntimeExampleTests`. So an `AppUIInteractiveView` used as a scroll view's document view gives
  up responsive scrolling.
- To follow scrolling, observe the clip view's bounds (`postsBoundsChangedNotifications` and
  `NSView.boundsDidChangeNotification`), which reports the wheel, the scroll bars, the keyboard and programmatic
  moves; `NSScrollView.willStartLiveScrollNotification`, `didLiveScrollNotification` and
  `didEndLiveScrollNotification` bracket a person's scrolling (2013-215, lines 1194-1223). A wheel mouse sends only
  the middle one (lines 1296-1310).
- `allowsMagnification` makes the scroll view handle the pinch itself. During a pinch it scales what is already
  drawn and redraws crisp at the end; invalidating content during the gesture forces a redraw at the current scale,
  so avoid it, and pause other work between `willStartLiveMagnifyNotification` and
  `didEndLiveMagnifyNotification` (2013-215, lines 1577-1678).
- To center content smaller than the clip view, override `constrainBoundsRect(_:)` on the clip view (2013-215,
  lines 1684-1744).

On UIKit, scrolling is not an animation that runs elsewhere: it is driven by events and a timer on the main run
loop, so a slow main thread shows as a stutter (2012-235, lines 1137-1145; STATED BY SOURCE).

## Measure before you change anything

- **Hypothesis, then removal.** Profile, name the suspected work, remove it and measure again; if the time does
  not improve, it is not worth optimizing (2012-235, lines 1038-1083).
- **Several devices, and the device over the simulator.** A fix can help one device and not another (2014-419,
  line 726), and the simulator's coloring of the debug options differs from a device: "trust what you see on
  device" (line 545).
- **The tools.** The Core Animation instrument's debug options color blended layers, offscreen-rendered layers,
  rasterization cache hits and misses, updated regions and misaligned images; Time Profiler finds the cost of
  `draw(_:)`; on the Mac, Quartz Debug flashes updated regions (2012-506, lines 202-298; 2014-419, lines 424-439
  and 1060-1073).
- **The budget.** A frame at 60 Hz is 16.67 ms, and the stages from event to pixel overlap over several frames, so
  the time from touch to pixel is several frames even when every stage fits (2014-419, lines 43-83).

All STATED BY SOURCE.

## What AppUIKit covers and what it does not

Checked against this package's sources:

- **Covered.** ``AppUIView``, ``AppUIScrollView``, `AppUIClipView` (AppKit only), `AppUIEvent`, the gesture
  recognizers (`AppUIPanGestureRecognizer` on both; `AppUIMagnificationGestureRecognizer` on AppKit and
  `AppUIPinchGestureRecognizer` on UIKit, under their own names), `AppUITouch` (UIKit only),
  `AppUIAnimationContext` (AppKit only), ``AppUIBezierPath``, ``AppUIKit/AppUIKit/currentCGContext()``, a display
  link made the same way on both through `AppUIView.makeDisplayLink(target:selector:)`, the top-left coordinate
  space of ``AppUITopLeftView`` with ``AppUITopLeftView/backingLayer`` (a layer on both), and the press, scroll and
  hover callbacks of ``AppUIInteractiveView``.
- **Not covered, by design.** There is no `AppUI` name for Core Animation: `CALayer`, `CAShapeLayer`,
  `CATransaction` and `CAAction` are the same types on both platforms and are used by their own names. Implicit
  actions are not turned off for you by any alias; the layers you create are yours to configure (above), and the
  display layer types with their actions already off belong to CAControls, below AppUIKit.
- **Different on purpose.** The scroll view is a type alias, not a shared behavior: zoom on AppKit is
  `allowsMagnification` and the live notifications, zoom on UIKit is the scroll view's delegate. Code around them is
  platform code.
- **Things to know about ``AppUIInteractiveView``.** On UIKit it reports the first touch of a set only, and it does
  not override `touchesCancelled(_:with:)`, so a press the system cancels never reaches
  ``AppUIInteractiveView/pressEnded(at:)``. It does not deliver coalesced or predicted touches. On AppKit it gives up
  responsive scrolling (above). Read from its source; the UIKit points are not tested here.
