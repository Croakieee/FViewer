import Foundation

enum FieldNotes {
    private static let notes: [String: String] = [
        "AvfxTimeline.LpSt": "The timeline loops from Loop Start to Loop End: at Loop End its time goes back to Loop Start, and items that start after Loop End never run. Loop End below Loop Start (60 and 0) means no loop. A Release (ULLP) or End clip lets the timeline go on past Loop End. Measured in the game",
        "AvfxTimeline.LpEd": "The timeline loops from Loop Start to Loop End: at Loop End its time goes back to Loop Start, and items that start after Loop End never run. Loop End below Loop Start (60 and 0) means no loop. A Release (ULLP) or End clip lets the timeline go on past Loop End. Measured in the game",
        "AvfxTimelineItem.Plfm": "Has no effect on PC: items with Platform 1 or 2 run like 0. Measured in the game",
        "AvfxTimelineItem.EdTm": "The emitter of this item lives the shorter of its own Life and End − Start. Measured in the game",
        "AvfxEmitterItem.bEnb": "The game creates the item even when this is off. Measured in the game",
        "AvfxEmitterItem.ICSK": "With Influence on Child 8 or 9 the particle lets go of a moving emitter little by little and stays in the world from the age Life ÷ this value. Measured in the game for 0.5 to 8",
        "AvfxEmitter.ClCn": "At most this many particles of this emitter live at once: dense rows with a long life are cut without a word. Measured in the game with 30",
        "AvfxParticle.LpSt": "A particle loop keeps the particle alive until the effect is released, its curves repeating the loop section; an item with Create Time 0 makes a new one every interval. Measured in the game",
        "AvfxParticle.LpEd": "A particle loop keeps the particle alive until the effect is released, its curves repeating the loop section; an item with Create Time 0 makes a new one every interval. Measured in the game",
        "AvfxTimelineItem.EfNo": "An item with an effector and no emitter runs the effector from Start to End (End −1: no end), at the binder's point with its own Position in world axes. Measured in the game",
        "AvfxMain.DLST": "Lit Model particles: 0 None — unlit, the effect's own Directional Light does nothing; 1 InLocal — the effect's own Directional Light; 2 InGame — the game's scene light (Preview → Game Light). Measured in the game",
        "AvfxBinder.Life": "A Point binder follows its object for this many frames, then stays; −1 always; 0 does not follow at all — the point stays where the effect spawned. Measured in the game",
        "AvfxBinderProperties.Pos": "On a Point binder on a character: moves the point in the character's axes (X left, Y up, Z forward), turning with the character; an animated curve plays. Measured in the game",
        "AvfxParticleDataModel.MdNo": "The model of the file the particle draws. A model with emit points only and no mesh is not drawn. Measured in the game",
        "AvfxParticleDataModel.MNRv": "At birth the particle picks one of the first Model Number Random + 1 models of the list, evenly (not past its end); 0 — the first. Measured in the game",
        "AvfxParticleDataPolyline.PnC": "Points in the chain, one per game frame: without Softness the trail is the path of the last Point Count − 1 game frames. More than 64 crashed the game. Measured in the game",
        "AvfxParticleDataPolyline.bLcl": "1: the trail's points are kept in the axes of the effect's root binder and move and turn with it; 0: in the world. Measured in the game",
        "AvfxParticleDataPolyline.Wd": "Half width in metres; Width Begin, Center and End multiply it at the head, at Point Count Center and at the tail. The particle's Scale changes neither the width nor the length. Measured in the game",
        "AvfxParticleDataPolyline.Len": "Position History: the trail is at most this many metres along the path from the head. Connect Target: metres per repeat of the texture along the line. Measured in the game",
        "AvfxParticleTextureColor1.TLst": "The textures of this layer; TexN picks one of them. Game files keep the layer's texture here, not in Texture Index",
    ]

    static func text(_ key: String?) -> String? { key.flatMap { notes[$0] } }
}
