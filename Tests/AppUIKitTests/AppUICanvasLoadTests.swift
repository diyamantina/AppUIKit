import CoreGraphics
import Testing
@testable import AppUIKit

/// The stream keeps the order and loses nothing while the consumer is slower than the producer. The control is the design the canvas does not
/// use, one task for each event, which gives up the order the platform delivered.
@MainActor
@Suite("AppUICanvas under load")
struct AppUICanvasLoadTests {
    private static let count = 500

    private static func press(_ index: Int) -> AppUICanvas.Sample {
        let phase: AppUICanvas.Phase = index == 0 ? .began : (index == count - 1 ? .ended : .moved)
        return AppUICanvas.Sample(phase: phase, location: CGPoint(x: CGFloat(index), y: CGFloat(count - index)), timestamp: Double(index), device: .mouse)
    }

    @Test(.timeLimit(.minutes(1)))
    func `events yielded while the consumer is slow arrive whole and in order`() async {
        let canvas = AppUICanvasFixtures.canvas()
        let expected = (0 ..< Self.count).map(Self.press)
        // The consumer waits three turns of the run loop for every sample it takes; the producer gives it one turn for every ten it makes.
        let consumer = Task { @MainActor in
            var received: [AppUICanvas.Sample] = []
            var iterator = canvas.samples.makeAsyncIterator()
            while received.count < Self.count, let next = await iterator.next() {
                received.append(next)
                for _ in 0 ..< 3 {
                    await Task.yield()
                }
            }
            return received
        }
        for (index, sample) in expected.enumerated() {
            canvas.emit(sample, contact: AppUICanvas.Contact(location: sample.location, timestamp: sample.timestamp, device: .mouse))
            if index.isMultiple(of: 10) {
                await Task.yield()
            }
        }
        let received = await consumer.value
        #expect(received.count == Self.count)
        #expect(received == expected)
    }

    @Test(.timeLimit(.minutes(1)))
    func `one task for each event reorders them: the control that proves the check can fail`() async {
        // A task for each event is the design the canvas does not use. Here each task waits as many turns as events remain after it, which any
        // difference in how long a task suspends can do; the order in which they finish is not the order in which they were made.
        let (stream, continuation) = AsyncStream.makeStream(of: Int.self, bufferingPolicy: .unbounded)
        var tasks: [Task<Void, Never>] = []
        for index in 0 ..< 50 {
            tasks.append(Task { @MainActor in
                for _ in 0 ..< (50 - index) {
                    await Task.yield()
                }
                continuation.yield(index)
            })
        }
        for task in tasks {
            await task.value
        }
        continuation.finish()
        var received: [Int] = []
        for await index in stream {
            received.append(index)
        }
        #expect(received.count == 50, "nothing was lost, only the order")
        #expect(received != Array(0 ..< 50))
    }
}
