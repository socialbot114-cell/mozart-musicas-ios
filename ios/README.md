# iOS foundation

Generated with XcodeGen for App Store ID `6813681353` and bundle `br.com.musicaspara.estudar`.

The product shell lists and plays only recordings marked `approved`. The distributable catalog is currently empty because no bundled recording has verified redistribution evidence. Composition age, filenames, hashes, and artwork are not evidence of recording rights.

On macOS with XcodeGen installed:

```bash
xcodegen generate --spec ios/project.yml
xcodebuild -project MusicasParaEstudar.xcodeproj -scheme MusicasParaEstudar test
```

Run `python3 ios/Scripts/validate_catalog.py --distribution` from the repository root before creating any distributable archive.
