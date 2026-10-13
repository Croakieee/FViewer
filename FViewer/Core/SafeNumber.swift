import Foundation

extension Int {
    init<T: BinaryFloatingPoint>(safe value: T, in range: ClosedRange<Int> = -2_000_000_000...2_000_000_000) {
        guard value.isFinite else {
            self = Swift.min(Swift.max(0, range.lowerBound), range.upperBound)
            return
        }
        self = Int(Swift.min(Swift.max(Double(value), Double(range.lowerBound)), Double(range.upperBound)))
    }
}

extension UInt8 {
    init<T: BinaryFloatingPoint>(safe value: T) { self = UInt8(Int(safe: value, in: 0...255)) }
}

extension BinaryFloatingPoint {
    var finite: Self { isFinite ? self : 0 }

    func bounded(_ limit: Self) -> Self { isFinite ? Swift.min(Swift.max(self, -limit), limit) : 0 }
}
