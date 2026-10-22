import Foundation

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

        var playerName: String {
            switch self {
            case .still: return "still"
            case .strafe: return "strafe"
            case .forwardBack: return "forward"
            case .circle: return "circle"
            case .dash: return "dash"
            }
        }
    }

    var motion = Motion.still
    var amplitude: Float = 2
    var period: Float = 4
    var jump = false
    var jumpHeight: Float = 1
    var jumpPeriod: Float = 2
}

struct PreviewStage: Equatable, Codable {
    var showTarget = false
    var distance: Float = 6
    var side: Float = 0
    var faceEachOther = true
    var caster = StageMover()
    var target = StageMover()
}

struct PreviewLook: Equatable, Codable {
    var toneMap = false
    var exposure: Float = 0
    var lightIntensity: Float = 4
}

struct PreviewCharacter: Equatable, Codable {
    var model = ""
    var pose = ""
    var poseFrame: Float = 0
    var posePlay = false
}

struct CharacterClip: Hashable {
    let name: String
    let frames: Int
}

struct CharacterModelEntry: Equatable {
    let name: String
    let file: URL
    let eid: URL?
}

enum PreviewSettings {
    static var look = PreviewLook()
    static var stage = PreviewStage()
    static var character = PreviewCharacter()
    static var modelsFolder: URL?
    static var models: [CharacterModelEntry] = []
    static var backgroundColor: SIMD3<Double>?
    static var token = 0

    static var activeModel: CharacterModelEntry? { models.first { $0.name == character.model } }
}
