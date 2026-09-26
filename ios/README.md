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

O app oferece uma contribuição avulsa não consumível pelo StoreKit 2. O Product ID exato cadastrado no App Store Connect é `musicapara.estudar.donation.r10` (não derivar do Bundle ID); configure o produto como **Não consumível**, com preço de R$ 10,00 e localização em português do Brasil. O app consulta esse ID, exibe o preço localizado da App Store, reconhece uma compra anterior e oferece restauração. A compra pode ser feita uma vez por Apple ID.

`StoreKit/Donation.storekit` espelha o Product ID e o tipo Não consumível para validar a consulta de produto em testes locais. O teste de captura da oferta não injeta um preço fictício. Para validar uma compra real, use um Apple ID sandbox em aparelho físico; a compra é enviada e aprovada pela App Store.

Para a versão 1.1 reenviada após o build 16, mantenha `MARKETING_VERSION` em `1.1` e incremente o build para `17`. No fluxo GitHub Actions, `CURRENT_PROJECT_VERSION` do archive usa o número da execução do workflow.
