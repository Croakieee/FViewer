import SwiftUI

enum PreviewRules {
    static let all: [(key: String, title: String, help: String)] = [
        ("softParticles", "Soft particles", "Particles with Soft Particle fade out near the floor."),
        ("screenCopy", "Screen copy", "Layers with Use Screen Copy show the scene behind the particle."),
        ("distortion", "Texture distortion", "The Distortion layer shifts the UV of the layers it targets."),
        ("lights", "Effector lights", "Point light effectors light the floor and the models."),
        ("trails", "Polyline trails", "Polyline particles are drawn as trails."),
        ("coneEmitters", "Cone emitters", "Cone and Cone Model emitters throw particles inside their angle."),
        ("cameraBinder", "Camera binder", "Binders of type Camera pin the effect in front of the camera."),
        ("spriteDamping", "Sprite damping", "Simple Animation sprites slow down by Coord Accuracy."),
        ("uvRotationReversed", "Reversed UV rotation", "UV Set rotation turns the opposite way to its sign."),
        ("paletteAlpha", "Palette alpha", "The Palette layer scales alpha by the first colour layer."),
        ("revisedColor", "Revised colour", "The effect header colour multiplies every particle."),
        ("polygonAsQuad", "Polygon as quad", "Polygon particles are drawn as a quad with the whole texture."),
        ("axisConnectRandom", "Separate random axis link", "Random offsets of X, Y and Z follow their own Axis Connect Random setting."),
        ("tc1Luminance", "First layer as luminance", "A first colour layer with Multiply is read as brightness, not as colour."),
        ("softDepthOffset", "Soft fade after depth offset", "The soft particle fade is measured from the depth the particle is drawn at."),
        ("directionalLights", "Directional lights", "Directional light effectors light the floor and the models from their direction."),
        ("modelSkin", "Model Skin on the loaded model", "Model Skin particles are drawn over the model loaded with File → Game → Load Model."),
        ("dissolve", "Dissolve on the loaded model", "A Dissolve particle cuts the model loaded with File → Game → Load Model where the red of its first texture is below Erosion, and the edge glows in the particle colour. Derived from the field names, not checked in the game."),
        ("textureFilter", "Texture filter level", "Texture Filter set to High and above samples the texture with anisotropic filtering."),
        ("uvRotationRandom", "Random UV rotation", "UV Set Rotation Random turns each particle's texture by its own amount."),
        ("rotationVelocityRandom", "Random rotation velocity", "Rotation Velocity Random gives each particle its own spin."),
        ("clipDistance", "Clip by distance", "Enable Clip Near and Enable Clip Far fade the whole particle by its centre's distance d to the camera: s = (End − d) / (End − Start) from 0 to 1, Near keeps 1 − s^1.5 and Far s^1.5. With the Caster base point the game does not fade it."),
        ("coordComputeOrder", "Coordinate compute order", "Emitters and particles combine scale, rotation and position in the order their Coord Compute Order names."),
        ("emitterCameraBillboard", "Emitter camera billboard", "Emitters with Camera Billboard Axis Y turn to face the camera around the vertical axis."),
        ("heldOnce", "Held particles once", "A particle held in its loop section is created once per emitter."),
        ("injectionAnglePerCreation", "Injection angle continues", "The injection angle keeps counting across creations instead of restarting each time."),
        ("childLimit", "Child limit", "An emitter keeps no more live particles than its Child Limit."),
        ("cylinderPointFrame", "Cylinder point frame", "Cylinder Model emitters turn each child to face along the outward normal of its point."),
        ("gravityRandom", "Random gravity", "Gravity Random gives each particle its own gravity."),
        ("treeBillboardFixed", "Tree billboard quads", "Quads with Tree Billboard keep their own rotation fixed."),
        ("moveDirectionStreaks", "Move direction streaks", "Move Direction Billboard particles stretch along their motion on screen."),
        ("plainUv", "Plain UV for windmill and powder", "Windmill and plain Powder particles use only the first texture layer without UV motion."),
        ("periodicCurves", "Adding curves ignore the loop", "Curves that keep adding after their last key run on the total age while the particle is held in its loop."),
        ("addAlphaOnly", "Add of alpha-only texture", "An Add layer with an alpha-only texture leaves the colour as it is."),
        ("calcColorFive", "Calculate Color 5", "A layer with Calculate Color 5 leaves the colour as it is."),
        ("modelFresnel", "Model fresnel colours", "Models with a Fresnel Type blend Color Begin and Color End by the view angle."),
        ("lineGradient", "Line colour along length", "Line particles blend Color Begin and Color End along their length."),
        ("cullingWinding", "Culling by D3D winding", "Front and Back culling follow the game's clockwise front faces."),
        ("postEffects", "Screen effectors", "Radial, directional and Gaussian blur and chromatic aberration effectors change the whole picture."),
        ("cameraQuake", "Camera quake", "Camera Quake moves the view as measured in the game: Position is a shift in metres along the camera's axes (X right, Y up, Z back), Rotation a turn in radians (X tilts up, Y turns left, Z rolls); the random part stays the same for the whole effector. Within Radius In of the effector's emitter the shake is full, farther out it falls to ((Radius Out − Radius In − d) / (Radius Out − Radius In)) ^ Attenuation."),
        ("emitterMarkers", "Emitter shapes", "The selected emitter shows its shape and its create points."),
        ("bindPointNumbers", "Bind point numbers", "Bind points of the loaded skeleton show their numbers."),
        ("loopEffectors", "Effector loop", "Effectors repeat between Loop Start and Loop End until the effect is released."),
        ("distortionHalfRange", "Distortion half range", "Texture Distortion shifts the UV by (red, green − 0.5) × Power, as the game's particle shader does."),
        ("paletteChannels", "Palette on every channel", "The Palette layer recolours each channel of the first colour layer and replaces it before the other layers, as the game's particle shader does."),
        ("softQuadratic", "Quadratic soft fade", "Soft particles fade by the square of their distance to the scene, as the game's particle shader does."),
        ("a8BlackRgb", "Alpha-only textures are black", "Textures that store only alpha are read with black colour, as the game samples them."),
        ("textureLessTc1White", "White base without a first layer", "A first colour layer that is off or has no texture is a white base the other layers combine onto."),
        ("tc1OffNoAlpha", "First layer off brings no alpha", "With the first colour layer switched off and another layer on, only the other layers bring alpha."),
        ("tc1MultiplyWhite", "First layer Multiply keeps the colour", "A first colour layer with Multiply leaves the particle colour as it is and gives only its alpha. Works with First layer as luminance."),
        ("blendBeforeClamp", "Blend before clamping", "Blend and Opacity particles are weighted by alpha before bright colour is clamped, so colours above 1 keep their hue."),
        ("depthOffsetCentre", "Depth offset from the particle centre", "Depth Offset pulls the whole particle towards the camera by min(Depth Offset, 1) × its centre's distance to the camera, never past the camera. A negative Depth Offset pushes models back the same way but does nothing on Simple Animation sprites (measured)."),
        ("decalNoMipmaps", "Decals without mipmaps", "Decal and Decal Ring textures are read at full size."),
        ("createIntervalWholeFrame", "Create interval at least a frame", "A Create Interval below one frame counts as one frame: an item creates at most once per frame."),
        ("createOnceOwnCount", "Create once ignores emitter count", "An item created once at the emitter start makes its own Create Count; the emitter's Create Count does not multiply it."),
        ("trailWholePath", "Trails keep the whole path", "A Position History trail of a particle with a finite life keeps its whole path since birth."),
        ("polylineAxisFromBase", "Polyline line along the rotation base", "An Axis Order line runs along the particle's Rotation Direction Base axis (X, Y or Z)."),
        ("polylineWidthRevised", "Polyline width by revised scale", "Polyline ribbon width is multiplied by the mean of the effect's Revised Scale X and Y."),
        ("emitterPeriodicCurves", "Emitter adding curves ignore the loop", "Emitter curves that keep adding after their last key run on the emitter's total age while it is held in its loop."),
        ("moveDirectionRotation", "Move direction keeps rotation", "Move Direction Billboard particles lie with Z along their motion and Y away from the camera, and their own Rotation turns them on top."),
        ("auraTarget", "Aura target", "Model Skin particles are drawn only when their Aura Target includes the loaded model: Weapon or Off Hand for weapon models, Character or Summon for the others."),
        ("binderOffset", "Binder offset", "The Position of a binder's start properties moves the bind point in its own space: X to the side, Y up, Z forward. Camera binders are not moved. Inferred from game files."),
        ("polylineShape", "Polyline fixed ribbon", "Polylines with No Billboard spread the ribbon along the particle's current Not Billboard Base Axis instead of facing the camera. Is Spline changes nothing, as measured in the game."),
        ("stepKeyOnArrival", "Step keys jump on arrival", "A Step key holds the previous value up to its own frame and jumps there; the segment after it follows the next key's type."),
        ("randomAlwaysPerFrame", "Always random each frame", "Random curves of type Always draw a new random value every frame instead of once per particle."),
        ("lifeRandomType", "Life random by type", "Life Random adds, takes off or spreads both ways by its Random Type (Plus, Minus, Plus Minus)."),
        ("createTimeLast", "Create Time last tick", "An item with Create Time 2 creates once, at the last Create Interval tick of the emitter's finite life, with its own Create Count."),
        ("emitterRandomOnce", "Emitter random once", "The random parts of an emitter's Position, Rotation and Scale are drawn once per emitter, not for every particle."),
        ("emitterShapeRandom", "Emitter shape random", "Angle, Radius, Inner Size and Outer Size Random of the emitter shape spread every spawn by their curve's Random Type."),
        ("shapeAngles", "Shape angles", "Angle X, Y and Z of the emitter data turn Cone Model, Sphere Model, Cylinder Model and Model shapes in the data Rotation Order."),
        ("ringStartZ", "Rings start at +Z", "Sphere Model and Cylinder Model rings start at +Z and run towards +X."),
        ("coneModelRings", "Cone Model rings", "Cone Model emitters place Divide Y rings up to the Injection Angle from +Z, Divide X points each, at Radius; On Vertex methods start on the point, To Vertex methods at the centre."),
        ("coneSizes", "Cone inner and outer size", "Cone emitters start each particle along its direction between Inner Size and Outer Size."),
        ("modelToVertexFromCentre", "Model To Vertex from the centre", "Model emitters with a To Vertex method start particles at the emitter's origin and throw them along the vertex normal."),
        ("emitterInjectionAngle", "Emitter injection angle", "With Any Direction on, Injection Angle X, Y and Z (with their Random) turn each child about its shape point."),
        ("emitterVelocityAngle", "Emitter velocity random as angle", "With Any Direction off, Velocity Random X, Y and Z turn each child about the emitter's axes by that angle."),
        ("emitterMotionRandom", "Emitter motion random", "Gravity Random and Air Resistance Random of a thrown child emitter are drawn per emitter by the curve's Random Type."),
        ("influenceUnknownFollows", "Influence 8 and 9 follow", "Items with Parent Influence Coord 8 or 9 follow the emitter like All Always."),
        ("inheritParentLife", "Inherit parent life", "Items with Inherit Parent Life live only for the rest of the emitter's life."),
        ("inheritParentVelocity", "Inherit parent velocity", "Items with Inherit Parent Velocity start with the velocity of the thrown emitter that made them."),
        ("localDirectionFollowsNormal", "Local direction follows normal", "Particles of an item with Local Direction 1 turn local +Z along the normal of their shape point."),
        ("localDirectionChildEmitters", "Local direction for child emitters", "Child emitters of an item with Local Direction 1 turn local +Z along the normal of their shape point."),
        ("parameterLink", "Parameter link", "Parameter Link lays the linked particle's Position, Rotation and Scale over the particle as a parent, and its colour multiplies the particle's."),
        ("itemStartFrame", "Item start frame", "A particle item with Start Frame starts that many frames into its life; its curves and its life count from there."),
        ("startFrameNullUpdate", "Start frame null update", "Measured in the game: without Start Frame Null Update (bStN) the first Start Frame frames are skipped, not flown through; with it the particle starts from frame 0 as if there were no Start Frame. Off: the old reading (without bStN the particle moves through those frames, with it they are skipped)."),
        ("rotationVelocityTurnsFlight", "Rotation velocity turns flight", "Particle Rotation Velocity is an angle that turns the launch direction about its flight frame, in the named Rotation Order."),
        ("localFlightUnscaled", "Emitter-space flight unscaled", "A flight kept in emitter space is turned with the emitter but scaled only by the effect's Revised Scale, not the emitter's scale."),
        ("inheritBinderRotation", "Influence on binder rotation", "With Options items without Influence on Rotation take the binder's rotation when Influence on Binder Position is on."),
        ("moveDirectionAxisZ", "Move direction along Z", "Particles with Rotation Base Move Direction turn local +Z along their motion, their own rotation on top."),
        ("modelTreeBillboardOwnAxis", "Model tree billboard own axis", "Models with Tree Billboard turn about their own +Y to face the camera."),
        ("collisionFreeze", "Collision freeze", "Particles with Collision Type 2 stop where they reach the floor."),
        ("angleFade", "Camera angle fade", "Header Fade X and Y fade the effect by the camera's vertical and horizontal angle between Fade Inner and Fade Outer."),
        ("drawLayerOverScene", "Draw layer over scene", "Effects with Draw Layer Screen, Post UI or Prev UI draw over the scene without depth test."),
        ("addBeforeClamp", "Add before clamping", "Add particles are weighted by alpha before bright colour is clamped, so colours above 1 stay saturated."),
        ("simpleClockRate", "Sprite clock 1.2", "Simple Animation sprite age, life, births and atlas run 1.2 times faster than effect frames; their motion does not."),
        ("simpleLifeInfinite", "Sprite endless life", "Sprites with Life −1 live as long as their particle."),
        ("simpleLifeRandom", "Sprite random life", "Each sprite lives Create Interval Life plus a random 0 to Create Life Random frames. Create Life Random is a whole number in the file; its values are always below the life. Inferred from game files."),
        ("simpleSpinRandom", "Sprite spin random", "Each sprite turns at Rotation Add Z plus a random part of Rotation Velocity Z."),
        ("simpleCreateAreaFullSize", "Sprite area full size", "Create Area X, Y and Z are the full size of the spawn box."),
        ("simpleDirectionUp", "Sprite direction up", "Sprites with Injection Direction Type 1 or 3 fly up, between the angles Injection Radial Direction 0 and 1 from +Y."),
        ("simpleBindModelPath", "Sprite bind model path", "Sprites born on a vertex travel to the same vertex of the Bind Model, along Velocity Flattery Rate and Speed."),
        ("simpleAreaOnVertices", "Sprite area on vertices", "Create Area also scatters sprites born on model vertices."),
        ("pixelPositionUv", "UV by pixel position", "A UV Set with Calculate UV By Pixel Position maps its layers by the pixel's place on the screen instead of the particle's own UV. From the field name, not checked in the game."),
        ("polylineWidthRandom", "Polyline width random", "Width Random, Width Begin, Center and End Random give each polyline its own width by the curve's Random Type."),
        ("emitterSounds", "Emitter sounds", "While the effect plays, every emitter with a Sound plays it when it starts: the .scd is read from the game folder or from the library (sound/… next to vfx/…). Looping sounds play until the emitter ends."),
        ("randomTypeOnRandom", "Random type of the random curve", "A random part (XR, Gravity Random, Create Interval Random…) is spread by the Random Type stored on that random curve. Across all 44 257 game effects the type is set there, while the base curve keeps 0."),
        ("colorRandom", "Colour random", "Random R, G, B and A of a colour add their own random part to each channel, by their Random Type; Random Brightness uses its own type too."),
        ("modelMorph", "Model morph", "A Model particle with Is Morph blends its Model Index list by Morph: 0 is the first model, 1 the second and so on. In the game files every morph list holds models with the same vertex count."),
        ("modelNumberRandom", "Model number random", "A Model particle with Model Number Random picks one model of its Model Index list for each particle; with an Always random type and an interval it picks again every interval frames."),
        ("drawOrder", "Draw order", "Header Draw Order Reverse draws the newest particles first; Depth draws far particles before near ones inside each draw priority."),
        ("effectOwnClip", "Effect clip distance", "With Clip Own Setting the whole effect fades in between Near Clip Begin and End and out between Far Clip Begin and End, by the distance from the camera."),
        ("binderRotationType", "Binder rotation type", "Binder Rotation Type Billboard turns the bound effect with the camera, Billboard Axis Y and Camera Billboard Axis Y turn it about Y towards the camera, Look At Camera points its +Z at the camera."),
        ("previousFrameCopy", "Previous frame copy", "Layers with Previous Frame Copy show the picture behind the particle, as Use Screen Copy does (the current frame stands in for the previous one)."),
        ("effectorFadeBase", "Effector fade base point", "Screen effectors with Fade Base Point Caster fade by their distance from the caster instead of the camera."),
        ("radialBlurRadiusMask", "Radial blur as the game", "Radial Blur averages 24 points from the pixel towards the centre over Length, and mixes by Strength inside the game's Inner / Outer Radius mask (radii / 2 in screen UV)."),
        ("radialBlurGradation", "Radial blur gradation", "Radial Blur Gradation softens the mask edge: G = 0.5 / Gradation (kept at 1 with an Inner Radius)."),
        ("effectorEndsWithEmitter", "Effector ends with its emitter", "A screen effector or light stops when the emitter that owns it ends."),
        ("distortionKeepsFootprint", "Distortion keeps texture detail", "Distorted layers pick their mip level from the undistorted UV, so a fast-changing distortion map does not blur the texture to its average."),
        ("polylineChain", "Polyline trail chain", "A Position History trail is a chain of Point Count points: every half frame point i moves 1 − Softness × i / (Point Count − 1) of the way to where point i − 1 was. Softness 0 is a plain history, 1 keeps the tail at the birth point."),
        ("polylineConnectTarget", "Polyline connect target", "An Axis Order polyline with Connect Target runs straight from the particle to the target (with Reverse to the caster), or to the goal / start of its emitter's Linear binder."),
        ("polylineVFromHead", "Polyline texture from the head", "The texture runs along a polyline from its head (the particle, v 0) to its tail."),
        ("binderTarget", "Target mannequin", "Binders and bind points set to Target sit on the target mannequin of Viewport → Stage (6 m ahead by default, facing the caster), with named bind points at the caster's offsets; off, they stay at the origin."),
        ("binderLinearPath", "Binder path to the goal", "Linear, Spline and Linear Adjust binders move from their start point to their goal point by the Carry Over Factor curve over the binder's time."),
        ("childEmitterItemProps", "Item settings on child emitters", "Create Probability, the parent's Child Limit, Override Life, Influence on Child Color, Initial Position and Start Frame act on child emitters as on particles. Without Start Frame Null Update the child starts that many frames in."),
        ("injectionAngleChildEmitters", "Injection angle on child emitters", "By Injection Angle turns the k-th child emitter an item creates by k × the angle about the parent's origin."),
        ("billboardModelKeepsEmitterRotation", "Billboard models keep emitter rotation", "Billboarded Model, Light Model and Disc particles keep their emitters' rotation (without the binder) under their own, on top of the billboard."),
        ("particleDirectionalLight", "Lit models by the effect's light", "Model particles with Is Lightning in an effect with Directional Light Source In Local take the effect's Directional Light effector: colour × (Ambient + Color × Power × term), the term by Directional Light Type; black without such an effector."),
        ("cameraSpace", "Camera space", "Effects with Camera Space are placed in the camera's space and move with the view."),
        ("fitGround", "Fit ground", "Effects with Fit Ground sit on the floor under their bind point."),
        ("revisedRotationNeedsAgs", "Revised rotation needs AGS", "The effect's Revised Rotation turns it only when AGS Enabled is set, as the VFX editing notes describe."),
        ("timelineLoop", "Timeline loop", "A timeline with Loop Start and Loop End starts its items in that range again each time it reaches Loop End, until the effect is released."),
        ("timelineEffectors", "Timeline effectors", "A timeline item with a Target Effector runs that effector for the item's time on its binder, also when the item has an emitter."),
        ("resetOneTimeline", "Reset targets", "A Reset clip restarts only the timelines its integers 2–4 point to (positive n: scheduler item n−1, negative −n: trigger slot n−1, like Kill); with no targets it restarts the whole effect."),
        ("fadeInClip", "Fade In clip", "A Fade In clip fades the timelines its integers 2–4 point to (or everything) in over its first integer in frames."),
        ("binderFollowTargetOrientation", "Following target orientation", "A binder with Following Target Orientation off keeps the position of its bind point but not its turn."),
        ("splineBinderRings", "Spline binder path", "Measured in the game: a Spline binder runs a non-uniform Catmull-Rom curve through the ring points of Properties 1 and 2 (Ring Position X metres aside and Y up in the start's frame, Z the share of the way from start to goal), knots at Ring Progress Time over the time of the Carry Over Factor's last key, chords at the ends; the place along the way is the Carry Over Factor over its last key's value."),
        ("polylineLengthCap", "Trail length in metres", "Measured in the game: a Position History trail is at most Length metres along its path from the head, within the Point Count / 2 frame window; the points past the cut collapse onto it."),
        ("simpleVerticesInOrder", "Sprites on vertices in order", "Measured in the game: Simple Animation sprites placed on model vertices take them in creation order (sprite k on vertex k mod n), not a random vertex."),
        ("withOptionsChildPose", "With Options child emitters", "Measured in the game: a child emitter made by a With Options item (PICd 1) keeps the By Injection Angle turn of its copy even without Influence on Rotation, and its own Position lies in world axes — not turned by the parent, the binder or the copy's turn."),
        ("splineRingRadiusPlane", "Spline ring radius in the X / Y plane", "Ring Radius (RnRd) moves a spline ring point a random way on a circle in the start's X / Y plane (aside and up). The plane is measured in the game; the radius is put on the circle, which is still a guess."),
        ("binderSpring", "Binder spring", "A Point binder's Spring Strength moves its point that share of the way to the bind point every 1/60 s: 1 at once, below 1 lagging, above 1 overshooting."),
        ("binderUpdateFrame", "Binder update frame", "A binder with Coordinate Update Frame 0 or more stops following its bind point after that many frames."),
        ("binderLife", "Binder life", "A binder with a Life above 0 stops following its bind point after that many frames."),
        ("vfxScaleBias", "VFX scale bias", "A binder's VFX Scale Bias scales the whole effect on it, unless BET is set."),
        ("binderTransformScale", "Binder transform scale", "A binder with Transform Scale scales the effect by the size of its caster or target (1 for the preview dummy)."),
        ("binderGenerateDelay", "Binder generate delay", "Emitters on a binder whose start properties have a Generate Delay start that many frames later."),
        ("emitterBillboards", "Emitter billboards", "Emitters with Rotation Direction Base Screen or Camera Billboard face the camera, Billboard Axis Y and Tree Billboard turn about Y towards it, Move Direction turns +Z along a thrown emitter's flight; their own rotation on top."),
        ("noPositionGround", "No Position sticks to the ground", "Children with an influence mode ending in No Position take the parent's influence without its height: they stay on the floor. In the game files these parents set a height far less often than in the modes with position."),
        ("vertexOrder", "Model vertex order", "A model's Vertex Order lists which emitter vertices are used and in what order."),
        ("morphExtrapolates", "Morph beyond the models", "Morph values past the first or last model keep stretching the vertices, as the VFX editing notes describe."),
        ("modelAnimationNumber", "Model animation number", "Animation Number picks a model of the Model Index list by its whole value, without blending."),
        ("fresnelAxis", "Fresnel along an axis", "Fresnel Type Any Axis measures the angle against the particle's +Z turned by Fresnel Rotation, Any Axis With World Rotation against that axis in world space, instead of the view direction."),
        ("polylineLocal", "Polyline local space", "A polyline with Is Local keeps its points in the space of its binder, so it moves with the binder instead of being left behind in the world."),
        ("polylineBindWeapon", "Polyline bind weapon", "A polyline with Bind Weapon runs along the weapon (main hand: base to tip bind points; off hand: from the left hand, mirrored), ignoring its emitter."),
        ("polylinePointDistortion", "Polyline point distortion", "Point Distortion jitters every point of a polyline sideways by up to that many metres, changing every half frame."),
        ("polylineTagHelper", "Polyline tag helper", "A polyline with a Tag Number is not drawn; it is a guide path for Simple Animation sprites whose Polyline Tag names it: their new sprites are born along it."),
        ("simpleLifeZeroEndless", "Sprite life 0 is endless", "Create Interval Life 0, like −1, keeps a sprite until its particle ends."),
        ("simpleUvLoopCount", "Sprite UV loop count", "With UV Loop Count a sprite disappears after running through the atlas that many times."),
        ("simpleUvReverse", "Sprite UV reverse", "UV Reverse set to 1 runs the atlas cells in the opposite order. −1 does not: across 3 359 flipbook atlases of the game the cells fade along the forward order alike with 0 and −1."),
        ("simpleBaseDirection", "Sprite base direction", "Base Direction Type 1 and 3 lay sprites flat on the ground, turning about Y; 2 and 4 stand them upright, turned towards the camera about Y."),
        ("simpleTilt", "Sprite X and Y rotation", "Rotation Start (± Base) X and Y tilt each sprite, turning further at Rotation Add plus a random part of Rotation Velocity per sprite frame."),
        ("simpleDirectionTypes", "Sprite direction left-right and up", "Injection Direction Type 2 throws sprites to the left or right, 4 upwards, each within Injection Radial Direction 0 and 1."),
        ("simpleMoveInterval", "Sprite creation on movement", "With Use Character Movement, Create Interval On Movement creates sprites every that many metres the particle moves; below 0 all at once, 0 none."),
        ("dissolveShape", "Dissolve shape and colour bands", "A Dissolve particle hides the loaded model inside its shape (BST: 1 cube, 2 sphere, 3 cylinder, 0 the box around the model) placed and sized by the particle; Reverse hides it outside. Along the border run the Start, Mid and End colours over Start, Mid and End Color Width, times Intensity; Erosion still cuts by the first texture."),
        ("screenEffectorFields", "Screen effector fields", "Chromatic Aberration shifts by Refraction Strength and splits red and blue by Separation Strength, both times Effect Strength and ramping up over the first second, inside the radius mask; Gaussian Blur uses the same mask (Outer below Inner: 0.1); Directional Blur reads its Angle in degrees, Single Side blurs one way and Angle Strength scales it."),
        ("discPartsCount", "Disc parts count", "A Disc with Parts Count above 1 is drawn that many times, each copy with its own random values."),
        ("discIntervalFactor", "Disc point interval factor", "Point Interval Factor V squeezes the disc texture along V from the middle: positive towards the start, negative towards the end."),
        ("decalScalingScale", "Decal scaling scale", "A Decal's Scaling Scale sets how much of its binder's VFX Scale Bias it follows: 1 all of it, 0 none."),
        ("influenceUnstickiness", "Influence unstickiness", "A following particle whose item has Influence Coordinate Unstickiness above 1 closes only 1 / that of the distance to its parent each frame, trailing behind it."),
        ("modelSkinMasks", "Model Skin masks", "Model Skin EEM (± random) brightens or darkens the skin, SEM brightens its fresnel edge by SEM × Fresnel Curve, and UV Point Density stretches (+) or squeezes (−) its texture."),
        ("particlePointLights", "Lit models by the effect's point lights", "Lit Model particles in an effect with Point Light 1 or 2 set to Local VFX also take the effect's point lights: colour × N·L × min(1, Brightness / Distance Scale / distance^n)."),
        ("pointLightMax", "Point light attenuation Max", "Point lights with Attenuation Max ignore distance."),
        ("powderLighting", "Lit powder", "Powder particles with Is Lightning take the effect's light like lit models, by their Directional Light Type."),
        ("normalMap", "Normal map on lit particles", "Lit particles bend their lighting by the Texture Normal layer, its Power scaling the bend."),
        ("collisionRespawn", "Collision respawn", "A particle with Collision Type 0 starts over from its birth when it reaches the floor."),
        ("movementParticle", "Movement particle hidden", "Quads with Is Movement Particle are support particles for a Directional Blur and are not drawn."),
        ("inGameLight", "Game light on lit particles", "Lit particles in an effect with Directional Light Source In Game take the viewer's own scene light, the one that shades the floor and the model."),
        ("releasedEndlessEnd", "Released endless particles end", "Once released, a particle with endless life ends together with the emitter that made it. While held it stays. Inferred from game files, not checked in the game."),
        ("splineKeyTangents", "Spline keys as measured", "Spline segments are Hermite curves whose slopes come from the neighbouring keys (X weighs the change to the next key, Y the change from the previous one), as measured in the game. Off: they follow the VFXEditor graph instead — Bézier handles moved along time only by the key's X and Y, so every segment eases in and out — for comparing with what VFXEditor draws."),
        ("effectorCoordOrder", "Effector compute order", "An effector's Coordinate Compute Order (CCOT) orders its own translation and rotation as for particles: a Point Light whose order translates before it rotates has its Position turned by its Rotation; a Camera Quake applies its shift and turn in that order. Non-zero in 9 of ~5 000 effectors in the game data."),
        ("pointLightShadows", "Point light shadows", "A Point Light with Enable Shadow (bSdw) and Enable Char Shadow (bChS) casts the loaded reference model's shadow onto the floor and the model, between Create Distance Near and Far (SCDN, SCDF) from the light. bChS and bMpS are on in almost every light in the game data, bSdw in about 2 %, so bSdw is taken as the switch."),
        ("sceneToneMap", "Scene tone map", "Apply Tone Map (bATM) scales the particle's colour by 1 / √(scene brightness), the exposure term read from the game's particle shader (rgb × lerp(1, 1/√lerp(1, L, a), bATM), L the mean brightness of the frame); the brightness comes from Preview → Scene."),
        ("sceneLightRates", "Scene light rates", "Apply Rate Environment (EvAR) and Apply Rate Directional (DlAR) tint the particle by that share of the scene's environment and sun colours from Preview → Scene (white leaves it unchanged)."),
        ("sceneFog", "Scene fog", "With Preview → Scene → Fog on, particles with Apply Fog (bAFg), and every particle of an effect with Global Fog (bGFE, by its influence GFIM), fade into the fog by their distance: blended ones toward the fog colour, additive ones toward black, multiplying ones toward white."),
        ("decalProjection", "Decal projection", "Decal and Decal Ring project onto whatever lies inside their box, as the game's decal shader does: the floor and the loaded reference model, tilted boxes included; alpha fades to the top and bottom of the box (× min(1, 5 · (0.5 − |y|))). Off: a flat quad on the floor, drawn only when the box reaches it."),
        ("reflectionLayer", "Reflection layer", "The Texture Reflection layer looks up its texture by the view reflected on the surface (a cube map, or a sphere map for a flat texture) and mixes it into the colour by its Calculate Color; Rate and Power are not used."),
        ("emitterBirthNoAge", "Emitters do not age on their birth step", "An emitter started by a timeline item already has the age since the item started and does not age again on that step; it creates whatever falls before its end, so an emitter living one or two frames still creates."),
        ("emitterLifeZeroWindow", "Emitter Life 0 lasts its timeline window", "An emitter with Life 0 started by a timeline item lives for the item's window instead of one frame."),
        ("generateDelayPastLife", "Generate Delay past the emitter's end", "An item whose Generate Delay is after its emitter's end is still created once at that frame."),
        ("emitterItemsIgnoreEnabled", "Emitter items ignore Enabled", "The game creates emitter items (particles and child emitters) even when their Enabled flag is off; timeline items keep theirs."),
        ("timelineItemLimit", "32 items per timeline", "The game runs only the first 32 items of a timeline."),
        ("simpleSpriteHalfSize", "Sprite scale is half the size", "Simple Animation Scale Start and End are half the sprite's size."),
    ]

    private static var cache: [String: Bool] = [:]
    static private(set) var token = 0

    struct Hot {
        var stepKeyOnArrival = true
        var randomAlwaysPerFrame = true
        var axisConnectRandom = true
        var periodicCurves = true
        var randomTypeOnRandom = true
        var colorRandom = true
        var splineKeyTangents = true
    }

    private static var hotToken = -1
    private static var hotValues = Hot()

    static var hot: Hot {
        if hotToken != token {
            hotValues = Hot(stepKeyOnArrival: isOn("stepKeyOnArrival"), randomAlwaysPerFrame: isOn("randomAlwaysPerFrame"),
                            axisConnectRandom: isOn("axisConnectRandom"), periodicCurves: isOn("periodicCurves"),
                            randomTypeOnRandom: isOn("randomTypeOnRandom"), colorRandom: isOn("colorRandom"),
                            splineKeyTangents: isOn("splineKeyTangents"))
            hotToken = token
        }
        return hotValues
    }

    static func isOn(_ key: String) -> Bool {
        if let cached = cache[key] { return cached }
        let value = UserDefaults.standard.object(forKey: "rule." + key) as? Bool ?? true
        cache[key] = value
        return value
    }

    static func set(_ key: String, _ value: Bool) {
        UserDefaults.standard.set(value, forKey: "rule." + key)
        cache[key] = value
        token += 1
    }

    static func bump() { token += 1 }

    static func curveColors() -> [Color]? {
        guard let stored = UserDefaults.standard.stringArray(forKey: "curve.colors"), stored.count == 3 else { return nil }
        var list = EffectDocument.defaultChannelColors
        for (index, text) in stored.enumerated() {
            let parts = text.split(separator: ",").compactMap { Double($0) }
            if parts.count == 3 { list[index] = Color(red: parts[0], green: parts[1], blue: parts[2]) }
        }
        return list
    }

    static func setCurveColor(_ index: Int, _ color: Color) {
        var stored = UserDefaults.standard.stringArray(forKey: "curve.colors") ?? []
        if stored.count != 3 {
            stored = EffectDocument.defaultChannelColors.prefix(3).map { color in
                let c = NSColor(color).usingColorSpace(.sRGB) ?? .white
                return "\(c.redComponent),\(c.greenComponent),\(c.blueComponent)"
            }
        }
        let c = NSColor(color).usingColorSpace(.sRGB) ?? .white
        stored[index] = "\(c.redComponent),\(c.greenComponent),\(c.blueComponent)"
        UserDefaults.standard.set(stored, forKey: "curve.colors")
        token += 1
    }

    static func resetCurveColors() {
        UserDefaults.standard.removeObject(forKey: "curve.colors")
        token += 1
    }
}

enum AppShortcuts {
    static let commands: [(key: String, title: String, fallback: String, shift: Bool)] = [
        ("new", "New Effect", "n", false), ("open", "Open File", "o", false), ("openFolder", "Open Folder", "o", true), ("save", "Save", "s", false),
        ("saveAs", "Save As", "s", true), ("undo", "Undo", "z", false), ("redo", "Redo", "z", true),
    ]

    static func key(_ command: String) -> KeyEquivalent {
        let fallback = commands.first { $0.key == command }?.fallback ?? "?"
        let stored = UserDefaults.standard.string(forKey: "shortcut." + command) ?? fallback
        return KeyEquivalent(stored.lowercased().first ?? Character(fallback))
    }
}

extension AppShortcuts {
    static let editorKeys: [(key: String, title: String, fallback: String)] = [
        ("grab", "Move", "g"), ("scale", "Scale", "s"), ("rotate", "Rotate", "r"), ("delete", "Delete", "x"), ("selectAll", "Select All", "a"),
        ("linked", "Select Linked", "l"), ("frame", "Frame Selected", "."), ("fill", "Fill Face", "f"), ("merge", "Merge Vertices", "m"),
        ("extrude", "Extrude", "e"), ("insertKey", "Insert Keyframe", "i"), ("interpolation", "Cycle Interpolation", "t"),
    ]

    static func editorKey(_ command: String) -> String {
        let fallback = editorKeys.first { $0.key == command }?.fallback ?? ""
        return UserDefaults.standard.string(forKey: "editkey." + command) ?? fallback
    }

    static func canonical(_ characters: String) -> String {
        guard characters.count == 1 else { return characters }
        for command in editorKeys where editorKey(command.key) == characters { return command.fallback }
        if editorKeys.contains(where: { $0.fallback == characters && editorKey($0.key) != characters }) { return "" }
        return characters
    }
}

enum Appearance {
    static func number(_ key: String, _ fallback: Double) -> Double {
        UserDefaults.standard.object(forKey: "look." + key) == nil ? fallback : UserDefaults.standard.double(forKey: "look." + key)
    }

    static func setNumber(_ key: String, _ value: Double) { UserDefaults.standard.set(value, forKey: "look." + key) }

    static func rgb(_ key: String, _ fallback: SIMD3<Double>) -> SIMD3<Double> {
        guard let parts = UserDefaults.standard.string(forKey: "look." + key)?.split(separator: ",").compactMap({ Double($0) }), parts.count == 3 else { return fallback }
        return SIMD3(parts[0], parts[1], parts[2])
    }

    static func setRGB(_ key: String, _ value: SIMD3<Double>?) {
        if let value {
            UserDefaults.standard.set("\(value.x),\(value.y),\(value.z)", forKey: "look." + key)
        } else {
            UserDefaults.standard.removeObject(forKey: "look." + key)
        }
    }

    static func isSet(_ key: String) -> Bool { UserDefaults.standard.object(forKey: "look." + key) != nil }

    static func reset() {
        for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("look.") { UserDefaults.standard.removeObject(forKey: key) }
    }

    static let selectedDefault = SIMD3<Double>(1, 0.63, 0.16)
    static let barSelectedDefault = SIMD3<Double>(1, 1, 1)

    static var curveWidth: CGFloat { CGFloat(number("curve.width", 1.6)) }
    static var pointSize: CGFloat { CGFloat(number("curve.point", 3.5)) }
    static var selectedSize: CGFloat { CGFloat(number("curve.selected", 4.5)) }
    static var grabDistance: CGFloat { CGFloat(number("curve.grab", 9)) }
    static var selectedColor: Color {
        let c = rgb("curve.selectedColor", selectedDefault)
        return Color(.sRGB, red: c.x, green: c.y, blue: c.z)
    }
    static var barColor: Color? {
        guard isSet("timeline.bar") else { return nil }
        let c = rgb("timeline.bar", SIMD3(0.44, 0.457, 0.492))
        return Color(.sRGB, red: c.x, green: c.y, blue: c.z)
    }
    static var barSelectedColor: Color {
        let c = rgb("timeline.selected", barSelectedDefault)
        return Color(.sRGB, red: c.x, green: c.y, blue: c.z)
    }
}

