import Foundation

public extension AppUIScrollView {
    /// Makes `content` what the scroll view scrolls: as wide as the scroll view and as tall as its own layout needs, so that it scrolls vertically when it is taller than the
    /// scroll view. AppKit makes it the
    /// document view and pins it to the top, left and right of the clip view; UIKit adds it to the scroll view and pins it to the content layout guide, as wide as the frame layout
    /// guide.
    func appuiSetContent(_ content: AppUIView) {
        content.translatesAutoresizingMaskIntoConstraints = false
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            documentView = content
            NSLayoutConstraint.activate([
                content.topAnchor.constraint(equalTo: contentView.topAnchor),
                content.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                content.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ])
        #elseif canImport(UIKit)
            addSubview(content)
            NSLayoutConstraint.activate([
                content.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
                content.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
                content.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
                content.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
                content.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor),
            ])
        #endif
    }
}
