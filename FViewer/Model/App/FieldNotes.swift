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
        "AvfxParticleTextureColor1.TLst": "The textures of this layer; TexN picks one of them. Game files keep the layer's texture here, not in Texture Index",
    ]

    static func text(_ key: String?) -> String? { key.flatMap { notes[$0] } }
}
