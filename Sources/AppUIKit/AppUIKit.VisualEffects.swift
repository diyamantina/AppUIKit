//
//  AppUIKit.VisualEffects.swift
//  AppUIKit
//
//  Platform-specific visual effect materials and blur styles.
//

#if os(macOS)

    public extension AppUIKit {
        /// Semantic visual effect materials with availability handling.
        ///
        /// Access via `AppUIKit.VisualEffectMaterial.sidebar`, etc.
        enum VisualEffectMaterial {
            case sidebar
            case headerView
            case contentBackground
            case menu
            case popover
            case titlebar

            /// Returns the NSVisualEffectView.Material with availability handling.
            @available(macOS 10.10, *)
            public var nsMaterial: NSVisualEffectView.Material {
                if #available(macOS 10.14, *) {
                    switch self {
                    case .sidebar: .sidebar
                    case .headerView: .headerView
                    case .contentBackground: .contentBackground
                    case .menu: .menu
                    case .popover: .popover
                    case .titlebar: .titlebar
                    }
                } else {
                    // Fallback for older macOS versions
                    switch self {
                    case .sidebar, .contentBackground: .light
                    case .headerView, .titlebar: .titlebar
                    case .menu, .popover: .menu
                    }
                }
            }
        }
    }
#endif

#if os(iOS)

    public extension AppUIKit {
        /// Semantic blur effect styles with availability handling.
        ///
        /// Access via `AppUIKit.BlurEffectStyle.systemMaterial`, etc.
        enum BlurEffectStyle {
            case systemMaterial
            case systemThinMaterial
            case systemUltraThinMaterial
            case systemThickMaterial
            case systemChromeMaterial
            case regular
            case prominent

            /// Returns the UIBlurEffect.Style with availability handling.
            public var uiStyle: UIBlurEffect.Style {
                if #available(iOS 13.0, *) {
                    switch self {
                    case .systemMaterial: .systemMaterial
                    case .systemThinMaterial: .systemThinMaterial
                    case .systemUltraThinMaterial: .systemUltraThinMaterial
                    case .systemThickMaterial: .systemThickMaterial
                    case .systemChromeMaterial: .systemChromeMaterial
                    case .regular: .regular
                    case .prominent: .prominent
                    }
                } else {
                    // Fallback for older iOS versions
                    switch self {
                    case .regular, .systemMaterial, .systemThinMaterial, .systemUltraThinMaterial, .systemThickMaterial:
                        .regular
                    case .prominent, .systemChromeMaterial:
                        .prominent
                    }
                }
            }
        }
    }
#endif
