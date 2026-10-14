import Combine
import SwiftUI

final class HoverPoint: ObservableObject {
    @Published var location = CGPoint.zero
}

struct UvReadout: View {
    @ObservedObject var pointer: HoverPoint
    let convert: (CGPoint) -> SIMD2<Float>

    var body: some View {
        let cursor = convert(pointer.location)
        Text(String(format: "U %.3f  V %.3f", cursor.x, cursor.y)).font(Theme.small).foregroundStyle(Theme.dim)
            .padding(.leading, 8)
            .padding(.bottom, 4)
            .allowsHitTesting(false)
    }
}
