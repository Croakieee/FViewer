import SwiftUI

enum FieldValue: Equatable {
    case int(Int)
    case double(Double)
    case bool(Bool)
    case text(String)

    var number: Double {
        switch self {
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
}

struct CurveGroup: Identifiable {
    let id: String
    let title: String
    let tag: String
    let isAngle: Bool
    var channels: [CurveChannel]
    var settings: [PropField]
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
}

struct TextureSlot: Identifiable {
    let id: String
    let name: String
    let path: String
    let nodeID: String?
}

enum Theme {
    static let window = Color(red: 0.114, green: 0.114, blue: 0.114)
    static let panel = Color(red: 0.188, green: 0.188, blue: 0.188)
    static let header = Color(red: 0.157, green: 0.157, blue: 0.157)
    static let field = Color(red: 0.33, green: 0.33, blue: 0.33)
    static let fieldDark = Color(red: 0.11, green: 0.11, blue: 0.11)
    static let line = Color(red: 0.09, green: 0.09, blue: 0.09)
    static let text = Color(red: 0.86, green: 0.86, blue: 0.86)
    static let dim = Color(red: 0.6, green: 0.6, blue: 0.6)
    static let accent = Color(red: 0.278, green: 0.447, blue: 0.702)
    static let selection = Color(red: 0.2, green: 0.31, blue: 0.47)
    static let playhead = Color(red: 0.31, green: 0.55, blue: 0.95)
    static let font = Font.system(size: 11)
    static let small = Font.system(size: 10)
}
