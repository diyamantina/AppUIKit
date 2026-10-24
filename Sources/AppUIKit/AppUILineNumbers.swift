import Foundation

/// Which line of a text a place is on, by search over the offsets where the lines start. A line ends at a line feed, a carriage return, or a carriage return
/// and a line feed together, as a text view ends a paragraph; the text after the last break is a line too, even when it is empty.
public struct AppUILineNumbers: Sendable, Equatable {
    /// The UTF-16 offset of the first character of each line, in order. It always begins with 0.
    public let starts: [Int]

    public init(text: String) {
        var starts = [0]
        var previousWasReturn = false
        var offset = 0
        for unit in text.utf16 {
            offset += 1
            switch unit {
            case 0x0A:
                // A line feed straight after a carriage return ends the same break.
                if previousWasReturn {
                    starts[starts.count - 1] = offset
                } else {
                    starts.append(offset)
                }
                previousWasReturn = false
            case 0x0D:
                starts.append(offset)
                previousWasReturn = true
            default:
                previousWasReturn = false
            }
        }
        self.starts = starts
    }

    /// How many lines there are: one more than the breaks.
    public var count: Int {
        starts.count
    }

    /// The number, counted from 1, of the line that holds the character at `offset`; an offset past the end is on the last line.
    public func line(at offset: Int) -> Int {
        var low = 0
        var high = starts.count
        while high - low > 1 {
            let middle = (low + high) / 2
            if starts[middle] <= offset {
                low = middle
            } else {
                high = middle
            }
        }
        return low + 1
    }

    /// Whether a line starts at `offset`.
    public func startsLine(at offset: Int) -> Bool {
        starts[line(at: offset) - 1] == offset
    }

    /// How many digits the largest line number has, which is how wide a column of them has to be.
    public var digits: Int {
        String(count).count
    }
}
