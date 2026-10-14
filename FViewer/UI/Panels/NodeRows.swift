import SwiftUI

extension EffectDocument {
    func texturePath(of node: OutlineNode? = nil, fields: [PropField]) -> String? {
        let slots = textureSlots
        if let node, let slot = slots.first(where: { $0.nodeID == node.id }) { return slot.path }
        for field in fields {
            if field.tag == "TxNo" || field.tag.hasPrefix("TLst") || field.label.hasPrefix("Mask Texture"), case .int(let index) = field.read(), index >= 0, index < slots.count {
                return slots[index].path
            }
            if field.tag == "texture", case .text(let name) = field.read() { return name }
        }
        return nil
    }

    func curveChanged(_ group: CurveGroup, in id: String?) -> Bool {
        guard let id, changes.contains(id) else { return false }
        return group.channels.contains { channel in originalKeys(group: group.id, channel: channel.id, in: id) != channel.read() }
    }
}

struct NodeActionButton: View {
    let action: NodeAction

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: action.symbol).font(.system(size: 9))
            Text(action.title).font(Theme.font)
        }
        .foregroundStyle(action.destructive ? Color(red: 1, green: 0.5, blue: 0.45) : Theme.text)
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 8)
        .frame(height: 20)
        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.field.opacity(0.6)))
        .contentShape(Rectangle())
        .pressable(perform: action.perform)
    }
}

struct ChildNodeRow: View {
    @ObservedObject var document: EffectDocument
    let child: OutlineNode

    var body: some View {
        let changes = document.changes
        HStack(spacing: 6) {
            Image(systemName: child.symbol).font(.system(size: 10)).foregroundStyle(child.tint.color).frame(width: 16)
            Text(child.title).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1)
            if changes.contains(child.id) { ChangeDot(added: changes.added.contains(child.id)) }
            Spacer(minLength: 4)
            Text(child.detail).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
            Image(systemName: "chevron.right").font(.system(size: 7, weight: .bold)).foregroundStyle(Theme.dim)
        }
        .padding(.horizontal, 6)
        .frame(height: 20)
        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.field.opacity(0.45)))
        .contentShape(Rectangle())
        .pressable { document.selectionID = child.id }
        .contextMenu {
            ForEach(child.actions) { action in Button(action.title, role: action.destructive ? .destructive : nil, action: action.perform) }
        }
    }
}
