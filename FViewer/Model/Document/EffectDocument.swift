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
    var avfxRoot: AvfxBlock?
    var jsonRoot: JSONNode?
    @Published var hidden: Set<VisibilityKey> = []
    @Published var isolateSelection = false
    @Published private(set) var revision = 0 { didSet { if !dragging { previewRevision = revision } } }
    @Published private(set) var previewRevision = 0
    var materialViewCache: (revision: Int, root: ObjectIdentifier?, values: [String: Any]) = (-1, nil, [:])
    private var dragging = false
    var isDragging: Bool { dragging }
    @Published var density: [String: [Float]] = [:]
    var densityRevision = -1
    var densityJob: DensityJob?
    @Published private(set) var outline: [OutlineNode] = []
    @Published var selectionID: String? {
        didSet {
            guard selectionID != oldValue else { return }
            activeCurveID = nil
            if soloPreview { applySolo() }
        }
    }
    @Published var soloPreview = false
    @Published private(set) var names: [String: String] = [:]

    @Published var gamePath = "" {
        didSet { if gamePath != oldValue, metaLoaded { saveMeta() } }
    }
    @Published var sourcePath = "" {
        didSet { if sourcePath != oldValue, metaLoaded { saveMeta() } }
    }
    private var metaLoaded = false

    private struct Meta: Codable {
        var names: [String: String] = [:]
        var gamePath: String = ""
        var sourcePath: String? = nil
    }

    private var metaURL: URL { url.deletingPathExtension().appendingPathExtension("fvmeta.json") }

    func loadNames() {
        if let data = try? Data(contentsOf: metaURL), let decoded = try? JSONDecoder().decode(Meta.self, from: data) {
            names = decoded.names
            savedNames = decoded.names
            gamePath = decoded.gamePath
            sourcePath = decoded.sourcePath ?? ""
        }
        metaLoaded = true
    }

    private var savedNames: [String: String] = [:]

    private(set) var metaError: String?

    func saveMeta() {
        do {
            if savedNames.isEmpty && gamePath.isEmpty && sourcePath.isEmpty {
                if FileManager.default.fileExists(atPath: metaURL.path) { try FileManager.default.removeItem(at: metaURL) }
            } else {
                try JSONEncoder().encode(Meta(names: savedNames, gamePath: gamePath, sourcePath: sourcePath.isEmpty ? nil : sourcePath)).write(to: metaURL, options: .atomic)
            }
            metaError = nil
        } catch {
            metaError = error.localizedDescription
        }
    }

    func assignNames(_ fresh: [String: String]) {
        for (id, name) in fresh where !name.isEmpty { names[id] = name }
        saveMeta()
        rebuildOutline()
    }

    func replaceNames(_ next: [String: String]) {
        guard next != names else { return }
        names = next
        saveMeta()
    }

    private func applyName(_ name: String, _ nodeID: String) {
        if name.isEmpty { names[nodeID] = nil } else { names[nodeID] = name }
        saveMeta()
        rebuildOutline()
        revision += 1
    }

    private func pushNameUndo(_ nodeID: String, from old: String, to new: String) {
        let grouped = !undoManager.isUndoing && !undoManager.isRedoing
        if undoManager.isUndoing {
            if !undoTitles.isEmpty { undoTitles.removeLast() }
            redoTitles.append("Rename")
        } else if undoManager.isRedoing {
            if !redoTitles.isEmpty { redoTitles.removeLast() }
            undoTitles.append("Rename")
        } else {
            if let clean = cleanDepth, undoTitles.count < clean { cleanDepth = nil }
            undoTitles.append("Rename")
            redoTitles = []
            trimUndoTitles()
        }
        isDirty = cleanDepth != undoTitles.count
        if grouped { undoManager.beginUndoGrouping() }
        undoManager.registerUndo(withTarget: self) { document in
            document.applyName(old, nodeID)
            document.pushNameUndo(nodeID, from: new, to: old)
        }
        undoManager.setActionName("Rename")
        if grouped { undoManager.endUndoGrouping() }
    }

    func setName(_ name: String, for nodeID: String) {
        let old = names[nodeID] ?? ""
        guard old != name else { return }
        applyName(name, nodeID)
        pushNameUndo(nodeID, from: old, to: name)
    }
    var savedEnd: Double?
    var savedIsolate = false
    @Published var activeCurveID: String?
    let clock = PlaybackClock()
    @Published var isDirty = false
    @Published var exportRequest: Set<String>?
    private(set) var roundTripExact: Bool?
    let undoManager: UndoManager = {
        let manager = UndoManager()
        manager.groupsByEvent = false
        manager.levelsOfUndo = EffectDocument.undoLimit
        return manager
    }()
    let catalog = AvfxCatalog.shared
    private var index: [String: OutlineNode] = [:]
    private var rowsCache: (revision: Int, rows: [SequencerRow])?

    init(url: URL) throws {
        self.url = url
        let data = try Data(contentsOf: url)
        if url.pathExtension.lowercased() == "avfx" {
            format = .avfx
            let root = try AvfxBlock.parseFile([UInt8](data))
            avfxRoot = root
            roundTripExact = Data(root.serialized()) == data
        } else {
            format = .pixi
            let root = try JSONParser.parse(data)
            guard root["emitters"] != nil || root["particles"] != nil || root["timelines"] != nil else {
                throw AvfxError.malformed("Not an effect: the JSON has no timelines, emitters or particles")
            }
            jsonRoot = root
        }
        loadNames()
        rebuildOutline()
        selectionID = outline.first?.id
        original = EffectDocument(shadowOf: self)
    }

    private init(shadowOf source: EffectDocument) {
        url = source.url
        format = source.format
        avfxRoot = source.avfxRoot?.deepCopy()
        jsonRoot = source.jsonRoot?.deepCopy()
        rebuildOutline()
    }

    private(set) var original: EffectDocument?
    @Published var showOriginal = false
    @Published var plane = SIMD3<Double>(0, 0, 0)
    @Published var paramOverrides: [String: Double] = [:]
    @Published private(set) var undoTitles: [String] = []
    @Published private(set) var redoTitles: [String] = []
    var originalFields: [String: [String: FieldValue]] = [:] { didSet { if originalFields.isEmpty { originalKeyCache = [:] } } }
    var originalKeyCache: [String: [CurveKeyPoint]?] = [:]
    var origins: [String: [Int]] = [:]
    var graphLayout: [String: CGPoint] = [:]

    func originalID(_ id: String) -> String? {
        let parts = id.split(separator: "/", maxSplits: 3, omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 3, parts[0] == "avfx", let index = Int(parts[2]), let list = origins[parts[1]] else { return id }
        guard index < list.count else { return nil }
        return (["avfx", parts[1], String(list[index])] + parts.dropFirst(3)).joined(separator: "/")
    }

    func dropOrigin(_ tag: String, at index: Int) {
        var list = origins[tag] ?? Array(0..<(original?.avfxRoot?.childrenNamed(tag).count ?? 0))
        if index < list.count { list.remove(at: index) }
        origins[tag] = list
        originalFields = [:]
    }
    private var changeCache: (revision: Int, set: ChangeSet)?

    var changes: ChangeSet {
        if let cached = changeCache, cached.revision == revision { return cached.set }
        let fresh = computeChanges()
        changeCache = (revision, fresh)
        return fresh
    }

    var title: String { url.lastPathComponent }

    func serializedData() -> Data {
        if let avfxRoot {
            avfxRoot.updateCounts()
            avfxRoot.syncCumulativeLists()
            return Data(avfxRoot.serialized())
        }
        return Data((jsonRoot?.serialized() ?? "").utf8)
    }

    static let editSuffix = "F"

    private static let ownedMark = "croakie.FViewer.edited"

    static func isOwned(_ url: URL) -> Bool { getxattr(url.path, ownedMark, nil, 0, 0, 0) >= 0 }

    static func markOwned(_ url: URL) {
        let value: [UInt8] = [1]
        setxattr(url.path, ownedMark, value, value.count, 0, 0)
    }

    var isEditedCopy: Bool { EffectDocument.isOwned(url) }

    var saveDestination: URL {
        if isEditedCopy { return url }
        let folder = url.deletingLastPathComponent(), ext = url.pathExtension
        var name = url.deletingPathExtension().lastPathComponent + EffectDocument.editSuffix
        var candidate = folder.appendingPathComponent(name).appendingPathExtension(ext)
        while FileManager.default.fileExists(atPath: candidate.path) {
            name += EffectDocument.editSuffix
            candidate = folder.appendingPathComponent(name).appendingPathExtension(ext)
        }
        return candidate
    }

    func save(to target: URL? = nil) throws {
        let destination = target ?? saveDestination
        if destination.standardizedFileURL == url.standardizedFileURL, !isEditedCopy {
            throw AvfxError.malformed("Original files are never overwritten. Choose another name")
        }
        try serializedData().write(to: destination, options: .atomic)
        EffectDocument.markOwned(destination)
        url = destination
        savedNames = names
        saveMeta()
        cleanDepth = undoTitles.count
        isDirty = false
    }

    func node(_ id: String?) -> OutlineNode? {
        guard let id else { return nil }
        return index[id]
    }

    var selectedNode: OutlineNode? { node(selectionID) }

    func nodeID(of block: AvfxBlock) -> String? {
        index.first { entry in
            if case .avfx(let held, _, let record) = entry.value.payload, record == nil { return held === block }
            return false
        }?.key
    }

    func visibilityKey(forNodeID id: String?) -> VisibilityKey? {
        guard var path = id else { return nil }
        while true {
            if let key = index[path]?.visibility ?? index[path]?.focus { return key }
            guard let slash = path.lastIndex(of: "/") else { return nil }
            path = String(path[..<slash])
        }
    }

    var visibilityFilter: VisibilityFilter {
        VisibilityFilter(hidden: hidden, isolated: isolateSelection ? visibilityKey(forNodeID: selectionID) : nil)
    }

    func toggleHidden(_ key: VisibilityKey) {
        if hidden.contains(key) { hidden.remove(key) } else { hidden.insert(key) }
    }

    func rebuildOutline() {
        if let avfxRoot {
            outline = buildAvfxOutline(avfxRoot)
        } else if let jsonRoot {
            outline = buildPixiOutline(jsonRoot)
        }
        index = [:]
        func visit(_ node: OutlineNode) {
            if let custom = names[node.id] {
                if node.detail.isEmpty { node.detail = node.title }
                node.title = custom
            }
            index[node.id] = node
            node.children.forEach(visit)
        }
        outline.forEach(visit)
    }

    private var cleanDepth: Int? = 0
    private var lastRedo: SnapshotBox?

    func touch() {
        revision += 1
        cleanDepth = nil
        isDirty = true
    }

    func amendLastUndo() {
        guard let lastRedo else { return }
        lastRedo.state = Snapshot(avfx: avfxRoot?.deepCopy(), json: jsonRoot?.deepCopy(), selection: selectionID, names: names, origins: origins, hidden: hidden)
        rebuildOutline()
        revision += 1
    }

    func perform(_ title: String, _ action: () -> Void, revert: () -> Void) {
        let before = snapshot()
        action()
        registerUndo(title, since: before)
    }

    private struct Snapshot {
        let avfx: AvfxBlock?
        let json: JSONNode?
        let selection: String?
        let names: [String: String]
        let origins: [String: [Int]]
        let hidden: Set<VisibilityKey>
    }

    private final class SnapshotBox {
        var state: Snapshot
        init(_ state: Snapshot) { self.state = state }
    }

    func snapshot() -> Any { Snapshot(avfx: avfxRoot?.deepCopy(), json: jsonRoot?.deepCopy(), selection: selectionID, names: names, origins: origins, hidden: hidden) }

    private func restore(_ state: Snapshot, other: Snapshot? = nil) {
        if let avfx = state.avfx { avfxRoot = avfx.deepCopy() }
        if let json = state.json { jsonRoot = json.deepCopy() }
        if origins != state.origins {
            origins = state.origins
            originalFields = [:]
        }
        if names != state.names {
            names = state.names
            saveMeta()
        }
        if let other, other.hidden != state.hidden, hidden != state.hidden { hidden = state.hidden }
    }

    func registerUndo(_ title: String, undo: () -> Void, redo: () -> Void) {
        undo()
        let before = Snapshot(avfx: avfxRoot?.deepCopy(), json: jsonRoot?.deepCopy(), selection: selectionID, names: names, origins: origins, hidden: hidden)
        redo()
        pushUndo(title, from: before, to: Snapshot(avfx: avfxRoot?.deepCopy(), json: jsonRoot?.deepCopy(), selection: selectionID, names: names, origins: origins, hidden: hidden))
    }

    func registerUndo(_ title: String, since before: Any) {
        guard let before = before as? Snapshot else { return }
        if before.names == names, EffectDocument.same(before.avfx, avfxRoot, { $0.sameContent(as: $1) }), EffectDocument.same(before.json, jsonRoot, { $0.sameContent(as: $1) }) { return }
        pushUndo(title, from: before, to: Snapshot(avfx: avfxRoot?.deepCopy(), json: jsonRoot?.deepCopy(), selection: selectionID, names: names, origins: origins, hidden: hidden))
    }

    private var undoSuspended = false

    @discardableResult func batch<T>(_ title: String, _ body: () throws -> T) rethrows -> T {
        if undoSuspended { return try body() }
        normalize()
        let before = snapshot()
        undoSuspended = true
        defer {
            undoSuspended = false
            normalize()
            registerUndo(title, since: before)
        }
        return try body()
    }

    private func normalize() {
        avfxRoot?.updateCounts()
        avfxRoot?.syncCumulativeLists()
    }

    private static func same<T>(_ a: T?, _ b: T?, _ equal: (T, T) -> Bool) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case let (x?, y?): return equal(x, y)
        default: return false
        }
    }

    static let undoLimit = 200

    private func trimUndoTitles() {
        while undoTitles.count > EffectDocument.undoLimit {
            undoTitles.removeFirst()
            cleanDepth = cleanDepth.flatMap { $0 > 0 ? $0 - 1 : nil }
        }
    }

    private func pushUndo(_ title: String, from: Snapshot, to: Snapshot) {
        if undoSuspended {
            rebuildOutline()
            liveDrag()
            return
        }
        let grouped = !undoManager.isUndoing && !undoManager.isRedoing
        if undoManager.isUndoing {
            if !undoTitles.isEmpty { undoTitles.removeLast() }
            redoTitles.append(title)
        } else if undoManager.isRedoing {
            if !redoTitles.isEmpty { redoTitles.removeLast() }
            undoTitles.append(title)
        } else {
            if let clean = cleanDepth, undoTitles.count < clean { cleanDepth = nil }
            undoTitles.append(title)
            redoTitles = []
            trimUndoTitles()
        }
        let box = SnapshotBox(to)
        lastRedo = grouped ? box : nil
        if grouped { undoManager.beginUndoGrouping() }
        undoManager.registerUndo(withTarget: self) { document in
            document.restore(from, other: box.state)
            document.pushUndo(title, from: box.state, to: from)
            if let selection = from.selection, document.node(selection) != nil { document.selectionID = selection }
        }
        undoManager.setActionName(title)
        Log.undo.debug("\(undoManager.isUndoing ? "Undid" : undoManager.isRedoing ? "Redid" : "Recorded") \(title) in \(self.title), \(undoTitles.count) steps")
        if grouped { undoManager.endUndoGrouping() }
        rebuildOutline()
        var path = selectionID
        while let current = path, node(current) == nil {
            path = current.lastIndex(of: "/").map { String(current[..<$0]) }
        }
        if path != selectionID { selectionID = path ?? outline.first?.id }
        revision += 1
        isDirty = cleanDepth != undoTitles.count
    }

    func liveChanged() {
        revision += 1
    }

    func liveDrag() {
        dragging = true
        revision += 1
        dragging = false
    }

    func setLive(_ field: PropField, _ value: FieldValue) {
        field.write?(value)
        liveDrag()
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

    func jumpHistory(to count: Int) {
        var guardCount = 0
        while undoTitles.count > count, undoManager.canUndo, guardCount < 2000 {
            guardCount += 1
            undoManager.undo()
        }
        while undoTitles.count < count, undoManager.canRedo, guardCount < 2000 {
            guardCount += 1
            undoManager.redo()
        }
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

    func missingCurves(for node: OutlineNode) -> [MissingCurve] {
        if case .avfx(let block, let cls, let record) = node.payload, record == nil { return avfxMissingCurves(node, block, cls) }
        return []
    }

    func missingFields(for node: OutlineNode) -> [MissingCurve] {
        if case .avfx(let block, let cls, let record) = node.payload, record == nil, block.children != nil { return avfxMissingFields(node, block, cls) }
        return []
    }

    var triggerCount: Int {
        if let root = avfxRoot { return root.child("Schd")?.ownRecords("Trgr").count ?? 0 }
        let numbers = (jsonRoot?["timelines"]?.elements ?? []).compactMap { $0["trigger"]?.number }
        return numbers.isEmpty ? 0 : Int(numbers.max() ?? 0) + 1
    }

    var sequencerRows: [SequencerRow] {
        if let cached = rowsCache, cached.revision == revision { return cached.rows }
        var rows: [SequencerRow] = []
        if let avfxRoot { rows = avfxSequencerRows(avfxRoot) } else if let jsonRoot { rows = pixiSequencerRows(jsonRoot) }
        rowsCache = (revision, rows)
        return rows
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

    static var channelColors: [Color] { PreviewRules.curveColors() ?? defaultChannelColors }

    static let defaultChannelColors: [Color] = [
        Color(red: 0.93, green: 0.33, blue: 0.31), Color(red: 0.47, green: 0.80, blue: 0.33), Color(red: 0.31, green: 0.56, blue: 0.95),
        Color(red: 0.93, green: 0.72, blue: 0.27), Color(red: 0.72, green: 0.48, blue: 0.90), Color(red: 0.36, green: 0.82, blue: 0.82),
        Color(red: 0.92, green: 0.52, blue: 0.75), Color(red: 0.75, green: 0.75, blue: 0.75),
    ]
}
