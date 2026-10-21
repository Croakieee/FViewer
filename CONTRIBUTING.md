# Contributing

## Setup

1. Open `FViewer.xcodeproj` in Xcode 26 or later.
2. Copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig` and set your team and a bundle ID suffix.
3. Run the `FViewer` scheme.

Do not pick a team in Signing & Capabilities. If `DEVELOPMENT_TEAM` or `PRODUCT_BUNDLE_IDENTIFIER` shows up in a diff of `project.pbxproj`, remove it before committing.

## Rules

- Field names and defaults follow Dalamud-VFXEditor. Where the two disagree, VFXEditor is right.
- Saving never overwrites the source file.
- All text in the app is English.
- No comments in code.
- A file opened and saved without changes must come out byte for byte the same. Check this for any format you touch.

## Issues

Name the game path of the file (for example `vfx/monster/m0016/eff/m0016sp01c0f.avfx`) instead of attaching it. Game files belong to SQUARE ENIX and must not be uploaded here.

## Pull requests

One change per pull request. Say what you tested and on which files.
