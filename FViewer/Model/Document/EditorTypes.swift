import SwiftUI

enum FieldValue: Equatable {
    case int(Int)
    case double(Double)
    case bool(Bool)
    case text(String)
    case color(Double, Double, Double, Double)

    var number: Double {
        switch self {
        case .color(let r, _, _, _): return r
        case .int(let v): return Double(v)
        case .double(let v): return v
        case .bool(let v): return v ? 1 : 0
        case .text(let v): return Double(v) ?? 0
        }
    }
}

enum FieldKind {
    case int
    case double
    case angle
    case bool
    case choice([FieldChoice])
    case text
    case info
    case color(alpha: Bool)
}

struct FieldChoice: Hashable {
    let name: String
    let value: Int
}

struct PropField: Identifiable {
    let id: String
    let label: String
    let tag: String
    let kind: FieldKind
    let read: () -> FieldValue
    let write: ((FieldValue) -> Void)?
    var animate: (() -> Void)?
    var unassign: (() -> Void)? = nil
    var triState = false
    var stat: String? = nil
}

struct PropSection: Identifiable {
    let id: String
    let title: String
    var fields: [PropField]
}

struct CurveChannel: Identifiable {
    let id: String
    let name: String
    let color: Color
    let read: () -> [CurveKeyPoint]
    let write: ([CurveKeyPoint]) -> Void
    let snapshot: () -> () -> Void
    var settings: [PropField] = []
    var extrapolation: () -> (pre: Int, post: Int) = { (0, 0) }
    var colorComponent: Int?
    var clampUnit = false
}

struct CurveGroup: Identifiable {
    let id: String
    let title: String
    let tag: String
    let isAngle: Bool
    var channels: [CurveChannel]
    var settings: [PropField]
    var remove: (() -> Void)?
    var missing: [MissingCurve] = []
    var unassign: [String: () -> Void] = [:]
    var stat: String? = nil
}

struct MissingCurve: Identifiable {
    let id: String
    let title: String
    let create: () -> Void
}

enum VisibilityKey: Hashable {
    case timeline(Int)
    case emitter(Int)
    case particle(Int)
}

struct VisibilityFilter: Equatable {
    var hidden: Set<VisibilityKey> = []
    var isolated: VisibilityKey?

    var isEmpty: Bool { hidden.isEmpty && isolated == nil }
}

struct NodeAction: Identifiable {
    let id: String
    let title: String
    let symbol: String
    var destructive = false
    let perform: () -> Void
}

enum NodeTint {
    case effect, scheduler, timeline, emitter, particle, effector, binder, texture, model, data, item, plain

    var color: Color {
        switch self {
        case .effect: return Color(red: 0.85, green: 0.85, blue: 0.85)
        case .scheduler: return Color(red: 0.62, green: 0.55, blue: 0.86)
        case .timeline: return Color(red: 0.93, green: 0.72, blue: 0.27)
        case .emitter: return Color(red: 0.36, green: 0.72, blue: 0.94)
        case .particle: return Color(red: 0.95, green: 0.50, blue: 0.30)
        case .effector: return Color(red: 0.93, green: 0.86, blue: 0.36)
        case .binder: return Color(red: 0.45, green: 0.82, blue: 0.55)
        case .texture: return Color(red: 0.86, green: 0.47, blue: 0.75)
        case .model: return Color(red: 0.42, green: 0.80, blue: 0.80)
        case .data: return Color(red: 0.62, green: 0.66, blue: 0.72)
        case .item: return Color(red: 0.72, green: 0.72, blue: 0.72)
        case .plain: return Color(red: 0.6, green: 0.6, blue: 0.6)
        }
    }
}

enum NodePayload {
    case group
    case avfx(block: AvfxBlock, cls: String?, record: [AvfxBlock]?)
    case json(JSONNode)
}

final class OutlineNode: Identifiable {
    let id: String
    var title: String
    var detail: String
    var symbol: String
    var tint: NodeTint
    var children: [OutlineNode] = []
    var payload: NodePayload
    var visibility: VisibilityKey?
    var focus: VisibilityKey?
    var actions: [NodeAction] = []

    init(id: String, title: String, detail: String = "", symbol: String, tint: NodeTint, payload: NodePayload) {
        self.id = id
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.tint = tint
        self.payload = payload
    }
}

struct SequencerRow: Identifiable {
    let id: String
    let label: String
    let start: Double
    let end: Double
    let openEnded: Bool
    let tint: NodeTint
    let depth: Int
    let nodeID: String?
    var base: Double = 0
    var startField: PropField?
    var endField: PropField?
    var enabledField: PropField?
    var densityKey = "*"
    var loop: (start: Double, end: Double)? = nil
    var clip: ClipSummary?
    var timeline: Int?
    var sources: [TimelineSource] = []
    var started = true
}

struct TextureSlot: Identifiable {
    let id: String
    let name: String
    let path: String
    let nodeID: String?
}

enum Theme {
    private static var lightCache: Bool?
    static var light: Bool {
        if let lightCache { return lightCache }
        let value = UserDefaults.standard.bool(forKey: "theme.light")
        lightCache = value
        return value
    }

    static func setLight(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: "theme.light")
        lightCache = on
    }
    static var scheme: ColorScheme { light ? .light : .dark }

    private static func pick(_ dark: Double, _ bright: Double) -> Color { Color(white: light ? bright : dark) }

    static func gray(_ value: Double) -> Color { Color(white: light ? min(1, max(0, 1 - value * 0.75)) : value) }

    static var window: Color { pick(0.114, 0.80) }
    static var panel: Color { pick(0.188, 0.93) }
    static var header: Color { pick(0.157, 0.88) }
    static var field: Color { pick(0.33, 0.76) }
    static var fieldDark: Color { pick(0.11, 1.0) }
    static var line: Color { pick(0.09, 0.66) }
    static var text: Color { pick(0.86, 0.10) }
    static var dim: Color { pick(0.6, 0.40) }
    static let accent = Color(red: 0.278, green: 0.447, blue: 0.702)
    static var selection: Color { light ? Color(red: 0.36, green: 0.52, blue: 0.80) : Color(red: 0.2, green: 0.31, blue: 0.47) }
    static let playhead = Color(red: 0.31, green: 0.55, blue: 0.95)
    static let font = Font.system(size: 11)
    static let small = Font.system(size: 10)
}
