import Foundation
import simd

struct SpriteInstance {
    var model: Mat4
    var color: Vec4
    var cell: Vec4
}

final class SpriteCloud {
    private struct Sprite {
        var age: Float = 0
        var position: Vec3
        var velocity: Vec3
        var fall = Vec3.zero
        var scaleX: Float
        var scaleY: Float
        var rotation: Float
        var cell: Int
        var world = false
    }

    private static var flatteryScale: Float { PreviewRules.isOn("spriteDamping") ? 12.5 : 0 }
    private static let lineWidth: Float = 0.012

    let anim: RSimple
    private let points: [EmitPoint]
    private let lines: Bool
    private var sprites: [Sprite] = []
    private var created = 0
    private var nextBurst: Float = 0

    init(anim: RSimple, points: [EmitPoint], lines: Bool) {
        self.anim = anim
        self.points = points
        self.lines = lines
    }

    private var capacity: Int { min(2048, max(1, anim.createCount)) }
    var finished: Bool { sprites.isEmpty }

    func step(_ frames: Float, alive: Bool, random: inout SeededRandom) {
        let a = anim
        for i in sprites.indices {
            sprites[i].age += frames
            sprites[i].fall += a.gravity * frames
            let keep = Vec3(
                pow(max(0, 1 - (1 - a.coordAccuracy.x) * SpriteCloud.flatteryScale), frames),
                pow(max(0, 1 - (1 - a.coordAccuracy.y) * SpriteCloud.flatteryScale), frames),
                pow(max(0, 1 - (1 - a.coordAccuracy.z) * SpriteCloud.flatteryScale), frames))
            sprites[i].velocity *= keep
            sprites[i].position += (sprites[i].velocity + sprites[i].fall) * frames
        }
        sprites.removeAll { $0.age >= a.life }
        guard alive else { return }
        nextBurst -= frames
        if a.createNewAfterDeath {
            let step = max(a.life / Float(max(1, a.createCount)), 0.01)
            while nextBurst <= 0 {
                if sprites.count < capacity {
                    sprites.append(spawn(&random))
                    created += 1
                }
                nextBurst += step
            }
            return
        }
        while nextBurst <= 0 {
            var i = 0
            while i < a.intervalCount && created < a.createCount && sprites.count < capacity {
                sprites.append(spawn(&random))
                created += 1
                i += 1
            }
            nextBurst += Float(max(1, a.interval + Int(random.next() * Float(a.intervalRandom + 1))))
        }
    }

    private func spawn(_ random: inout SeededRandom) -> Sprite {
        let a = anim
        let point: EmitPoint? = a.injectionPosition == 1 && !points.isEmpty ? points[min(points.count - 1, Int(random.next() * Float(points.count)))] : nil
        var direction = point?.normal ?? Vec3(random.range(-1, 1), random.range(-1, 1), random.range(-1, 1))
        if simd_length_squared(direction) < 1e-6 { direction = Vec3(0, 1, 0) }
        direction = simd_normalize(direction)
        let kx = random.range(min(a.scaleRandomX.x, a.scaleRandomX.y), max(a.scaleRandomX.x, a.scaleRandomX.y))
        let ky = a.scaleRandomLink ? kx : random.range(min(a.scaleRandomY.x, a.scaleRandomY.y), max(a.scaleRandomY.x, a.scaleRandomY.y))
        let cells = a.uvCellsU * a.uvCellsV
        let position = point?.position ?? Vec3(random.range(-1, 1) * a.createArea.x, random.range(-1, 1) * a.createArea.y, random.range(-1, 1) * a.createArea.z)
        let speed = a.velocityMin > a.velocityMax ? a.velocityMax : random.range(a.velocityMin, a.velocityMax)
        let block = Float(Int(random.next() * Float(a.blockCount))) * 2 * .pi / Float(a.blockCount)
        let rotation = a.rotStart + random.range(-1, 1) * a.rotRandom + block
        let cell = cells > 1 && a.uvRandom > 0 ? Int(random.next() * Float(min(a.uvRandom, cells))) : 0
        return Sprite(position: position, velocity: direction * speed, scaleX: kx, scaleY: ky, rotation: rotation, cell: cell)
    }

    private func color(at age: Float) -> Vec4 {
        let colors = anim.colors, frames = anim.frames
        guard !colors.isEmpty else { return Vec4(1, 1, 1, 1) }
        var i = 0
        while i < frames.count - 1 && age > frames[i + 1] { i += 1 }
        let c0 = colors[min(i, colors.count - 1)], c1 = colors[min(i + 1, colors.count - 1)]
        let f0 = i < frames.count ? frames[i] : 0
        let f1 = i + 1 < frames.count ? frames[i + 1] : f0
        let k = f1 > f0 ? min(1, max(0, (age - f0) / (f1 - f0))) : 0
        return c0 + (c1 - c0) * k
    }

    func render(frame: Mat4, cameraRotation: simd_quatf, cameraPosition: Vec3, particleScale: Vec3, pixelAngle: Float, lineLength: Float,
                revisedScale: Vec3) -> [SpriteInstance] {
        let a = anim
        let cells = a.uvCellsU * a.uvCellsV
        var out: [SpriteInstance] = []
        out.reserveCapacity(sprites.count)
        for i in sprites.indices {
            let k = min(1, sprites[i].age / a.life)
            let e = pow(k, a.scaleCurve > 0 ? a.scaleCurve : 1)
            if !a.bindParent && !sprites[i].world {
                sprites[i].position = Math3D.point(frame, sprites[i].position)
                sprites[i].velocity = Math3D.vector(frame, sprites[i].velocity)
                sprites[i].world = true
            }
            let s = sprites[i]
            var position = s.world ? s.position : Math3D.point(frame, s.position)
            var w = (a.scaleStart.x + (a.scaleEnd.x - a.scaleStart.x) * e) * s.scaleX * (a.scaleByParent ? particleScale.x : revisedScale.x)
            var h = (a.scaleStart.y + (a.scaleEnd.y - a.scaleStart.y) * e) * s.scaleY * (a.scaleByParent ? particleScale.y : revisedScale.y)
            var rotation = cameraRotation * simd_quatf(angle: s.rotation + a.rotVelocity * s.age, axis: Vec3(0, 0, 1))
            if lines {
                h = a.lineLength.x * lineLength
                w = pixelAngle > 0 ? pixelAngle * simd_distance(position, cameraPosition) : SpriteCloud.lineWidth
                let velocity = s.world ? s.velocity : Math3D.vector(frame, s.velocity)
                if simd_length_squared(velocity) > 1e-12 {
                    let axisY = simd_normalize(velocity)
                    let side = simd_cross(cameraPosition - position, axisY)
                    if simd_length_squared(side) > 1e-12 {
                        let axisX = simd_normalize(side)
                        rotation = Math3D.quaternion(x: axisX, y: axisY, z: simd_cross(axisX, axisY))
                    }
                }
            }
            let pivot = rotation.act(Vec3(a.pivot.x * w / 2, a.pivot.y * h / 2, 0))
            position += pivot
            let cell = cells > 1 ? (s.cell + (a.uvInterval > 0 ? Int(s.age / Float(a.uvInterval)) : 0)) % cells : 0
            let cu = 1 / Float(a.uvCellsU), cv = 1 / Float(a.uvCellsV)
            out.append(SpriteInstance(model: Math3D.compose(position, rotation, Vec3(w, h, 1)), color: color(at: s.age),
                                      cell: Vec4(Float(cell % a.uvCellsU) * cu, Float(cell / a.uvCellsU) * cv, cu, cv)))
        }
        return out
    }
}
