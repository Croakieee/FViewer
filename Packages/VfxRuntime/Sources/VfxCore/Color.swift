import Foundation

public struct Rgb {
    public var r: Double
    public var g: Double
    public var b: Double
    public init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }
}

public enum ColorError: Error, CustomStringConvertible {
    case format(String)
    public var description: String {
        switch self {
        case .format(let s): return "colour \"\(s)\" is not '#rrggbb' or '#rgb'"
        }
    }
}

public func parseHex(_ color: String) throws -> Rgb {
    var hex = color.trimmingCharacters(in: .whitespaces)
    guard hex.hasPrefix("#") else { throw ColorError.format(color) }
    hex.removeFirst()
    if hex.count == 3 { hex = hex.map { "\($0)\($0)" }.joined() }
    guard hex.count == 6, let n = UInt32(hex, radix: 16) else { throw ColorError.format(color) }
    return Rgb(r: Double((n >> 16) & 255) / 255, g: Double((n >> 8) & 255) / 255, b: Double(n & 255) / 255)
}

