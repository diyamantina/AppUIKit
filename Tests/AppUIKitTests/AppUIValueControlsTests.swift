import Testing
@testable import AppUIKit

/// The value controls a shared chrome is written against: a slider, a colour well and a choice button each read back on either framework what they were told, and say when the
/// person changes them.
@MainActor
@Suite("AppUIKit value controls")
struct AppUIValueControlsTests {
    @Test func `a slider keeps its range and value, clamps to the range, and reports once when released`() {
        let slider = AppUISlider()
        slider.appuiConfigure(range: 0 ... 100, value: 40)
        #expect(slider.appuiValue == 40)
        slider.appuiValue = 250
        #expect(slider.appuiValue == 100, "a value beyond the range is held at its end")
        slider.appuiValue = -5
        #expect(slider.appuiValue == 0)
        #expect(!slider.isContinuous)
    }

    @Test func `a colour well reads back the colour it was given`() throws {
        let well = AppUIColorWell()
        let colour = AppUIColor(srgbRed: 0.25, green: 0.5, blue: 0.75, alpha: 1)
        well.appuiColor = colour
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let read = try #require(well.appuiColor.usingColorSpace(.sRGB))
            #expect(abs(read.redComponent - 0.25) < 1e-6 && abs(read.blueComponent - 0.75) < 1e-6)
        #elseif canImport(UIKit)
            #expect(abs(well.appuiColor.redComponent - 0.25) < 1e-6 && abs(well.appuiColor.blueComponent - 0.75) < 1e-6)
        #endif
    }

    @Test func `a choice button shows the selected title, can be set without a callback, and an index outside the titles shows none`() {
        let button = AppUIChoiceButton(titles: ["Normal", "Multiply", "Screen"], selected: 1)
        var chosen: [Int] = []
        button.onChoose = { chosen.append($0) }
        #expect(button.selectedIndex == 1)
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            #expect(button.titleOfSelectedItem == "Multiply")
        #elseif canImport(UIKit)
            #expect(button.title(for: .normal) == "Multiply")
        #endif
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            button.selectedIndex = 2
        #else
            button.show(2)
        #endif
        #expect(button.selectedIndex == 2 && chosen.isEmpty, "setting the choice is not the person's choosing")
        button.appuiSetTitles(["A", "B"], selected: 5)
        #expect(button.selectedIndex == -1)
    }
}
