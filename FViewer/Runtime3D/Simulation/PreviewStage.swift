import Foundation
import simd

struct StageMover: Equatable, Codable {
    enum Motion: Int, Codable, CaseIterable {
        case still, strafe, forwardBack, circle, dash

        var title: String {
            switch self {
            case .still: return "Still"
            case .strafe: return "Strafe"
            case .forwardBack: return "Forward and Back"
            case .circle: return "Circle"
            case .dash: return "Dash"
            }
        }
    }

    var motion = Motion.still
    var amplitude: Float = 2
    var period: Float = 4
    var jump = false
    var jumpHeight: Float = 1
    var jumpPeriod: Float = 2

    func offset(at seconds: Float) -> Vec3 {
        let period = max(self.period, 0.1)
        let w = 2 * Float.pi * seconds / period
        var out = Vec3.zero
        switch motion {
        case .still: break
        case .strafe: out.x = amplitude * sin(w)
        case .forwardBack: out.z = amplitude * sin(w)
        case .circle: out = Vec3(amplitude * sin(w), 0, amplitude * (cos(w) - 1))
        case .dash:
            let n = Int(max(seconds, 0) / period)
            let into = max(seconds, 0) - Float(n) * period
            let to: Float = n % 2 == 1 ? amplitude : 0
            let from: Float = n == 0 ? 0 : amplitude - to
            out.x = from + (to - from) * smooth(into / min(0.25, period / 2))
        }
        if jump {
            let jumpPeriod = max(self.jumpPeriod, 0.2)
            let duration = min(0.7, jumpPeriod)
            let u = max(seconds, 0).truncatingRemainder(dividingBy: jumpPeriod) / duration
            if u < 1 { out.y = 4 * jumpHeight * u * (1 - u) }
        }
        return out
    }

    private func smooth(_ x: Float) -> Float {
        let t = min(max(x, 0), 1)
        return t * t * (3 - 2 * t)
    }
}

struct PreviewStage: Equatable, Codable {
    var showTarget = false
    var distance: Float = 6
    var side: Float = 0
    var faceEachOther = true
    var caster = StageMover()
    var target = StageMover()

    func places(at seconds: Float) -> (caster: Mat4, target: Mat4) {
        let c = caster.offset(at: seconds)
        let t = Vec3(side, 0, distance) + target.offset(at: seconds)
        var flat = t - c
        flat.y = 0
        let facing = faceEachOther && simd_length_squared(flat) > 1e-8
        let casterYaw = facing ? atan2(flat.x, flat.z) : 0
        let targetYaw = facing ? atan2(-flat.x, -flat.z) : .pi
        return (Math3D.compose(c, simd_quatf(angle: casterYaw, axis: Vec3(0, 1, 0)), Vec3(1, 1, 1)),
                Math3D.compose(t, simd_quatf(angle: targetYaw, axis: Vec3(0, 1, 0)), Vec3(1, 1, 1)))
    }
}
