import Foundation

public extension AppUIButton {
    /// Shows the SF Symbol `name` and nothing else on the button. AppKit sets the image with `description` as what VoiceOver reads and shows the image only; UIKit sets the
    /// image of the button's configuration when it has one, and otherwise the image of its normal state.
    func appuiSetSymbol(_ name: String, description: String) {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            image = AppUIImage.appUISymbol(name, description: description)
            imagePosition = .imageOnly
        #elseif canImport(UIKit)
            let symbol = AppUIImage.appUISymbol(name, description: description)
            if configuration != nil {
                configuration?.image = symbol
            } else {
                setImage(symbol, for: .normal)
            }
        #endif
    }

    /// The image the button shows: on AppKit its image, on UIKit the image of its configuration or of its normal state.
    var appuiSymbolImage: AppUIImage? {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            image
        #elseif canImport(UIKit)
            configuration?.image ?? image(for: .normal)
        #endif
    }

    /// Whether the button is shown pressed: the on state of an AppKit toggle, `isSelected` on UIKit (which also carries the selected accessibility trait).
    var appuiIsSelected: Bool {
        get {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                return state == .on
            #elseif canImport(UIKit)
                return isSelected
            #endif
        }
        set {
            #if canImport(AppKit) && !targetEnvironment(macCatalyst)
                state = newValue ? .on : .off
                // UIKit's `isSelected` carries the selected accessibility state; an AppKit toggle says it with its on state only, so VoiceOver and a UI test (`isSelected`) read it
                // from here as well.
                setAccessibilitySelected(newValue)
            #elseif canImport(UIKit)
                isSelected = newValue
            #endif
        }
    }

    /// Makes the button a toggle whose pressed state is `appuiIsSelected`: a push-on push-off button with a square textured bezel on AppKit; on UIKit a plain configuration
    /// with rounded corners whose background is tinted while selected. The owner sets the state from its model when it handles the action: UIKit does not flip the state on
    /// a tap (`changesSelectionAsPrimaryAction` is off), AppKit's push-on push-off button does flip it on a click, so the owner's refresh is what makes both show the model.
    func appuiMakeToggle() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            setButtonType(.pushOnPushOff)
            bezelStyle = .texturedSquare
        #elseif canImport(UIKit)
            var plain = AppUIButton.Configuration.plain()
            plain.cornerStyle = .medium
            configuration = plain
            changesSelectionAsPrimaryAction = false
            configurationUpdateHandler = { button in
                button.configuration?.background.backgroundColor = button.isSelected ? AppUIColor.tintColor.withAlphaComponent(0.2) : .clear
            }
        #endif
    }

    /// Makes the button a bare image with no border or background: borderless and image-only on AppKit, a plain configuration on UIKit.
    func appuiMakeBorderless() {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            isBordered = false
            imagePosition = .imageOnly
        #elseif canImport(UIKit)
            configuration = .plain()
        #endif
    }
}
