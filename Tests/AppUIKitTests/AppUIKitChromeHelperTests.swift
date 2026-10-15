import Testing
@testable import AppUIKit

/// The small cross-framework helpers a shared chrome is written against: each reads back on the framework it ran on what it was told to set, so a status line, a segmented
/// control, a palette button, a row's icon and a stack's insets can be written once.
@MainActor
@Suite("AppUIKit chrome helpers")
struct AppUIKitChromeHelperTests {
    /// A target that counts the actions it receives.
    @MainActor
    private final class Receiver: NSObject {
        private(set) var count = 0
        @objc func fire(_: Any?) {
            count += 1
        }
    }

    /// Whether the control's primary action reaches `receiver` and nobody else. AppKit is asked by a click, which the control delivers itself. UIKit delivers through the
    /// running application, which a test bundle with no host does not have, so UIKit is asked what it registered for the primary action event: the one selector on `receiver`,
    /// and no other target.
    private func primaryActionReaches(_ receiver: Receiver, from control: AppUIControl) -> Bool {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let before = receiver.count
            control.performClick(nil)
            return receiver.count == before + 1 && control.target === receiver
        #elseif canImport(UIKit)
            let registered = control.actions(forTarget: receiver, forControlEvent: .primaryActionTriggered) ?? []
            return registered == ["fire:"] && control.allTargets == [receiver]
        #endif
    }

    @Test func `a label is read-only, shows the text it is given and keeps its line limit`() {
        let label = AppUILabel()
        label.appuiConfigureAsLabel()
        label.appuiText = "Undo Draw stroke"
        label.appuiMaximumLines = 2
        #expect(label.appuiText == "Undo Draw stroke")
        #expect(label.appuiMaximumLines == 2)
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            #expect(!label.isEditable && !label.isSelectable && !label.isBordered && !label.drawsBackground)
        #elseif canImport(UIKit)
            #expect(label.adjustsFontForContentSizeCategory)
        #endif
    }

    @Test func `a segmented control shows the titles it is given, in order, and the selection reads back`() {
        let control = AppUISegmentedControl()
        control.appuiSetSegments(["Draw", "Design", "Type"])
        #expect(control.appuiSegmentCount == 3)
        #expect((0 ..< 3).map { control.appuiSegmentTitle(at: $0) } == ["Draw", "Design", "Type"])
        control.appuiSelectedSegment = 1
        #expect(control.appuiSelectedSegment == 1)
        control.appuiSetSegments(["Draw"])
        #expect(control.appuiSegmentCount == 1, "setting segments replaces the earlier ones")
    }

    @Test func `a segmented control sends its primary action to one target, and a later target replaces it`() {
        let control = AppUISegmentedControl()
        control.appuiSetSegments(["A", "B"])
        let first = Receiver(), second = Receiver()
        control.appuiSetPrimaryAction(target: first, action: #selector(Receiver.fire(_:)))
        #expect(primaryActionReaches(first, from: control))
        control.appuiSetPrimaryAction(target: second, action: #selector(Receiver.fire(_:)))
        #expect(primaryActionReaches(second, from: control))
        #expect(first.count <= 1, "the first target is no longer reached")
    }

    @Test func `a button shows its symbol, sends its primary action, and its tooltip reads back`() {
        let button = AppUIButton()
        button.appuiMakeBorderless()
        button.appuiSetSymbol("eye", description: "Hide")
        #expect(button.appuiSymbolImage != nil)
        let receiver = Receiver()
        button.appuiSetPrimaryAction(target: receiver, action: #selector(Receiver.fire(_:)))
        #expect(primaryActionReaches(receiver, from: button))
        button.appuiToolTip = "Hide the object"
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            #expect(button.appuiToolTip == "Hide the object")
            #expect(!button.isBordered)
        #elseif canImport(UIKit)
            // UIKit keeps a control's tooltip in its tooltip interaction, which exists only in a running application; a test bundle with no host reads nil from both the
            // control's own property and the helper, so what is pinned here is that the helper is that property.
            #expect(button.appuiToolTip == button.toolTip)
        #endif
    }

    @Test func `a toggle button reads back the pressed state its owner sets, and the frameworks differ on a click as documented`() {
        let button = AppUIButton()
        button.appuiMakeToggle()
        button.appuiSetSymbol("scribble", description: "Freehand")
        #expect(!button.appuiIsSelected)
        button.appuiIsSelected = true
        #expect(button.appuiIsSelected)
        #expect(button.appuiSymbolImage != nil, "making it a toggle keeps the symbol")
        let receiver = Receiver()
        button.appuiSetPrimaryAction(target: receiver, action: #selector(Receiver.fire(_:)))
        #expect(primaryActionReaches(receiver, from: button))
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            #expect(!button.appuiIsSelected, "AppKit's push-on push-off button flips on a click; the owner sets the state back from its model")
        #elseif canImport(UIKit)
            #expect(!button.changesSelectionAsPrimaryAction, "UIKit does not flip the state on a tap; the owner sets it")
        #endif
        button.appuiIsSelected = false
        #expect(!button.appuiIsSelected)
    }

    @Test func `an image view's tint, a view's opacity and a stack's insets read back`() {
        let icon = AppUIImageView()
        icon.appuiContentTintColor = .appuiSecondaryLabel
        #expect(icon.appuiContentTintColor == .appuiSecondaryLabel)
        let view = AppUIView()
        view.appuiAlpha = 0.4
        // UIKit keeps a view's opacity as the layer's Float, so the read-back may differ from 0.4 by one ulp of Float(0.4), and no more.
        #expect(abs(view.appuiAlpha - 0.4) <= CGFloat(Float(0.4).ulp))
        let stack = AppUIStackView()
        stack.appuiEdgeInsets = AppUIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
        let insets = stack.appuiEdgeInsets
        #expect(insets.top == 1 && insets.left == 2 && insets.bottom == 3 && insets.right == 4)
        #if canImport(UIKit)
            #expect(stack.isLayoutMarginsRelativeArrangement, "UIKit respects the margins only when told to")
        #endif
    }
}
