# iOS foundation

Generated with XcodeGen for App Store ID `6813681353` and bundle `br.com.musicaspara.estudar`.

The product shell lists and plays only recordings marked `approved`. The bundled catalog contains 50 approved recordings, each with a verified source URL, license, territory, verification date and a SHA-256 hash of the exact bundled file. Composition age, filenames, hashes, and artwork are not evidence of recording rights; approval is based on recorded rights evidence per track.

On macOS with XcodeGen installed:

```bash
xcodegen generate --spec ios/project.yml
xcodebuild -project MusicasParaEstudar.xcodeproj -scheme MusicasParaEstudar test
```

Run `python3 ios/Scripts/validate_catalog.py --distribution` from the repository root before creating any distributable archive.
