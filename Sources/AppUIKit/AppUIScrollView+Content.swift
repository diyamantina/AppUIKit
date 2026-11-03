import Foundation

public extension AppUIScrollView {
    /// Makes `content` what the scroll view scrolls: as wide as the scroll view and as tall as its own layout needs, so that it scrolls vertically when it is taller than the
    /// scroll view. AppKit makes a top left holder (`AppUITopLeftView`) the document view and pins the holder to the top, left and right of the clip view and the content inside
    /// it. A clip view takes the
    /// orientation of its document view, and a document view that is not flipped and is shorter than the clip view lies at the bottom edge, so the holder is what keeps a short
    /// content at the top; UIKit adds it to the scroll view and pins it to the content layout guide, as wide as the frame layout
    /// guide.
    func appuiSetContent(_ content: AppUIView) {
        content.translatesAutoresizingMaskIntoConstraints = false
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            let holder = AppUITopLeftView()
            holder.translatesAutoresizingMaskIntoConstraints = false
            holder.addSubview(content)
            documentView = holder
            NSLayoutConstraint.activate([
                content.topAnchor.constraint(equalTo: holder.topAnchor),
                content.leadingAnchor.constraint(equalTo: holder.leadingAnchor),
                content.trailingAnchor.constraint(equalTo: holder.trailingAnchor),
                content.bottomAnchor.constraint(equalTo: holder.bottomAnchor),
                holder.topAnchor.constraint(equalTo: contentView.topAnchor),
                holder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                holder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
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
