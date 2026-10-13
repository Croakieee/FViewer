# Changelog

## 1.3 beta (2026-10-12)

### Effects
- Every field and curve of an `.avfx` file is editable.
- Timeline, Graph Editor, Node Editor and Item Editor.
- Timeline strips show how many particles are alive on each frame.
- Highlight and Solo follow the emitter or particle a selected row refers to.

### Preview
- Point and directional lights, screen blurs, chromatic aberration and camera quake.
- Game skeleton with bind points and a textured game model as reference objects.
- Coord Compute Order, UV rotation random, rotation velocity random, clip near and far, texture filter levels, mipmaps.
- 44 preview rules that can be switched off one by one.

### Game files
- File Inspector with undo for `.tmb`, `.pap`, `.eid`, `.mtrl`, `.phyb`, `.kdb`, `.skp`, `.atch`, `.imc` and `.scd`; viewers for `.mdl`, `.sklb` and `.tex`.
- Reading files from the game's `sqpack` archives.
- Game Catalog and content search across the open folder.

### Mods
- Export as Penumbra `.pmp` or TexTools `.ttmp2` with option groups.

### Fixed
- UI stalls after clicks when recent files are on a slow or external disk.
- Texture layers 2–4 were blended with white when layer 1 was off.

### Known limitations
- Dissolve particles, Black Hole effectors, normal and reflection textures are not drawn.
- Vorbis sounds in `.scd` are not played.
