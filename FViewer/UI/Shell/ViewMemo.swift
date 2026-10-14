import Foundation

final class ViewMemo<Value> {
    private var entries: [String: Value] = [:]
    private var order: [String] = []
    private let limit: Int

    init(limit: Int = 16) {
        self.limit = limit
    }

    func value(_ key: String, _ make: () -> Value) -> Value {
        if let known = entries[key] { return known }
        let made = make()
        entries[key] = made
        order.append(key)
        while order.count > limit { entries[order.removeFirst()] = nil }
        return made
    }
}
