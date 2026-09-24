#!/usr/bin/env python3
"""Validate optimized artwork assets included in the iOS app bundle."""

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ASSET_CATALOG = ROOT / "MusicasParaEstudar/Resources/Assets.xcassets"
EXPECTED_ASSETS = {
    "FocusArtwork": "focus_artwork.jpg",
    "PianoEveningArtwork": "piano_evening_artwork.jpg",
    "BachPortrait": "bach_portrait.png",
    "ChopinPortrait": "chopin_portrait.png",
    "MozartPortrait": "mozart_portrait.png",
    "BeethovenPortrait": "beethoven_portrait.png",
}
MAX_TOTAL_BYTES = 2 * 1024 * 1024


def main() -> None:
    total_bytes = 0
    for asset_name, expected_filename in EXPECTED_ASSETS.items():
        asset_set = ASSET_CATALOG / f"{asset_name}.imageset"
        manifest = json.loads((asset_set / "Contents.json").read_text(encoding="utf-8"))
        images = manifest.get("images", [])
        if len(images) != 1:
            raise SystemExit(f"{asset_name}: expected exactly one universal image")

        image = images[0]
        filename = image.get("filename")
        if filename != expected_filename or image.get("idiom") != "universal":
            raise SystemExit(f"{asset_name}: unexpected image entry {image!r}")

        image_path = asset_set / filename
        if not image_path.is_file():
            raise SystemExit(f"{asset_name}: missing image {image_path}")
        total_bytes += image_path.stat().st_size

    if total_bytes > MAX_TOTAL_BYTES:
        raise SystemExit(
            f"Optimized artwork is {total_bytes / 1024 / 1024:.2f} MiB; "
            f"budget is {MAX_TOTAL_BYTES / 1024 / 1024:.0f} MiB"
        )

    print(f"Validated {len(EXPECTED_ASSETS)} artwork assets ({total_bytes / 1024:.1f} KiB)")


if __name__ == "__main__":
    main()
