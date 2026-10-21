# Third-party notices

## Dalamud-VFXEditor

FViewer follows the field names, defaults and file layouts of [Dalamud-VFXEditor](https://github.com/0ceal0t/Dalamud-VFXEditor) and ships data derived from it in `FViewer/Resources`:

- `AvfxCatalog.json`, `AvfxDefaults.json`, `TmbCatalog.json`: field and layout tables generated from its sources
- `default_*.vfxedit`, `template_blank.avfx`, `template_weapon.avfx`: default nodes and effect templates
- `catalog_*.txt`, `atch_names.txt`, `useful_textures.txt`: lists of game paths and names

Dalamud-VFXEditor is distributed under the MIT License:

```
Copyright 2021 Michael Kaminsky

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## dev_ffxiv_avfx_preview and three.js

The 3D preview is the player of [dev_ffxiv_avfx_preview](https://github.com/zerobyted/dev_ffxiv_avfx_preview). Its build (`dist/player/avfx-player.iife.js`) and its field statistics (`docs/field_stats.json`) are copied into the app when FViewer is built; they are not part of this repository.

The player bundles [three.js](https://github.com/mrdoob/three.js), distributed under the MIT License:

```
The MIT License

Copyright © 2010-2024 three.js authors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

## FINAL FANTASY XIV

FINAL FANTASY XIV is a registered trademark of SQUARE ENIX CO., LTD. FViewer is not affiliated with SQUARE ENIX. The repository contains no game assets. `bone_names.txt` and the path lists hold names only.
