//  AppUIKit.AnimationValue.swift
//  AppUIKit
//
//  Cross-framework boxing of Core Graphics values into `NSValue` for Core Animation key-value
//  animations. AppKit and UIKit name these initializers differently (`NSValue(point:)`/`NSValue(rect:)`
//  vs `NSValue(cgPoint:)`/`NSValue(cgRect:)`); a consumer animating a `CALayer` reaches one name here and
//  draws identically on both platforms, with no platform `#if` of its own.

import Foundation

public extension AppUIKit {
    /// Boxes a `CGPoint` into an `NSValue` for a Core Animation `fromValue`/`toValue`.
    static func animationValue(_ point: CGPoint) -> NSValue {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            return NSValue(point: point)
        #else
            return NSValue(cgPoint: point)
        #endif
    }

    /// Boxes a `CGRect` into an `NSValue` for a Core Animation `fromValue`/`toValue`.
    static func animationValue(_ rect: CGRect) -> NSValue {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
            return NSValue(rect: rect)
        #else
            return NSValue(cgRect: rect)
        #endif
    }
}
