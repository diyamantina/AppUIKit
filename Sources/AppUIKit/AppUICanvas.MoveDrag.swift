//
//  AppUICanvas.MoveDrag.swift
//  AppUIKit
//

import CoreGraphics

public extension AppUICanvas {
    /// The arithmetic of carrying a selection: the distance the shapes are shown moved by while the pointer is down.
    enum MoveDrag {
        /// The distance a drag of `raw` moves the selection by. With `lockedToAxis` (Shift) the longer axis is kept and the other is zero; on a tie it is the horizontal.
        public static func delta(raw: CGSize, lockedToAxis: Bool) -> CGSize {
            guard lockedToAxis else { return raw }
            return abs(raw.height) > abs(raw.width) ? CGSize(width: 0, height: raw.height) : CGSize(width: raw.width, height: 0)
        }
    }
}
