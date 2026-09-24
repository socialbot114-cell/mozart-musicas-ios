# iOS artwork library

The iOS asset catalog contains optimized derivatives of all 60 supplied artwork PNGs: **7.40 MiB** from 76.84 MiB of individual source PNGs. The 2.18 MiB contact sheet is not bundled, and originals in `imgs capas/componentes novos/` are not modified.

| Group | Count | Intended use | Derivative target |
| --- | ---: | --- | --- |
| Collection covers | 5 | Home collection cards and matching Explore filters; English lettering is cropped out and titles come from SwiftUI | 720 px, JPEG 82 |
| Composer portraits | 10 | Explore composer carousel and corresponding track/mini-player/player artwork | 768 px, purple-gradient composite, optimized JPEG 86 |
| Instruments and score items | 10 | Explore visual selector; instrument filtering only returns tracks matching catalog metadata/titles | 384 px, transparent optimized PNG |
| Study objects | 10 | Selectable Focus ambience illustrations | 384 px, transparent optimized PNG |
| Ornaments | 15 | Subtle accents across collection cards, category artwork, Focus and Player | 512 px; wide divider 768 px, transparent optimized PNG |
| Player controls | 10 | Functional native buttons for play/pause, track navigation, shuffle, repeat, volume, favorites, queue and menu | 256 px, transparent optimized PNG |

Every derivative is documented with its source path, semantic name, crop/resize, dimensions and byte size in `ARTWORK.json`. Run `python3 ios/Scripts/prepare_artwork.py` from the repository root (Pillow required) to regenerate the asset catalog from the original source folder. CI runs `python3 ios/Scripts/validate_artwork.py` and enforces the 12 MiB artwork budget.

The source filenames indicate generated artwork, but licensing/provenance evidence was not present in the source directory when audited. Record that evidence before public distribution.
