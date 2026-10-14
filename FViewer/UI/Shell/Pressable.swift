import SwiftUI

extension View {
    func pressable(perform action: @escaping () -> Void) -> some View {
        Button(action: action) { self }
            .buttonStyle(.plain)
    }
}
