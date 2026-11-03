import Testing
@testable import AppUIKit

/// The scroll view helper a shared chrome is written against: the content is what the scroll view scrolls, as wide as the scroll view and as tall as its own layout needs.
@MainActor
@Suite("AppUIKit scroll view content")
struct AppUIScrollViewContentTests {
    @Test func `the content is as wide as the scroll view and keeps the height its layout asks for, so a taller content scrolls`() {
        let scroll = AppUIKit.ViewFactory.scrollView()
        scroll.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let content = AppUIView()
        let tall = AppUIView()
        tall.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(tall)
        NSLayoutConstraint.activate([
            tall.topAnchor.constraint(equalTo: content.topAnchor), tall.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            tall.trailingAnchor.constraint(equalTo: content.trailingAnchor), tall.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            tall.heightAnchor.constraint(equalToConstant: 500),
        ])
        scroll.appuiSetContent(content)
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            scroll.layoutSubtreeIfNeeded()
            #expect(content.superview === scroll.documentView && scroll.documentView?.isFlipped == true, "the content lies in a flipped holder that is the document view")
        #elseif canImport(UIKit)
            scroll.layoutIfNeeded()
            #expect(content.superview === scroll)
        #endif
        #expect(content.frame.width == 200, "as wide as the scroll view")
        #expect(content.frame.height == 500, "as tall as its layout asks, which is more than the scroll view")
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        @Test func `a content shorter than the scroll view lies at the top of it, not at the bottom`() {
            let scroll = AppUIKit.ViewFactory.scrollView()
            scroll.frame = CGRect(x: 0, y: 0, width: 200, height: 400)
            let content = AppUIView()
            let short = AppUIView()
            short.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(short)
            NSLayoutConstraint.activate([
                short.topAnchor.constraint(equalTo: content.topAnchor), short.leadingAnchor.constraint(equalTo: content.leadingAnchor),
                short.trailingAnchor.constraint(equalTo: content.trailingAnchor), short.bottomAnchor.constraint(equalTo: content.bottomAnchor),
                short.heightAnchor.constraint(equalToConstant: 50),
            ])
            scroll.appuiSetContent(content)
            scroll.layoutSubtreeIfNeeded()
            let rect = scroll.convert(short.bounds, from: short)
            let gapFromTop = scroll.isFlipped ? rect.minY : scroll.bounds.height - rect.maxY
            #expect(gapFromTop == 0, "the content starts \(gapFromTop) points under the top")
        }
    #endif
}
