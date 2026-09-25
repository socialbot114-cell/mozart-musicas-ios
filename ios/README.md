# iOS foundation

Generated with XcodeGen for App Store ID `6813681353` and bundle `br.com.musicaspara.estudar`.

The product shell lists and plays only recordings marked `approved`. The bundled catalog contains 50 approved recordings, each with a verified source URL, license, territory, verification date and a SHA-256 hash of the exact bundled file. Composition age, filenames, hashes, and artwork are not evidence of recording rights; approval is based on recorded rights evidence per track.

On macOS with XcodeGen installed:

```bash
xcodegen generate --spec ios/project.yml
xcodebuild -project MusicasParaEstudar.xcodeproj -scheme MusicasParaEstudar test
```

Run `python3 ios/Scripts/validate_artwork.py` from the repository root to verify the optimized asset catalog. Run `python3 ios/Scripts/validate_catalog.py --distribution` before creating any distributable archive.

## Contribuição opcional

O app oferece uma compra consumível avulsa pelo StoreKit 2. O identificador esperado no App Store Connect é `br.com.musicaspara.estudar.donation.r10`; cadastre-o como In-App Purchase consumível com preço de R$ 10,00 e localização em português do Brasil. A compra não é recorrente, e o app exibe o preço localizado retornado pela App Store.

`StoreKit/Donation.storekit` simula o produto a R$ 10,00 para execução local pelo scheme gerado do XcodeGen. Compras reais só ficam disponíveis depois que o produto estiver criado e liberado para teste no App Store Connect.
