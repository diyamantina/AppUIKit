import CACanvas
import CoreGraphics
import Foundation
import Testing
@testable import AppUIKit

/// The arithmetic of dragging the handles of a selection's frame, proven against the closed forms worked out by hand, and the zones of a
/// press on the frame. The frame in every case is `x 100 y 50 w 200 h 100` (right edge 300, bottom edge 150, centre 200, 100).
@Suite("AppUICanvas: dragging the frame of a selection")
@MainActor
struct AppUICanvasFrameTests {
    static let frame = CGRect(x: 100, y: 50, width: 200, height: 100)
    private typealias Handle = AppUICanvas.FrameHandle
    private typealias Drag = AppUICanvas.FrameDrag

    private static func constraint(_ shift: Bool, _ option: Bool) -> AppUICanvas.FrameConstraint {
        [shift ? .proportional : [], option ? .fromCentre : []]
    }

    private static func scaling(_ handle: Handle, dx: CGFloat, dy: CGFloat, shift: Bool = false, option: Bool = false) -> AppUICanvas.FrameScaling {
        let start = handle.point(in: frame)
        return Drag.resize(frame: frame, handle: handle, from: start, to: CGPoint(x: start.x + dx, y: start.y + dy), constraint: constraint(shift, option))
    }

    @Test("FRM1: a handle's point is the corner or the middle of the edge it names, and its opposite is across the centre")
    func handlePoints() {
        let expected: [(Handle, CGPoint)] = [
            (.topLeft, CGPoint(x: 100, y: 50)), (.top, CGPoint(x: 200, y: 50)), (.topRight, CGPoint(x: 300, y: 50)), (.right, CGPoint(x: 300, y: 100)),
            (.bottomRight, CGPoint(x: 300, y: 150)), (.bottom, CGPoint(x: 200, y: 150)), (.bottomLeft, CGPoint(x: 100, y: 150)), (.left, CGPoint(x: 100, y: 100)),
        ]
        for (handle, point) in expected {
            #expect(handle.point(in: Self.frame) == point, "\(handle)")
            let across = handle.opposite.point(in: Self.frame)
            #expect(across.x + point.x == 400 && across.y + point.y == 200, "\(handle) and its opposite are symmetric about the centre (200, 100)")
            #expect(handle.opposite.opposite == handle)
        }
        #expect(Handle.allCases.map(\.rawValue) == Array(0 ..< 8), "the order is the chrome's: clockwise from the top left")
    }

    @Test("FRM2: dragging the bottom right corner by (+40, +30) keeps the top left and scales by 240/200 and 130/100")
    func cornerResize() {
        let scaling = Self.scaling(.bottomRight, dx: 40, dy: 30)
        #expect(scaling.pivot == CGPoint(x: 100, y: 50))
        #expect(abs(scaling.sx - 1.2) < 1e-12 && abs(scaling.sy - 1.3) < 1e-12)
        // The pivot stays and the dragged corner goes where the pointer went.
        let map = scaling.matrix
        #expect(CGPoint(x: 100, y: 50).applying(map) == CGPoint(x: 100, y: 50))
        let corner = CGPoint(x: 300, y: 150).applying(map)
        #expect(abs(corner.x - 340) < 1e-9 && abs(corner.y - 180) < 1e-9, "the corner is where the pointer is")
    }

    @Test("FRM3: dragging the top left corner by (+50, -25) keeps the bottom right: widths 200 - 50 and 100 + 25")
    func oppositeCorner() {
        let scaling = Self.scaling(.topLeft, dx: 50, dy: -25)
        #expect(scaling.pivot == CGPoint(x: 300, y: 150))
        #expect(abs(scaling.sx - 150.0 / 200) < 1e-12 && abs(scaling.sy - 125.0 / 100) < 1e-12)
    }

    @Test("FRM4: a side handle scales one axis only, about the opposite edge")
    func sideResize() {
        let right = Self.scaling(.right, dx: 60, dy: 999)
        #expect(right.sy == 1 && abs(right.sx - 1.3) < 1e-12 && right.pivot.x == 100, "the right edge ignores the vertical travel")
        let top = Self.scaling(.top, dx: 999, dy: -20)
        #expect(top.sx == 1 && abs(top.sy - 1.2) < 1e-12 && top.pivot.y == 150, "the top edge ignores the horizontal travel")
    }

    @Test("FRM5: Option holds the centre and counts the travel twice: the right handle by +30 grows the width by 60")
    func fromCentre() {
        let scaling = Self.scaling(.right, dx: 30, dy: 0, option: true)
        #expect(scaling.pivot == CGPoint(x: 200, y: 100) && abs(scaling.sx - 260.0 / 200) < 1e-12)
        let corner = Self.scaling(.bottomRight, dx: 10, dy: 20, option: true)
        #expect(abs(corner.sx - 220.0 / 200) < 1e-12 && abs(corner.sy - 140.0 / 100) < 1e-12)
    }

    @Test("FRM6: Shift gives one factor: the larger for a corner, the moved axis for a side")
    func proportional() {
        let corner = Self.scaling(.bottomRight, dx: 40, dy: 30, shift: true)
        #expect(abs(corner.sx - 1.3) < 1e-12 && corner.sx == corner.sy, "1.2 and 1.3: the larger")
        let side = Self.scaling(.right, dx: 20, dy: 0, shift: true)
        #expect(abs(side.sx - 1.1) < 1e-12 && side.sy == side.sx, "the side's factor goes to both axes")
        let both = Self.scaling(.bottomRight, dx: 20, dy: 20, shift: true, option: true)
        #expect(
            abs(both.sx - 1.4) < 1e-12 && both.sx == both.sy && both.pivot == CGPoint(x: 200, y: 100),
            "Shift and Option together: proportional about the centre, the larger of 1.2 and 1.4"
        )
    }

    @Test(
        "FRM7: a drag past the opposite edge mirrors, as in Sketch: the right handle by -300 on a width of 200 is a factor of -0.5, and the size never reaches zero"
    )
    func crossing() {
        let crossed = Self.scaling(.right, dx: -300, dy: 0)
        #expect(abs(crossed.sx + 0.5) < 1e-12 && crossed.flipsX && !crossed.flipsY)
        let landed = Self.scaling(.right, dx: -200, dy: 0)
        #expect(landed.sx == Drag.factorRange.lowerBound, "on the opposite edge itself: the smallest size, never zero")
        let nearly = Self.scaling(.right, dx: -200.0001, dy: 0)
        #expect(nearly.sx == -Drag.factorRange.lowerBound, "just past it: the smallest size, mirrored")
        let huge = Self.scaling(.right, dx: 10_000_000, dy: 0)
        #expect(huge.sx == Drag.factorRange.upperBound)
        let far = Self.scaling(.right, dx: -10_000_000, dy: 0)
        #expect(far.sx == -Drag.factorRange.upperBound)
    }

    @Test("FRM7b: with .keepsSide a crossing holds the smallest size and does not mirror")
    func keepsSide() {
        let start = Handle.right.point(in: Self.frame)
        let held = Drag.resize(frame: Self.frame, handle: .right, from: start, to: CGPoint(x: start.x - 500, y: start.y), constraint: .keepsSide)
        #expect(held.sx == Drag.factorRange.lowerBound && !held.flipsX)
        let corner = Drag.resize(frame: Self.frame, handle: .bottomRight, from: start, to: CGPoint(x: start.x - 500, y: start.y - 500), constraint: .keepsSide)
        #expect(corner.sx == Drag.factorRange.lowerBound && corner.sy == Drag.factorRange.lowerBound)
    }

    @Test("FRM7c: the box of a mirrored scale, by the closed form: the scaled box moved to the mirror image across the pivot")
    func mirrorShift() {
        // The right handle by -300: pivot x 100, factor -0.5. The box 100...300 scales by 0.5 about 100 to 100...200 and its mirror image across 100 is 0...100: a shift of -100 =
        // 2 * 100 - 100 - 200.
        let scaling = Self.scaling(.right, dx: -300, dy: 0)
        let shift = scaling.shift(of: Self.frame)
        #expect(abs(shift.dx + 100) < 1e-9 && shift.dy == 0)
        // The mirror image of the scaled box 100...200 across 100 is 0...100, and the box moved by the shift is 0...100.
        #expect(abs((100 + shift.dx) - 0) < 1e-9 && abs((200 + shift.dx) - 100) < 1e-9)
        // Both axes, from the top left corner by (+300, +150): pivot (300, 150), factors (200 - 300) / 200 = -0.5 and (100 - 150) / 100 = -0.5.
        let both = Drag.resize(frame: Self.frame, handle: .topLeft, from: CGPoint(x: 100, y: 50), to: CGPoint(x: 400, y: 200))
        #expect(abs(both.sx + 0.5) < 1e-12 && abs(both.sy + 0.5) < 1e-12)
        let moved = both.shift(of: Self.frame)
        // x: 100...300 scales by 0.5 about 300 to 200...300, mirror across 300 is 300...400, so the shift is 600 - 200 - 300 = 100.
        // y: 50...150 scales by 0.5 about 150 to 100...150, mirror across 150 is 150...200, so the shift is 300 - 100 - 150 = 50.
        #expect(abs(moved.dx - 100) < 1e-9 && abs(moved.dy - 50) < 1e-9)
        #expect(Self.scaling(.right, dx: 40, dy: 0).shift(of: Self.frame) == .zero, "no shift without a mirror")
    }

    @Test("FRM8: no travel is the identity; an axis with no extent keeps its factor")
    func degenerate() {
        #expect(Self.scaling(.bottomRight, dx: 0, dy: 0).isIdentity)
        let line = CGRect(x: 10, y: 10, width: 100, height: 0)
        let scaling = Drag.resize(frame: line, handle: .bottomRight, from: CGPoint(x: 110, y: 10), to: CGPoint(x: 160, y: 40))
        #expect(abs(scaling.sx - 1.5) < 1e-12 && scaling.sy == 1, "a line cannot be made taller by scaling")
    }

    @Test("FRM9: the rotation is the signed angle between the two directions from the centre, clockwise on the screen, in (-180, 180]")
    func rotation() {
        let centre = CGPoint(x: 200, y: 100)
        func angle(_ to: CGPoint, step: Double? = nil) -> Double {
            Drag.rotation(about: centre, from: CGPoint(x: 300, y: 100), to: to, step: step)
        }
        #expect(angle(CGPoint(x: 200, y: 200)) == 90, "from the right to below is a quarter turn clockwise on a y-down screen")
        #expect(angle(CGPoint(x: 100, y: 100)) == 180)
        #expect(angle(CGPoint(x: 200, y: 0)) == -90)
        #expect(abs(angle(CGPoint(x: 300, y: 100 + 100 * tan(30 * Double.pi / 180))) - 30) < 1e-9)
        #expect(angle(CGPoint(x: 400, y: 100)) == 0)
        #expect(Drag.rotation(about: centre, from: centre, to: CGPoint(x: 300, y: 100)) == 0, "no direction at the centre")
        #expect(angle(CGPoint(x: 300, y: 100 + 100 * tan(22 * Double.pi / 180)), step: 15) == 15, "22 degrees snaps to 15")
        #expect(angle(CGPoint(x: 300, y: 100 + 100 * tan(23 * Double.pi / 180)), step: 15) == 30, "23 degrees snaps to 30")
    }

    @Test("FRM10: the map of a turn sends points by the closed form and leaves the centre")
    func turnMatrix() {
        let centre = CGPoint(x: 200, y: 100)
        let quarter = Drag.turn(degrees: 90, about: centre)
        let moved = CGPoint(x: 300, y: 100).applying(quarter)
        #expect(abs(moved.x - 200) < 1e-9 && abs(moved.y - 200) < 1e-9, "(300, 100) is 100 right of the centre and goes 100 below it")
        let stays = centre.applying(quarter)
        #expect(abs(stays.x - 200) < 1e-9 && abs(stays.y - 100) < 1e-9)
        #expect(Drag.turn(degrees: 0, about: centre) == .identity)
        let half = CGPoint(x: 300, y: 100).applying(Drag.turn(degrees: 180, about: centre))
        #expect(abs(half.x - 100) < 1e-9 && abs(half.y - 100) < 1e-9)
    }

    // MARK: where a press lands

    private static var viewport: CACanvas.Viewport {
        CACanvas.Viewport(scale: 2, offset: CGPoint(x: 10, y: 20))
    }

    /// The frame on the view: x 210 ... 610, y 120 ... 320.
    private static func hit(_ x: CGFloat, _ y: CGFloat) -> AppUICanvas.FrameHit {
        AppUICanvas.FrameHit.at(CGPoint(x: x, y: y), frame: frame, viewport: viewport)
    }

    @Test("FRM11: the handles, nearest first and a corner before a side, then the edges anywhere along them")
    func zones() {
        #expect(Self.hit(210, 120) == .handle(.topLeft) && Self.hit(612, 322) == .handle(.bottomRight))
        #expect(Self.hit(410, 120) == .handle(.top) && Self.hit(610, 220) == .handle(.right))
        #expect(Self.hit(300, 121) == .handle(.top), "anywhere along the top edge, not only at the handle")
        #expect(Self.hit(211, 260) == .handle(.left) && Self.hit(500, 318) == .handle(.bottom))
        #expect(Self.hit(300, 126) == .handle(.top), "within six view points of the edge")
        #expect(Self.hit(300, 128) == .body, "and seven or more inside is the body")
    }

    @Test("FRM12: inside is the body, just outside a corner is the rotate zone, and the rotation handle above the top edge rotates")
    func bodyAndRotate() {
        #expect(Self.hit(400, 220) == .body)
        #expect(Self.hit(195, 105) == .rotate && Self.hit(625, 335) == .rotate && Self.hit(195, 335) == .rotate && Self.hit(625, 105) == .rotate)
        #expect(Self.hit(410, 96) == .rotate, "the rotation handle, 24 view points above the middle of the top edge")
        #expect(Self.hit(100, 100) == .none && Self.hit(410, 400) == .none && Self.hit(300, 100) == .none, "far from the frame, or beside an edge")
    }

    @Test("FRM13: a frame too small for side handles offers corners only, and a line has no top or bottom to drag")
    func smallFrames() {
        let viewport = CACanvas.Viewport()
        let small = CGRect(x: 0, y: 0, width: 10, height: 10)
        let top = AppUICanvas.FrameHit.at(CGPoint(x: 5, y: 0), frame: small, viewport: viewport)
        #expect(top == .handle(.topLeft) || top == .handle(.topRight), "a 10 point frame has no top handle: a corner takes it")
        let line = CGRect(x: 0, y: 50, width: 200, height: 0)
        #expect(
            AppUICanvas.FrameHit.at(CGPoint(x: 100, y: 50), frame: line, viewport: viewport) == .none,
            "the middle of a line is no handle and no edge band: a press there carries it"
        )
        let end = AppUICanvas.FrameHit.at(CGPoint(x: 200, y: 50), frame: line, viewport: viewport)
        #expect(end == .handle(.topRight) || end == .handle(.bottomRight), "its end is a corner handle, which lengthens it along x")
    }

    @Test("SKP2: Shift keeps the longer axis of a move and zeroes the other, a tie keeps the horizontal, and without Shift the drag is as it was")
    func axisLock() {
        typealias Move = AppUICanvas.MoveDrag
        #expect(Move.delta(raw: CGSize(width: 40, height: 20), lockedToAxis: true) == CGSize(width: 40, height: 0))
        #expect(Move.delta(raw: CGSize(width: 10, height: -30), lockedToAxis: true) == CGSize(width: 0, height: -30))
        #expect(Move.delta(raw: CGSize(width: 25, height: 25), lockedToAxis: true) == CGSize(width: 25, height: 0), "a tie keeps the horizontal")
        #expect(Move.delta(raw: CGSize(width: -25, height: 25), lockedToAxis: true) == CGSize(width: -25, height: 0))
        #expect(Move.delta(raw: CGSize(width: 40, height: 20), lockedToAxis: false) == CGSize(width: 40, height: 20))
    }

    @Test("the reach grows with the device: a fingertip's targets are the 44 point target of Apple's guidelines, a mouse's are exact")
    func reaches() {
        let mouse = AppUICanvas.FrameReach.of(.mouse), pencil = AppUICanvas.FrameReach.of(.pencil), touch = AppUICanvas.FrameReach.of(.touch)
        #expect(AppUICanvas.FrameReach.of(.trackpad) == mouse)
        #expect(mouse.handle < pencil.handle && pencil.handle < touch.handle)
        #expect(mouse.rotate < pencil.rotate && pencil.rotate < touch.rotate)
        #expect(touch.handle * 2 >= 44, "a diameter of 44 points")
    }

    @Test("a press 15 points from a corner misses the handle with a mouse and takes it with a finger")
    func fingerReachesFurther() {
        let viewport = CACanvas.Viewport(scale: 2, offset: CGPoint(x: 10, y: 20))
        // The frame is x 210 ... 610 and y 120 ... 320 on the view. The point is 15 points from the top left corner, along the edge.
        let near = CGPoint(x: 225, y: 120)
        let withMouse = AppUICanvas.FrameHit.at(near, frame: Self.frame, viewport: viewport, device: .mouse)
        let withFinger = AppUICanvas.FrameHit.at(near, frame: Self.frame, viewport: viewport, device: .touch)
        #expect(withMouse == .handle(.top), "a mouse is on the top edge band, not the corner handle")
        #expect(withFinger == .handle(.topLeft), "a finger takes the corner it is near")
        let outside = CGPoint(x: 180, y: 90)
        #expect(AppUICanvas.FrameHit.at(outside, frame: Self.frame, viewport: viewport, device: .mouse) == .none, "42 points from the corner is out of a mouse's rotate zone")
        #expect(AppUICanvas.FrameHit.at(outside, frame: Self.frame, viewport: viewport, device: .touch) == .rotate, "and inside a finger's")
    }
}
