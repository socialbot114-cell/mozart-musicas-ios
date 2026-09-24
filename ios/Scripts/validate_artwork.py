#!/usr/bin/env python3
"""Validate the complete optimized artwork library included in the iOS app."""

import json
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ASSET_CATALOG = ROOT / "MusicasParaEstudar/Resources/Assets.xcassets"
SWIFT_SOURCE = ROOT / "MusicasParaEstudar"
MANIFEST_PATH = ROOT / "ARTWORK.json"
EXPECTED_GROUP_COUNTS = {
    "collections": 5,
    "composers": 10,
    "instruments": 10,
    "study_objects": 10,
    "ornaments": 15,
    "player_controls": 10,
}
MAX_TOTAL_BYTES = 12 * 1024 * 1024


def main() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    assets = manifest.get("assets", [])
    if manifest.get("assetCount") != 60 or len(assets) != 60:
        raise SystemExit(f"Expected a 60-asset artwork library; found {len(assets)}")

    groups = Counter(asset.get("group") for asset in assets)
    if dict(groups) != EXPECTED_GROUP_COUNTS:
        raise SystemExit(f"Unexpected artwork group counts: {dict(groups)!r}")

    asset_names = [asset.get("asset") for asset in assets]
    if len(set(asset_names)) != len(asset_names):
        raise SystemExit("Artwork manifest contains duplicate asset names")

    swift_source = "\n".join(path.read_text(encoding="utf-8") for path in SWIFT_SOURCE.rglob("*.swift"))
    unreferenced = [name for name in asset_names if name not in swift_source]
    if unreferenced:
        raise SystemExit(f"Artwork assets not referenced by the app: {unreferenced!r}")

    total_bytes = 0
    for asset in assets:
        asset_name = asset["asset"]
        asset_set = ASSET_CATALOG / asset["imageset"]
        manifest_path = asset_set / "Contents.json"
        if not manifest_path.is_file():
            raise SystemExit(f"{asset_name}: missing {manifest_path}")

        image_manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        images = image_manifest.get("images", [])
        if len(images) != 1 or images[0].get("idiom") != "universal":
            raise SystemExit(f"{asset_name}: expected one universal image")

        filename = images[0].get("filename")
        if filename != asset.get("filename"):
            raise SystemExit(f"{asset_name}: asset catalog and artwork manifest disagree")

        image_path = asset_set / filename
        if not image_path.is_file():
            raise SystemExit(f"{asset_name}: missing image file {image_path}")
        total_bytes += image_path.stat().st_size

    if total_bytes > MAX_TOTAL_BYTES:
        raise SystemExit(
            f"Artwork library is {total_bytes / 1024 / 1024:.2f} MiB; "
            f"budget is {MAX_TOTAL_BYTES / 1024 / 1024:.0f} MiB"
        )

    print(f"Validated {len(assets)} artwork assets ({total_bytes / 1024 / 1024:.2f} MiB)")
    for group in sorted(groups):
        print(f"  {group}: {groups[group]}")


if __name__ == "__main__":
    main()
