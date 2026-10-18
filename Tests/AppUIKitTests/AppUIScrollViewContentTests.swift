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
            #expect(scroll.documentView === content)
        #elseif canImport(UIKit)
            scroll.layoutIfNeeded()
            #expect(content.superview === scroll)
        #endif
        #expect(content.frame.width == 200, "as wide as the scroll view")
        #expect(content.frame.height == 500, "as tall as its layout asks, which is more than the scroll view")
    }
}
