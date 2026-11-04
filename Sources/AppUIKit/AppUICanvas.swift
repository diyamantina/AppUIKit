//
//  AppUICanvas.swift
//  AppUIKit
//
//  The interactive side of the canvas: one layer-backed view that hosts one CACanvas.Surface and turns what a person does to it, with a mouse,
//  a trackpad, a finger or a pen, into one ordered stream of samples. The Surface only displays; this view is the only canvas file that touches
//  events. The platform fork is in AppUICanvas+AppKit.swift and AppUICanvas+UIKit.swift, one file each; nothing else here names a platform.
//

import CACanvas
import CoreGraphics
import Foundation
import QuartzCore

/// A view that shows a `CACanvas.Surface` and reports the pointer.
///
/// The view owns the Surface and fills its bounds with it. The host shows items through ``surface`` (`apply(items:overlay:viewport:)`);
/// this type does not wrap the display. It reads the pointer and answers where things are: ``samples`` is the pointer, ``hit(at:)`` is the
/// question. It knows nothing of any application.
///
/// ## Threads
///
/// Everything runs on the main actor. The event handlers yield into ``samples`` synchronously, in the order the system delivers events, and
/// create no task, so the order the platform gave is the order the consumer sees.
public final class AppUICanvas: AppUITopLeftView {
    /// The display. The host calls `apply(items:overlay:viewport:)` on it; the view sizes it, sets its display scale and hit-tests it.
    public let surface = CACanvas.Surface()

    /// The pointer shape over the canvas. The host sets it from what is under the pointer; setting the shape it already has does nothing.
    public var cursor: Cursor = .arrow {
        didSet {
            if cursor != oldValue {
                platformCursorChanged()
            }
        }
    }

    /// The pointer, as one ordered stream with one consumer.
    ///
    /// Samples are yielded at the moment the platform delivers them, in that order, and none is dropped (the buffer is unbounded). Iterate it
    /// from one task. It has no second consumer: two tasks iterating the same stream split its samples between them. A canvas nobody iterates
    /// keeps every sample until it is released, so the host starts its loop when it creates the canvas. The stream ends when the canvas is
    /// released.
    public let samples: AsyncStream<Sample>

    private let continuation: AsyncStream<Sample>.Continuation

    /// Which contact draws (a `UITouch` on UIKit), so the other contacts of a multi-finger event are not mixed into the stream, and a second
    /// one turns the gesture into a navigation.
    var tracker = ContactTracker<ObjectIdentifier>()
    /// The steps of a change of view (scroll, pinch, smart zoom), in the order the platform delivered them, with one consumer like ``samples``.
    public let navigation: AsyncStream<Navigation>
    private let navigationContinuation: AsyncStream<Navigation>.Continuation
    /// The keys that mean an edit or a change of view (``Key``), in the order they were pressed, with one consumer like ``samples``.
    public let keys: AsyncStream<Key>
    let keyContinuation: AsyncStream<Key>.Continuation
    /// The commands a touch screen's multi-finger taps make (``Command``), in order, with one consumer like ``samples``. A Mac reports none.
    public let commands: AsyncStream<Command>
    let commandContinuation: AsyncStream<Command>.Continuation
    /// Whether the space bar is held: a drag then pans the view and reports no sample, as in every drawing app.
    public internal(set) var isSpaceHeld = false
    /// Whether the tilde key is held (a release is reported when the canvas stops being the key view).
    public internal(set) var isTildeHeld = false
    /// Whether the X key is held: every report then carries ``Modifiers/marquee`` (a release is reported when the canvas stops being the key view).
    public internal(set) var isMarqueeHeld = false
    /// Modifier keys a host holds down for the person where there is no keyboard (a touch screen's Uniform and From centre switches): every report then carries them, beside the
    /// keys of the event, and a change is reported at the
    /// pointer's last place in the stream's order, like a key.
    public var heldModifiers: Modifiers = [] {
        didSet {
            guard heldModifiers != oldValue else { return }
            emit(modifiers: lastPlatformModifiers, timestamp: ProcessInfo.processInfo.systemUptime)
        }
    }

    /// The keys a report carries on top of the event's own: those the host holds, and X while it is held.
    var foldedModifiers: Modifiers {
        isMarqueeHeld ? heldModifiers.union(.marquee) : heldModifiers
    }

    /// Where a pan by Space and drag was last, in the view's points; `nil` when none is going.
    var panAnchor: CGPoint?
    /// Where the pointer was last, so a change of modifier keys has a place.
    var lastLocation = CGPoint.zero
    /// The modifier keys of the last report, so only a change is reported, and the keys of the last event before the held ones were added to it.
    var lastModifiers: Modifiers = []
    var lastPlatformModifiers: Modifiers = []

    /// The last sample made, kept so a cancel can say where the contact was.
    private var lastDown: (contact: Contact, modifiers: Modifiers)?

    /// Creates a canvas with an empty Surface.
    public init() {
        let pair = AsyncStream.makeStream(of: Sample.self, bufferingPolicy: .unbounded)
        samples = pair.stream
        continuation = pair.continuation
        let steps = AsyncStream.makeStream(of: Navigation.self, bufferingPolicy: .unbounded)
        navigation = steps.stream
        navigationContinuation = steps.continuation
        let pressed = AsyncStream.makeStream(of: Key.self, bufferingPolicy: .unbounded)
        keys = pressed.stream
        keyContinuation = pressed.continuation
        let made = AsyncStream.makeStream(of: Command.self, bufferingPolicy: .unbounded)
        commands = made.stream
        commandContinuation = made.continuation
        super.init(frame: .zero)
        backingLayer.addSublayer(surface)
        installPlatformInput()
        refreshDisplayScale()
    }

    @available(*, unavailable)
    public required init?(coder _: AppUICoder) {
        nil
    }

    deinit {
        continuation.finish()
        navigationContinuation.finish()
        keyContinuation.finish()
        commandContinuation.finish()
    }

    // MARK: Where things are

    /// What lies under a point of the view (in the view's own points, origin at the top left).
    ///
    /// The Surface's marks are asked first, because a handle beats the object under it; then its items, topmost first.
    public func hit(at point: CGPoint) -> Hit {
        if let mark = surface.marks(at: point).first {
            return .mark(mark)
        }
        let items = surface.ids(at: point)
        return items.isEmpty ? .none : .items(items)
    }

    // MARK: Layout and scale

    /// Fits the Surface to the view with actions off, so a resize moves nothing through an animation.
    override public func didLayout() {
        super.didLayout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        surface.bounds = CGRect(origin: .zero, size: bounds.size)
        surface.position = CGPoint(x: bounds.midX, y: bounds.midY)
        CATransaction.commit()
    }

    override public func didChangeAppearance() {
        super.didChangeAppearance()
        refreshDisplayScale()
    }

    /// Reads the scale of the window the view is in and gives it to the Surface.
    func refreshDisplayScale() {
        apply(displayScale: platformDisplayScale())
    }

    /// Sets the Surface's display scale; when it changed, bitmaps are asked for again at the new scale and shapes take it.
    func apply(displayScale scale: CGFloat) {
        guard scale > 0, scale != surface.displayScale else { return }
        surface.displayScale = scale
        surface.settleScale()
    }

    // MARK: Samples

    /// Yields one sample. A contact that ends or is cancelled is forgotten; one that began or moved is remembered for a cancel.
    func emit(_ sample: Sample, contact: Contact) {
        var sample = sample
        lastPlatformModifiers = sample.modifiers
        sample.modifiers.formUnion(foldedModifiers)
        switch sample.phase {
        case .began, .moved:
            if !sample.isPredicted {
                lastDown = (contact, sample.modifiers)
            }
        case .ended, .cancelled:
            lastDown = nil
        case .hovered, .modifiersChanged:
            break
        }
        if !sample.isPredicted {
            lastLocation = sample.location
        }
        lastModifiers = sample.modifiers
        continuation.yield(sample)
    }

    /// Yields one sample of a contact that is not part of a UIKit event's folded or predicted batch.
    func emit(_ phase: Phase, _ contact: Contact, modifiers: Modifiers) {
        emit(contact.sample(phase, modifiers: modifiers), contact: contact)
    }

    /// Reports a step of a change of view.
    func emit(navigation step: Navigation) {
        navigationContinuation.yield(step)
    }

    /// Reports the modifier keys when they differ from the last report, as a sample at the pointer's last place, in the same stream as the
    /// pointer so that a key pressed in the middle of a drag arrives in its order.
    func emit(modifiers: Modifiers, timestamp: TimeInterval) {
        lastPlatformModifiers = modifiers // the keyboard's own keys, even when nothing changes in what is carried: a switch let go later must not take them away
        guard modifiers.union(foldedModifiers) != lastModifiers else { return }
        let contact = Contact(location: lastLocation, timestamp: timestamp, device: .mouse)
        emit(contact.sample(.modifiersChanged, modifiers: modifiers), contact: contact)
    }

    /// The X key goes down or up: the state changes and the modifiers are reported at the pointer's last place, in the stream's order, so a drag already begun sees it. The same
    /// state again changes nothing.
    func holdMarquee(_ held: Bool, timestamp: TimeInterval) {
        guard held != isMarqueeHeld else { return }
        isMarqueeHeld = held
        emit(modifiers: lastPlatformModifiers, timestamp: timestamp)
    }

    /// Ends a contact the system took away without saying so (the window closed under a drag): a cancel at the last place it was.
    func cancelContactIfDown() {
        guard let down = lastDown else { return }
        emit(.cancelled, down.contact, modifiers: down.modifiers)
    }

    /// The samples of one event, in the order the stream must carry them: the touches UIKit folded into the event (oldest first), then the
    /// event's own touch, then the touches UIKit predicted.
    ///
    /// UIKit's folded list ends with the event's own touch, so the entries that are the own touch (same time, same place) are not repeated.
    /// Folded and predicted touches are movement: they are given only to an event that moves or lifts (folded) or moves (predicted); a touch
    /// that begins is alone, because a movement before the beginning would break the order of phases.
    static func samples(
        phase: Phase,
        folded: [Contact],
        own: Contact,
        predicted: [Contact],
        modifiers: Modifiers
    ) -> [Sample] {
        var result: [Sample] = []
        if phase != .began {
            for earlier in folded where !(earlier.timestamp == own.timestamp && earlier.location == own.location) {
                result.append(earlier.sample(.moved, modifiers: modifiers, isCoalesced: true))
            }
        }
        result.append(own.sample(phase, modifiers: modifiers))
        if phase == .moved {
            for guess in predicted {
                result.append(guess.sample(.moved, modifiers: modifiers, isPredicted: true))
            }
        }
        return result
    }

    /// Yields the samples of ``samples(phase:folded:own:predicted:modifiers:)`` in order.
    func emit(phase: Phase, folded: [Contact], own: Contact, predicted: [Contact], modifiers: Modifiers) {
        for sample in Self.samples(phase: phase, folded: folded, own: own, predicted: predicted, modifiers: modifiers) {
            emit(sample, contact: own)
        }
    }
}
