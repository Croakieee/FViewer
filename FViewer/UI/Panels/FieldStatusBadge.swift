import SwiftUI

struct FieldStatusBadge: View {
    let kind: FieldStatus.Kind
    @State private var shown = false

    var body: some View {
        Group {
            if let symbol = kind.symbol {
                Image(systemName: symbol).font(.system(size: 8, weight: .semibold))
            } else {
                Text("≈").font(.system(size: 11, weight: .semibold))
            }
        }
        .foregroundStyle(kind == .measured ? Color(red: 0.45, green: 0.78, blue: 0.5) : Theme.dim)
        .frame(width: 12, height: 14)
        .contentShape(Rectangle())
        .onTapGesture { shown.toggle() }
        .help(kind.title + "\n" + kind.text)
        .popover(isPresented: $shown, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                Text(kind.title).font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.text)
                Text(kind.text).font(Theme.small).foregroundStyle(Theme.dim).fixedSize(horizontal: false, vertical: true)
            }
            .padding(8)
            .frame(width: 220, alignment: .leading)
            .background(Theme.panel)
            .preferredColorScheme(Theme.scheme)
        }
    }
}
