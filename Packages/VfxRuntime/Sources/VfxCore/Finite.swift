import Foundation

public extension Int {
    init<T: BinaryFloatingPoint>(finite value: T, in range: ClosedRange<Int> = -2_000_000_000...2_000_000_000) {
        guard value.isFinite else {
            self = Swift.min(Swift.max(0, range.lowerBound), range.upperBound)
            return
        }
        let bounded = Swift.min(Swift.max(Double(value), Double(range.lowerBound)), Double(range.upperBound))
        if bounded >= 9.2e18 { self = range.upperBound } else if bounded <= -9.2e18 { self = range.lowerBound } else { self = Swift.min(Swift.max(Int(bounded), range.lowerBound), range.upperBound) }
    }
}

public extension UInt8 {
    init<T: BinaryFloatingPoint>(finite value: T) { self = UInt8(Int(finite: value, in: 0...255)) }
}
