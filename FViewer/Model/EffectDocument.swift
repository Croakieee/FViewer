import Combine
import SwiftUI

enum EffectFormat {
    case avfx
    case pixi
}

final class EffectDocument: ObservableObject, Identifiable {
    let id = UUID()
    @Published var url: URL
    let format: EffectFormat
    private(set) var avfxRoot: AvfxBlock?
    private(set) var jsonRoot: JSONNode?
    @Published private(set) var revision = 0
    @Published private(set) var outline: [OutlineNode] = []
    @Published var selectionID: String? {
        didSet { if selectionID != oldValue { activeCurveID = nil } }
    }
    @Published var activeCurveID: String?
    @Published var time: Double = 0
    @Published var isDirty = false
    let undoManager = UndoManager()
    let catalog = AvfxCatalog.shared
    private var index: [String: OutlineNode] = [:]

    init(url: URL) throws {
        self.url = url
        let data = try Data(contentsOf: url)
        if url.pathExtension.lowercased() == "avfx" {
            format = .avfx
            avfxRoot = try AvfxBlock.parseFile([UInt8](data))
        } else {
            format = .pixi
            let root = try JSONParser.parse(data)
            guard root["emitters"] != nil || root["particles"] != nil || root["timelines"] != nil else {
                throw AvfxError.malformed("Это не эффект: в JSON нет timelines, emitters и particles")
            }
            jsonRoot = root
        }
        rebuildOutline()
        selectionID = outline.first?.id
    }

    var title: String { url.lastPathComponent }

    func serializedData() -> Data {
        if let avfxRoot {
            avfxRoot.syncCumulativeLists()
            return Data(avfxRoot.serialized())
        }
        return Data((jsonRoot?.serialized() ?? "").utf8)
    }

    func save(to target: URL? = nil) throws {
        let destination = target ?? url
        try serializedData().write(to: destination, options: .atomic)
        url = destination
        isDirty = false
    }

    func node(_ id: String?) -> OutlineNode? {
        guard let id else { return nil }
        return index[id]
    }

    var selectedNode: OutlineNode? { node(selectionID) }

    func rebuildOutline() {
        if let avfxRoot {
            outline = buildAvfxOutline(avfxRoot)
        } else if let jsonRoot {
            outline = buildPixiOutline(jsonRoot)
        }
        index = [:]
        func visit(_ node: OutlineNode) {
            index[node.id] = node
            node.children.forEach(visit)
        }
        outline.forEach(visit)
    }

    func touch() {
        revision += 1
        isDirty = true
    }

    func perform(_ title: String, _ action: @escaping () -> Void, revert: @escaping () -> Void) {
        action()
        registerUndo(title, undo: revert, redo: action)
    }

    func registerUndo(_ title: String, undo: @escaping () -> Void, redo: @escaping () -> Void) {
        undoManager.registerUndo(withTarget: self) { document in
            undo()
            document.registerUndo(title, undo: redo, redo: undo)
        }
        undoManager.setActionName(title)
        rebuildOutline()
        touch()
    }

    func liveChanged() {
        revision += 1
    }

    func setLive(_ field: PropField, _ value: FieldValue) {
        field.write?(value)
        revision += 1
    }

    func commit(_ field: PropField, from old: FieldValue, to new: FieldValue) {
        guard let write = field.write, old != new else { return }
        perform(field.label, { write(new) }, revert: { write(old) })
    }

    func undo() {
        guard undoManager.canUndo else { return }
        undoManager.undo()
    }

    func redo() {
        guard undoManager.canRedo else { return }
        undoManager.redo()
    }

    func sections(for node: OutlineNode) -> [PropSection] {
        switch node.payload {
        case .group: return []
        case .avfx(let block, let cls, let record): return avfxSections(node, block, cls, record)
        case .json(let json): return pixiSections(node, json)
        }
    }

    func curveGroups(for node: OutlineNode) -> [CurveGroup] {
        switch node.payload {
        case .group: return []
        case .avfx(let block, let cls, let record): return record == nil ? avfxCurveGroups(node, block, cls) : []
        case .json(let json): return pixiCurveGroups(node, json)
        }
    }

    var sequencerRows: [SequencerRow] {
        if let avfxRoot { return avfxSequencerRows(avfxRoot) }
        if let jsonRoot { return pixiSequencerRows(jsonRoot) }
        return []
    }

    var duration: Double {
        max(30, (sequencerRows.map(\.end).max() ?? 30).rounded(.up))
    }

    var textureSlots: [TextureSlot] {
        if let avfxRoot {
            return avfxRoot.childrenNamed("Tex").enumerated().map { i, block in
                let path = block.stringValue
                return TextureSlot(id: "tex\(i)", name: (path as NSString).lastPathComponent, path: path, nodeID: "avfx/Tex/\(i)")
            }
        }
        var names: [String] = []
        func visit(_ node: JSONNode) {
            if let members = node.members {
                for member in members {
                    if member.key == "texture", let name = member.node.string, !names.contains(name) { names.append(name) }
                    visit(member.node)
                }
            }
            node.elements?.forEach(visit)
        }
        if let jsonRoot { visit(jsonRoot) }
        return names.map { TextureSlot(id: "tex-" + $0, name: $0, path: $0, nodeID: nil) }
    }

    var modelNames: [String] {
        var names: [String] = []
        func visit(_ node: JSONNode) {
            if let members = node.members {
                for member in members {
                    if member.key == "model", let name = member.node.string, !names.contains(name) { names.append(name) }
                    visit(member.node)
                }
            }
            node.elements?.forEach(visit)
        }
        if let jsonRoot { visit(jsonRoot) }
        return names
    }

    static let channelColors: [Color] = [
        Color(red: 0.93, green: 0.33, blue: 0.31), Color(red: 0.47, green: 0.80, blue: 0.33), Color(red: 0.31, green: 0.56, blue: 0.95),
        Color(red: 0.93, green: 0.72, blue: 0.27), Color(red: 0.72, green: 0.48, blue: 0.90), Color(red: 0.36, green: 0.82, blue: 0.82),
        Color(red: 0.92, green: 0.52, blue: 0.75), Color(red: 0.75, green: 0.75, blue: 0.75),
    ]
}
