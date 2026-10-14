//  AppUIRepresentable.swift
//  AppUIKit
//
//  A SwiftUI view that hosts an AppKit or UIKit view, written once. AppKit names the two requirements `makeNSView` and
//  `updateNSView`, UIKit names them `makeUIView` and `updateUIView`; a conformer here writes `makeAppUIView` and
//  `updateAppUIView`, and the framework's own names forward to them.

#if canImport(SwiftUI)
    import SwiftUI

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        /// A SwiftUI view that hosts a platform view, with the same two requirements on macOS and iOS.
        public protocol AppUIRepresentable: NSViewRepresentable where NSViewType == AppUIViewType {
            /// The hosted view's type, which the framework's own `NSViewType` is pinned to.
            associatedtype AppUIViewType: NSView
            /// Makes the hosted view once, when SwiftUI first needs it.
            func makeAppUIView(context: Context) -> AppUIViewType
            /// Brings the hosted view up to date with the SwiftUI state.
            func updateAppUIView(_ view: AppUIViewType, context: Context)
        }

        @MainActor
        public extension AppUIRepresentable {
            func makeNSView(context: Context) -> NSViewType {
                makeAppUIView(context: context)
            }

            func updateNSView(_ view: NSViewType, context: Context) {
                updateAppUIView(view, context: context)
            }
        }
    #elseif canImport(UIKit)
        /// A SwiftUI view that hosts a platform view, with the same two requirements on macOS and iOS.
        public protocol AppUIRepresentable: UIViewRepresentable where UIViewType == AppUIViewType {
            /// The hosted view's type, which the framework's own `UIViewType` is pinned to.
            associatedtype AppUIViewType: UIView
            /// Makes the hosted view once, when SwiftUI first needs it.
            func makeAppUIView(context: Context) -> AppUIViewType
            /// Brings the hosted view up to date with the SwiftUI state.
            func updateAppUIView(_ view: AppUIViewType, context: Context)
        }

        @MainActor
        public extension AppUIRepresentable {
            func makeUIView(context: Context) -> UIViewType {
                makeAppUIView(context: context)
            }

            func updateUIView(_ view: UIViewType, context: Context) {
                updateAppUIView(view, context: context)
            }
        }
    #endif
#endif
