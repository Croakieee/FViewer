import SwiftUI
import simd

struct ModelEditorView: View {
    @EnvironmentObject var app: AppModel

    var body: some View {
        Group {
            if let document = app.document, let id = app.modelEditorTarget, case .avfx(let block, _, _)? = document.node(id)?.payload, block.tag == "Modl" {
                ModelEditorContent(document: document, session: ModelEditSession(document: document, nodeID: id, model: block), title: document.node(id)?.title ?? "Model")
                    .id(document.id.uuidString + id)
            } else {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 980, minHeight: 560)
        .background(Theme.panel)
        .preferredColorScheme(Theme.scheme)
    }
}

private struct ModelEditorContent: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    @StateObject var session: ModelEditSession
    let title: String
    @State private var spreadsheet = false
    @State private var sidebar = true
    @State private var pending: ModelCapture?

    private var name: String { title.replacingOccurrences(of: " ", with: "_") }

    var body: some View {
        let _ = document.revision
        VStack(spacing: 0) {
            EditorHeader(symbol: "cube", title: "Model Editor · " + title) {
                Text("\(session.vertexCount) vertices · \(session.triangleCount) triangles · \(session.emitCount) emit points")
                    .font(Theme.small).foregroundStyle(Theme.dim)
                Text(selectionText).font(Theme.small).foregroundStyle(Theme.text)
                Spacer()
                HeaderButton(symbol: "arrow.uturn.backward", help: "Undo") { document.undo() }
                HeaderButton(symbol: "arrow.uturn.forward", help: "Redo") { document.redo() }
                HeaderButton(symbol: "tablecells", active: spreadsheet, help: "Spreadsheet: every vertex, emit point and order entry as numbers") { spreadsheet.toggle() }
                HeaderButton(symbol: "sidebar.right", active: sidebar, help: "Sidebar") { sidebar.toggle() }
            }
            HStack(spacing: 0) {
                if spreadsheet {
                    ModelSpreadsheet(document: document, model: session.model).frame(minWidth: 420)
                } else {
                    ModelUvEditor(document: document, session: session).frame(minWidth: 300)
                }
                Rectangle().fill(Theme.line).frame(width: 1)
                ModelViewport3D(document: document, session: session).frame(minWidth: 320)
                if sidebar {
                    Rectangle().fill(Theme.line).frame(width: 1)
                    ScrollView {
                        VStack(spacing: 6) {
                            itemPanel
                            emitPanel
                            meshPanel
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(width: 250)
                }
            }
            HStack(spacing: 8) {
                Text(session.status.isEmpty ? "Click to select · G move · S scale · R rotate · A select all" : session.status)
                    .font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 10)
            .frame(height: 22)
            .background(Theme.header)
        }
        .onChange(of: document.revision) { _, _ in session.clampSelection() }
        .onAppear { ModelEditSession.active = session }
    }

    private var selectionText: String {
        var parts: [String] = []
        if !session.selection.isEmpty { parts.append("\(session.selection.count) selected") }
        if !session.emitSelection.isEmpty { parts.append("\(session.emitSelection.count) emit selected") }
        return parts.joined(separator: " · ")
    }

    private func row<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 6) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1).frame(width: 64, alignment: .trailing)
            content()
        }
    }

    private func axisField(_ label: String, _ value: Double, step: Double = 0.01, _ title: String, shift: @escaping (Double) -> Void) -> some View {
        NumberField(label: label, value: value, step: step, digits: 4,
                    onLive: { next in
                        shift(next - value)
                        document.liveDrag()
                    },
                    onCommit: { old, next in
                        let before = pending ?? session.capture()
                        pending = nil
                        session.restore(before)
                        shift(next - old)
                        session.commit(title, from: before)
                    })
    }

    @ViewBuilder private var itemPanel: some View {
        let picked = session.selection.sorted()
        if let center = vertexCenter(picked) {
            Panel(title: picked.count == 1 ? "Vertex \(picked[0])" : "Vertices", trailing: picked.count == 1 ? "" : "\(picked.count) · median") {
                VStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { axis in
                        row(axis == 0 ? "Position" : "") {
                            axisField(["X", "Y", "Z"][axis], Double(center[axis]), "Move Vertices") { delta in
                                var offset = SIMD3<Float>(0, 0, 0)
                                offset[axis] = Float(delta)
                                let all = session.positions
                                for index in picked where index < all.count { session.setPosition(index, all[index] + offset) }
                            }
                        }
                    }
                }
                if let uv = session.uvCenter {
                    VStack(spacing: 2) {
                        ForEach(0..<2, id: \.self) { axis in
                            row(axis == 0 ? "UV \(session.uvSet + 1)" : "") {
                                axisField(["U", "V"][axis], Double(uv[axis]), "Move UVs") { delta in
                                    var offset = SIMD2<Float>(0, 0)
                                    offset[axis] = Float(delta)
                                    session.translateUV(offset)
                                }
                            }
                        }
                    }
                }
                row("Color") {
                    ColorField(color: session.color(picked[0]), alpha: true,
                               onLive: { color in
                                   if pending == nil { pending = session.capture() }
                                   for index in picked { session.setColor(index, color) }
                                   document.liveDrag()
                               },
                               onCommit: { _, color in
                                   let before = pending ?? session.capture()
                                   pending = nil
                                   for index in picked { session.setColor(index, color) }
                                   session.commit("Vertex Color", from: before)
                               })
                }
                if picked.count == 1 {
                    let normal = session.normal(picked[0])
                    VStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { axis in
                            row(axis == 0 ? "Normal" : "") {
                                axisField(["X", "Y", "Z"][axis], Double(normal[axis]), "Vertex Normal") { delta in
                                    var next = session.normal(picked[0])
                                    next[axis] = min(max(next[axis] + Float(delta), -1), 1)
                                    session.setNormal(picked[0], next)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func vertexCenter(_ picked: [Int]) -> SIMD3<Float>? {
        let all = session.positions
        let points = picked.filter { $0 < all.count }.map { all[$0] }
        guard !points.isEmpty else { return nil }
        return points.reduce(SIMD3<Float>(0, 0, 0), +) / Float(points.count)
    }

    @ViewBuilder private var emitPanel: some View {
        let picked = session.emitSelection.sorted()
        let all = session.emitPositions
        let points = picked.filter { $0 < all.count }.map { all[$0] }
        if !points.isEmpty {
            let center = points.reduce(SIMD3<Float>(0, 0, 0), +) / Float(points.count)
            Panel(title: picked.count == 1 ? "Emit Point \(picked[0])" : "Emit Points", trailing: picked.count == 1 ? "" : "\(picked.count) · median") {
                VStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { axis in
                        row(axis == 0 ? "Position" : "") {
                            axisField(["X", "Y", "Z"][axis], Double(center[axis]), "Move Emit Points") { delta in
                                var offset = SIMD3<Float>(0, 0, 0)
                                offset[axis] = Float(delta)
                                let current = session.emitPositions
                                for index in picked where index < current.count { session.setEmitPosition(index, current[index] + offset) }
                            }
                        }
                    }
                }
                if picked.count == 1 {
                    let normal = session.emitNormal(picked[0])
                    VStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { axis in
                            row(axis == 0 ? "Normal" : "") {
                                axisField(["X", "Y", "Z"][axis], Double(normal[axis]), "Emit Point Normal") { delta in
                                    var next = session.emitNormal(picked[0])
                                    next[axis] += Float(delta)
                                    session.setEmitNormal(picked[0], next)
                                }
                            }
                        }
                    }
                }
                row("Color") {
                    ColorField(color: session.emitColor(picked[0]), alpha: true,
                               onLive: { color in
                                   if pending == nil { pending = session.capture() }
                                   for index in picked { session.setEmitColor(index, color) }
                                   document.liveDrag()
                               },
                               onCommit: { _, color in
                                   let before = pending ?? session.capture()
                                   pending = nil
                                   for index in picked { session.setEmitColor(index, color) }
                                   session.commit("Emit Point Color", from: before)
                               })
                }
                row("") {
                    SegmentButton(title: "Remove", active: false) { session.removeSelectedEmitPoints() }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var meshPanel: some View {
        Group {
            Panel(title: "Select") {
                FlowLayout(spacing: 4) {
                    SegmentButton(title: "All", active: false) { session.selectAll() }
                    SegmentButton(title: "None", active: false) { session.selectNone() }
                    SegmentButton(title: "Linked", active: false) { session.selectLinked() }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Panel(title: "Mesh") {
                FlowLayout(spacing: 4) {
                    SegmentButton(title: "Import glTF…", active: false) { app.importModel(session.model, emitPoints: false) }
                    SegmentButton(title: "Export glTF…", active: false) { app.exportModel(session.model, name: name) }
                    SegmentButton(title: "Add Quad", active: false) { session.addQuad() }
                    SegmentButton(title: "Duplicate", active: false) { session.duplicateSelection() }
                    SegmentButton(title: "Extrude", active: false) { session.extrudeSelection() }
                    SegmentButton(title: "Subdivide", active: false) { session.subdivideSelection() }
                    SegmentButton(title: "Fill Face", active: false) { session.fillFace() }
                    SegmentButton(title: "Merge", active: false) { session.mergeSelection() }
                    SegmentButton(title: "Delete Vertices", active: false) { session.deleteSelectedVertices() }
                    SegmentButton(title: "Delete Faces", active: false) { session.deleteSelectedFaces() }
                    SegmentButton(title: "Flip Winding", active: false) { session.flipWinding() }
                    SegmentButton(title: "Recompute Normals", active: false) { session.recomputeNormals() }
                    HelpBadge(text: "Add Quad puts a unit square at the origin. Duplicate copies the selected vertices with the faces between them. Extrude copies the selection and joins the copy to the original with side faces; move it afterwards with G. Subdivide splits every selected face in four. Fill Face builds a triangle from 3 selected vertices, or two from 4. Merge joins the selected vertices at their centre. Delete Faces keeps the vertices. Flip Winding reverses the facing of every triangle. Recompute Normals rebuilds vertex normals from the triangles around each vertex.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Panel(title: "Emit Points", trailing: "\(session.emitCount)") {
                FlowLayout(spacing: 4) {
                    SegmentButton(title: "Add at Origin", active: false) { session.addEmitPoints(fromSelection: false) }
                    SegmentButton(title: "From Selected Vertices", active: false) { session.addEmitPoints(fromSelection: true) }
                    SegmentButton(title: "Import glTF…", active: false) { app.importModel(session.model, emitPoints: true) }
                    HelpBadge(text: "Emit points are where an emitter of type Model creates its particles. From Selected Vertices puts one on each selected vertex, with that vertex's normal.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
