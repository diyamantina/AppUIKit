# Native Per Platform (optimize for the user, not the developer)

**Status: MANDATORY for any code that has UI.** The UI is optimized for the *user*, through genuinely
native presentation on each platform, never for the developer's convenience of a single shared
layout, easy testing, or a write-once cross-platform lowest-common-denominator. Each platform's UI
may be drastically different, and that is correct. Sameness across platforms is never a goal in
itself; the best native experience on the device in the user's hands is.

## The premise

There are two distinct optimization targets, and they are often in tension:

- **Optimizing for the developer**: one layout that runs everywhere, identical across devices, cheap
  to build, easy to test, easy to keep "in sync". A write-once cross-platform stack is the extreme
  of this: the user gets the intersection of what every platform can do, rendered by a foreign
  toolkit that is no platform's native idiom.
- **Optimizing for the user**: the interface that fits *this* device, its input model, its
  conventions, its ergonomics. A Mac with a menu bar, resizable split columns, multiple windows, a
  pointer and a full keyboard is a different machine from an iPhone held in one hand at arm's reach,
  and its best UI looks and behaves nothing alike.

We choose the user. When the two conflict, the native user experience wins, every time.

## The rule

1. **Build native, per platform.** Use each platform's own SDK and idioms (SwiftUI, UIKit, AppKit on
   Apple platforms) to their fullest. Do not flatten an iPhone, an iPad, and a Mac into one layout
   because it is less code. The Mac build is a Mac app; the iPhone build is an iPhone app.

2. **Divergence is welcome, not a smell.** If the iPhone and the Mac UIs end up drastically
   different, that is success, not drift. Different navigation, different chrome, different
   affordances, different information density per the device is the point.

3. **Never justify a UI choice with developer or test convenience.** "Easier to build", "keeps the
   renderers identical", "simpler to test", or "matches the other platform" is not a reason to give
   the user a worse native experience. Justify UI decisions with what is best for the user on that
   device.

4. **A shared layout policy is advisory, not a constraint.** A framework-free decision aid (a
   resolved layout plan, a size-class mapping, a common vocabulary) is useful so a renderer starts
   from a tested answer instead of guessing. But each platform may follow it, refine it, or replace
   it entirely when its own idioms serve the user better. The plan informs; it does not bind.

## What still stays shared (because it is correctness, not look and feel)

This rule frees the *presentation*. It does not loosen the architecture. Two things remain uniform:

- **The pre-UI layer** (`pre-ui-layer.md`): every renderer drives change through the one
  `perform(Intent)` channel and reflects read-only surface state; the engine is the single source of
  truth. A drastically different Mac UI still goes through the same intents and surfaces. The model
  is shared *precisely so* the presentation can diverge freely without duplicating behavior.
- **Output correctness**: where multiple backends produce the same artifact (for example a GPU and a
  CPU renderer producing pixels), they must agree. That is backend correctness, unrelated to
  per-platform UI structure.

## Reconciliation with `three-renderers.md`

`three-renderers.md` calls for building the same UI in all three Apple SDKs over one model, as the
architecture's payoff and a comparison instrument for which framework behaves best. That holds *for
a given device class*, and it is genuinely valuable. But it is a developer and architecture goal,
and it is **subordinate to this rule**: the "same UI across renderers" aspiration applies only where
the same UI is also the best native UI for the device. Where a platform's best native experience
calls for a drastically different shape, the user wins and the renderers diverge. The shared model
makes that cheap; it never makes it mandatory to look identical.

## Acceptance check

This rule is judgment-based; conformance is an observable checklist, each item phrased so two
reviewers reach the same verdict on a given change:

- **Native SDK per platform.** Each platform's UI is built with that platform's own SDK and idioms
  (SwiftUI / UIKit / AppKit), not a single foreign cross-platform layout rendered everywhere. PASS:
  the Mac target uses a menu bar, resizable split columns, multiple windows where they serve the user;
  the iPhone target uses one-handed navigation. FAIL: one layout is forced identical across devices
  because it is less code.
- **No developer-convenience justification.** No UI decision in the change is defended with "easier to
  build", "keeps the renderers identical", "simpler to test", or "matches the other platform". FAIL if
  any commit message, comment, or PR note carries such a reason for a user-facing layout choice; PASS
  if every UI choice is justified by what is best for the user on that device.
- **Divergence is not treated as drift.** Where the iPhone and Mac UIs differ in navigation, chrome,
  density, or affordances, that difference is left in place, not "fixed" toward sameness. FAIL if a
  change collapses a justified per-platform divergence purely to make the platforms look alike.
- **The shared layer is untouched by the divergence.** Every renderer still drives change through the
  one `perform(Intent)` channel and reads read-only surface state (`pre-ui-layer.md`); the divergence
  lives only in presentation. FAIL if a platform duplicates behavior into its renderer instead of
  routing through the shared model.
- **Backend output still agrees.** Where two backends produce the same artifact (a GPU and a CPU
  renderer producing pixels, say), they still match; this rule frees presentation, not output
  correctness.

A change passes only when every item passes; a UI made uniform across platforms for build or test
convenience fails this rule even if it ships and looks tidy.

## Why

Users do not run architectures; they run the app in front of them, on one device, judged against the
native apps beside it. A write-once, lowest-common-denominator UI reads as foreign on every platform
and best on none. The pre-UI layer exists to make native-per-platform *affordable* (one model, many
thin renderers), not to make every platform look the same. Build the model once; build the
experience natively, for the user, on each device.
