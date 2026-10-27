// AppUIReservedRegion.swift
// AppUIKit
//
// The words of reserved regions and of the hinge, the same on AppKit and UIKit.

import ForwardsCore

/// An area of a view that something else reserves: the fold of a foldable iPhone (a division) or a camera (an occlusion). Frames are in the view's coordinate space.
public typealias AppUIReservedRegion = ForwardReservedRegion

/// Whether a reserved region divides the content (the fold of a hinge) or covers it (a camera, the Dynamic Island).
public typealias AppUIRegionKind = ForwardRegionKind

/// The state of a hinge: closed, partly open or fully open, and its angle in radians.
public typealias AppUIHinge = ForwardHinge
