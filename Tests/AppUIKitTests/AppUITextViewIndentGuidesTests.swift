#if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit
    import Foundation
    import Testing
    @testable import AppUIKit

    /// The guides through the indentation of the lines of a text view, held by pixels.
    @MainActor
    struct AppUITextViewIndentGuidesTests {
        private func make(_ text: String) throws -> (NSTextView, NSScrollView, NSWindow) {
            let (textView, container) = AppUITextView.appuiMakeScrolling()
            let scroll = try #require(container as? NSScrollView)
            let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 400, height: 240), styleMask: [.titled], backing: .buffered, defer: false)
            scroll.frame = try #require(window.contentView).bounds
            window.contentView?.addSubview(scroll)
            textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            textView.backgroundColor = .white
            textView.textColor = .white
            textView.isRichText = false
            textView.string = text
            try relayout(textView)
            return (textView, scroll, window)
        }

        private func relayout(_ textView: NSTextView) throws {
            let container = try #require(textView.textContainer)
            textView.layoutManager?.ensureLayout(for: container)
        }

        private func render(_ textView: NSTextView) throws -> NSBitmapImageRep {
            let image = try #require(textView.bitmapImageRepForCachingDisplay(in: textView.visibleRect))
            textView.cacheDisplay(in: textView.visibleRect, to: image)
            return image
        }

        /// Whether the pixel at a place of the text view, in points, is not the white of the background.
        private func inked(_ image: NSBitmapImageRep, _ textView: NSTextView, at place: (x: CGFloat, y: CGFloat)) -> Bool {
            let scale = CGFloat(image.pixelsWide) / textView.visibleRect.width
            guard let color = image.colorAt(x: Int(place.x * scale), y: Int((place.y - textView.visibleRect.minY) * scale))?.usingColorSpace(.deviceRGB) else {
                return false
            }
            return color.redComponent < 0.97 || color.greenComponent < 0.97 || color.blueComponent < 0.97
        }

        /// The middle of the pixel the guide of `level` (from 1) of lines indented in `unit`s is on, and the middle of the line `number` (from 0).
        private func place(_ level: Int, line number: Int, in textView: NSTextView, image: NSBitmapImageRep) throws -> (x: CGFloat, y: CGFloat) {
            let layout = try #require(textView.layoutManager)
            let font = try #require(textView.font)
            let container = try #require(textView.textContainer)
            let characters = textView.string as NSString
            var start = 0
            for _ in 0 ..< number {
                start = NSMaxRange(characters.lineRange(for: NSRange(location: start, length: 0)))
            }
            let fragment = layout.lineFragmentRect(forGlyphAt: layout.glyphIndexForCharacter(at: start), effectiveRange: nil)
            let width = (" " as NSString).size(withAttributes: [.font: font]).width
            let scale = CGFloat(image.pixelsWide) / textView.visibleRect.width
            let origin = textView.textContainerOrigin.x + container.lineFragmentPadding + CGFloat((level - 1) * 2) * width
            return (AppUIIndentGuides.rect(x: origin, top: 0, bottom: 1, scale: scale).minX + 0.5 / scale, fragment.midY + textView.textContainerOrigin.y)
        }

        @Test func `a text view with guides has one at the left edge of each level of a line's indentation, none through its text, and none when taken away`() throws {
            let (textView, scroll, window) = try make("a\n  b\n    c\n  d\n")
            defer { withExtendedLifetime((scroll, window)) {} }
            #expect(textView.appuiIndentGuideUnit == nil)
            let before = try render(textView)
            let first = try place(1, line: 2, in: textView, image: before)
            #expect(!inked(before, textView, at: first), "nothing is drawn until guides are asked for")
            textView.appuiIndentGuideUnit = 2
            #expect(textView.appuiIndentGuideUnit == 2)
            let on = try render(textView)
            let second = try place(2, line: 2, in: textView, image: on)
            let third = try place(3, line: 2, in: textView, image: on)
            #expect(inked(on, textView, at: first) && inked(on, textView, at: second), "both levels of `    c`")
            #expect(!inked(on, textView, at: third), "no third: the text begins there")
            let oneOfB = try place(1, line: 1, in: textView, image: on)
            let twoOfB = try place(2, line: 1, in: textView, image: on)
            #expect(inked(on, textView, at: oneOfB) && !inked(on, textView, at: twoOfB), "one level of `  b`")
            let ofA = try place(1, line: 0, in: textView, image: on)
            #expect(!inked(on, textView, at: ofA), "none for a line that is not indented")
            textView.appuiIndentGuideUnit = nil
            #expect(textView.appuiIndentGuideUnit == nil)
            #expect(try !inked(render(textView), textView, at: first))
        }

        @Test func `a change of the text moves the guides with it`() throws {
            let (textView, scroll, window) = try make("a\n  b\n")
            defer { withExtendedLifetime((scroll, window)) {} }
            textView.appuiIndentGuideUnit = 2
            textView.string = "a\n    b\n"
            try relayout(textView)
            let image = try render(textView)
            let two = try place(2, line: 1, in: textView, image: image)
            #expect(inked(image, textView, at: two), "the edited line has its second level")
        }
    }
#endif

#if canImport(UIKit) && !canImport(AppKit)
    import Foundation
    import Testing
    import UIKit
    @testable import AppUIKit

    /// The guides through the indentation of the lines of a text view on the iPad, held by pixels.
    @MainActor
    struct AppUITextViewIndentGuidesTouchTests {
        private func make(_ text: String) -> (UITextView, UIWindow) {
            let (textView, _) = AppUITextView.appuiMakeScrolling()
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 240))
            textView.frame = window.bounds
            textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            textView.backgroundColor = .white
            textView.textColor = .white
            textView.text = text
            window.addSubview(textView)
            window.makeKeyAndVisible()
            textView.layoutIfNeeded()
            return (textView, window)
        }

        /// Whether the pixel at a place is not the white of the background, in the view as drawn at one pixel to a point.
        private func inked(_ view: UIView, at place: (x: CGFloat, y: CGFloat)) throws -> Bool {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let image = UIGraphicsImageRenderer(size: view.bounds.size, format: format).image { context in
                view.layer.render(in: context.cgContext)
            }
            let drawn = try #require(image.cgImage)
            var bytes = [UInt8](repeating: 0, count: drawn.width * drawn.height * 4)
            let context = try #require(CGContext(
                data: &bytes, width: drawn.width, height: drawn.height, bitsPerComponent: 8, bytesPerRow: drawn.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            context.draw(drawn, in: CGRect(x: 0, y: 0, width: drawn.width, height: drawn.height))
            let offset = (Int(place.y) * drawn.width + Int(place.x)) * 4
            return bytes[offset] < 247 || bytes[offset + 1] < 247 || bytes[offset + 2] < 247
        }

        private func place(_ level: Int, line number: Int, in textView: UITextView) throws -> (x: CGFloat, y: CGFloat) {
            let font = try #require(textView.font)
            let layout = textView.layoutManager
            var start = 0
            let text = textView.text as NSString
            for _ in 0 ..< number {
                start = NSMaxRange(text.lineRange(for: NSRange(location: start, length: 0)))
            }
            let fragment = layout.lineFragmentRect(forGlyphAt: layout.glyphIndexForCharacter(at: start), effectiveRange: nil)
            let width = (" " as NSString).size(withAttributes: [.font: font]).width
            let x = textView.textContainerInset.left + textView.textContainer.lineFragmentPadding + CGFloat((level - 1) * 2) * width
            return (AppUIIndentGuides.rect(x: x, top: 0, bottom: 1, scale: 1).minX + 0.5, fragment.midY + textView.textContainerInset.top)
        }

        @Test func `a text view with guides has one at the left edge of each level of a line's indentation, and none when they are taken away`() throws {
            let (textView, window) = make("a\n  b\n    c\n")
            defer { withExtendedLifetime(window) {} }
            let first = try place(1, line: 2, in: textView)
            #expect(try !inked(textView, at: first))
            textView.appuiIndentGuideUnit = 2
            #expect(textView.appuiIndentGuideUnit == 2)
            textView.layoutIfNeeded()
            let second = try place(2, line: 2, in: textView)
            let third = try place(3, line: 2, in: textView)
            #expect(try inked(textView, at: first) && inked(textView, at: second), "both levels of `    c`")
            #expect(try !inked(textView, at: third))
            let oneOfB = try place(1, line: 1, in: textView)
            let twoOfB = try place(2, line: 1, in: textView)
            #expect(try inked(textView, at: oneOfB) && !inked(textView, at: twoOfB))
            textView.appuiIndentGuideUnit = nil
            #expect(try !inked(textView, at: first))
        }
    }
#endif
