# Pane layout and adaptive columns

**Status: MANDATORY for every app that lays a document out in panes, columns or pages.** Learned on an iPad and an iPhone Duo with a real editor, and each rule below is a defect that was shipped and found by looking at the screen.

## Why

A split gives each pane a size; the content of a pane then asks for one too. When the two disagree the content wins, silently: the pane's content is wider than its pane, a divider is drawn over a search field, rows are cut. A window that counts as wide by a fixed number lays three columns out in a portrait iPad and leaves the document a hundred points. A model that changes under a view is not always seen by the view. None of this shows in a unit test of the model; it shows in a picture of the real window.

## Rules

1. **The split sizes a pane; the content does not.** Lay the content of a pane over a view that takes whatever room it is offered (`Color.clear.overlay(alignment: .topLeading) { content }` then `.clipped()`), so that a part that needs more than the pane has is cut at the edge and cannot widen the pane. Do not rely on the content to be small.
2. **Optional parts are decided by a measurement, not by a container that is meant to drop them.** A tip put in `ViewThatFits` with a `minWidth` was found to make a 240 point pane's content 296 points wide even when it showed nothing. Measure the pane (`onGeometryChange`) and put the optional part in only when the pane is wide enough for it.
3. **A header fits the narrowest pane it will have.** Put the controls that are always there in one row and the ones that come and go in a second row that exists only when needed; give a field a short prompt. A UI test fails when any control is past the pane's edge (the divider beside the pane is the edge).
4. **Columns are decided by the room the parts need, not by a fixed width.** The window is wide enough for the sidebar, the document and the inspector beside it when its width exceeds the sum of their widths and the document's least width. Put the sum in one pure function and test it with the real window widths of Apple's devices (a 13 inch iPad upright is 1032 points: a flat 1000 counted it as wide). Anything narrower gives the window to the document and puts the inspector in a popover.
5. **A layout is saved for the way the device is held.** Key the saved layout by the arrangement and make the arrangement include the orientation; a comment that says two keys are separate is not a test, so test it.
6. **A way to give the document the whole area.** A control in the toolbar that hides the outline and the panes beside it, and shows them again, is a toggle that looks pressed while they are shown; the pane's own maximize control and the toolbar control stay in step.
7. **A view of a platform view is brought up to date by a change of its inputs, and keeps its controller.** SwiftUI's update of a representable was not called when a document was opened on an iPad, and a coordinator was made more than once for one view, so the update went to a controller whose view was not the one on screen. Read what the view shows where the parent makes it (so the parent's change makes a new value), and keep the controller in an object the view owns, so the view that is shown and the controller that is updated are the same.
8. **Look at the screen, in both orientations and at the narrowest size, before saying it is done.** A picture of each arrangement is a deliverable of the change (`accessibility.md`, `iphone-duo.md`).

## One set of panes on a Mac, an iPad and an iPhone (SuperSplit)

Learned by running the same editor on all three with SuperSplit for the split. The panes are one set of views; what differs is the container, and the container is chosen by the room, not by the device.

1. **One view per pane role, many containers.** Write each pane once, by role (`EditorPane(role: .outline)`), and let the container decide how roles are shown: all six side by side in a Mac window; the outline, the source and the diagnostics in a split on an iPad, with the inspector beside it or in a popover; a page of a `TabView` each on a phone, where SuperSplit is not used at all. A phone does not get a split of tiny panes: pages are the same views without the split. Never fork a pane per device.
2. **The arrangement is a value, and it names the saved layout.** `desktop`, `tablet`, `upright` and `short` (little height) are cases of one enum; the container is made again (`.id(arrangement)`) when the arrangement changes, and each arrangement keeps its own saved layout, per device, per kind of document. A layout laid out for a wide window is not what suits a tall one, and a fold or a rotation must not apply one to the other. Test that the keys differ.
3. **A pane's share and its least size are two different limits, and the least must win.** The outline is a share of the width (30 per cent on a tablet); on an iPad with a sidebar and an inspector that share came out below what the outline needs. Give the pane a least size, and have the layout clamp the share to it when the container shrinks (`setMinimumSize` and a ratio clamped at layout time), with an exhaustive test over container widths that the least holds. Whatever the share, the content must fit the least (rule 3 above).
4. **The Mac hides the problem by being wide.** A pane that fits in a wide Mac window is squeezed on an iPad that shares its width with a sidebar and an inspector. Test every pane at its least width, on every platform, not at the size the app first opens at.
5. **The divider is the edge of a pane, and the accessibility tree tells where it is.** A divider is a bar about 28 points wide centered on the boundary between two panes, drawn over both. Its frame in the accessibility tree is the line a UI test uses to assert that no control of a pane is past its edge (`Divider between Outline and 2 panes`); on the Mac it is a slider, on iOS adjustable. Read frames from the tree; a picture shows that something is wrong, the frames say what.
6. **A pane's content is cut at the card, so what is cut is not seen.** The pane card clips its body: a control that does not fit is silently lost, which is the worst failure. Pair the clip with a test that fails on any control past the edge, and with a picture of each arrangement.
7. **Maximize is the way to give one pane the whole area.** SuperSplit maximizes a pane over the layout; a toolbar toggle for "hide the outline" is maximize of the source, kept in step with the pane's own control, saved with the arrangement, and applied when the arrangement is made.
8. **Platform views inside a pane need an owner that lives as long as the pane.** A pane's content is made by a closure inside the split, and SwiftUI made the coordinator of a text view more than once for one pane, so a change of the model went to a controller whose view was not on the screen. Keep the controller in an object the pane's view owns, and read the model where the pane builds the view.
9. **Chrome as glass is a background.** The header strip and the round controls take the glass look as a background behind the title and the glyphs (through a layer that falls back, such as Forwards), so that what is drawn on them is drawn the same where a view is rendered off the screen and in pixel tests.
10. **Test it at three levels, and keep them apart.** The pure layout (positions of panes and dividers for a list of container sizes, probed from the model), the real window (frames from the accessibility tree, in each orientation and at the largest text size), and a picture of each arrangement looked at by a person. The first would have found the squeezed outline, the second the header under the divider, and only the third the squeezed source pane.

## How to find what widens a pane

Switch the parts off one at a time at run time (an environment variable passed to the app through the test's launch environment, not the runner's) and measure the frame of the content, the pane and the divider from the accessibility tree: with the header and the list both off the content was still too wide, which named the tip. Never judge by what a view looks like; read the frames.

## Acceptance check

Run from the repository root; `SOURCES` are the Swift sources of the app and its UI packages. Both must print nothing:

```sh
# 1. no window counted as wide by a fixed width
grep -rnE '(windowWidth|size\.width|width) *> *(9|1[0-9])[0-9]{2}\b' "$SOURCES" --include='*.swift'

# 2. no optional part left to ViewThatFits with a least width
grep -rn -A4 'ViewThatFits' "$SOURCES" --include='*.swift' | grep -E 'minWidth'
```

The change passes when those print nothing, the unit tests of the width rule and of the saved layouts for each arrangement pass, and the UI test that no control of a pane is past its edge passes in each orientation.

Cross-references: `iphone-duo.md` (the same size decisions on a foldable), `accessibility.md` (the text size changes the arrangement), `ui/swiftui-views.md` and `ui/uikit-views.md`, `ui/three-renderers.md`, `core/proof-discipline.md` (what was observed and what was assumed), `core/no-shortcuts-first-principles.md` (a clip hides the symptom: the cause is named and tested).
