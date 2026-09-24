# iOS artwork

The asset catalog contains a small, optimized derivative set for the iOS interface. Original PNGs remain in `imgs capas/componentes novos/` and are not modified.

| Asset | Source | Transformation | Use |
| --- | --- | --- | --- |
| `FocusArtwork` | `capa thumbnails/ChatGPT Image 24 de set. de 2026, 15_30_00 (6).png` | Crop `(0, 800)–(640, 1200)`, composite to the app's dark ink surface, JPEG 82, 720×450 | Foco Profundo artwork; ink bottle and score crop removes the portrait and embedded English title |
| `PianoEveningArtwork` | `capa thumbnails/ChatGPT Image 24 de set. de 2026, 15_30_01 (7).png` | Crop `(600, 650)–(1200, 1250)`, composite to the app's dark ink surface, JPEG 82, 720×720 | Piano para Dormir artwork; crop removes the embedded English title |
| `BachPortrait` | `compositores/ChatGPT Image 24 de set. de 2026, 15_16_25 (1).png` | Resize to 512×512, preserve transparency, optimized PNG | Composer filter |
| `ChopinPortrait` | `compositores/ChatGPT Image 24 de set. de 2026, 15_16_26 (2).png` | Resize to 512×512, preserve transparency, optimized PNG | Composer filter |
| `MozartPortrait` | `compositores/ChatGPT Image 24 de set. de 2026, 15_16_26 (3).png` | Resize to 512×512, preserve transparency, optimized PNG | Composer filter |
| `BeethovenPortrait` | `compositores/ChatGPT Image 24 de set. de 2026, 15_16_27 (4).png` | Resize to 512×512, preserve transparency, optimized PNG | Composer filter |

The two cover crops contain no embedded title; category names and descriptions are rendered as native, localized SwiftUI text. Composer names are also native text and remain accessible to VoiceOver.

Source artwork was supplied in the project workspace. Its licensing/provenance evidence was not present in the source directory when audited and should be recorded before public distribution.
