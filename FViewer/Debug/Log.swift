import Foundation
import os

nonisolated struct LogChannel: Sendable {
    #if DEBUG
    private let logger: Logger
    #endif

    init(_ category: String) {
        #if DEBUG
        logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "FViewer", category: category)
        #endif
    }

    func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
        let text = message()
        logger.debug("\(text, privacy: .public)")
        #endif
    }

    func info(_ message: @autoclosure () -> String) {
        #if DEBUG
        let text = message()
        logger.info("\(text, privacy: .public)")
        #endif
    }

    func error(_ message: @autoclosure () -> String) {
        #if DEBUG
        let text = message()
        logger.error("\(text, privacy: .public)")
        #endif
    }
}

nonisolated enum Log {
    static let app = LogChannel("App")
    static let document = LogChannel("Document")
    static let undo = LogChannel("Undo")
    static let library = LogChannel("Library")
    static let textures = LogChannel("Textures")
    static let simulation = LogChannel("Simulation")
    static let game = LogChannel("Game")
    static let export = LogChannel("Export")

    static func milliseconds(since start: Double) -> String {
        String(format: "%.1f ms", (CFAbsoluteTimeGetCurrent() - start) * 1000)
    }
}
