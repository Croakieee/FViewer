public protocol Parent: AnyObject {
    func matrixAt(_ time: Double) -> Affine3
}

final class Origin: Parent {
    func matrixAt(_ time: Double) -> Affine3 { .identity }
}

final class FrozenParent: Parent {
    private let matrix: Affine3
    init(_ parent: Parent, _ time: Double) { matrix = parent.matrixAt(time) }
    func matrixAt(_ time: Double) -> Affine3 { matrix }
}

final class TurnedParent: Parent {
    private let parent: Parent
    private let turn: Affine3
    init(_ parent: Parent, _ degrees: Vec3, _ order: RotationOrder) {
        self.parent = parent
        turn = .rotation(degrees, order)
    }
    func matrixAt(_ time: Double) -> Affine3 { parent.matrixAt(time).appending(turn) }
}

func attach(_ emitter: Parent, _ follow: Follow, _ time: Double, _ turn: Vec3?, _ order: RotationOrder) -> Parent {
    let parent: Parent = follow == .always ? emitter : FrozenParent(emitter, time)
    guard let turn, turn.x != 0 || turn.y != 0 || turn.z != 0 else { return parent }
    return TurnedParent(parent, turn, order)
}
