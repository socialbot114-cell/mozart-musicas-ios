#!/usr/bin/env python3
"""Create a smaller screenshot APK by replacing bundled MP3s with empty files."""

from __future__ import annotations

import argparse
import zipfile
from pathlib import Path


def is_signature_file(filename: str) -> bool:
    normalized = filename.upper()
    return normalized.startswith("META-INF/") and (
        normalized == "META-INF/MANIFEST.MF"
        or normalized.endswith((".SF", ".RSA", ".DSA", ".EC"))
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    if not args.input.is_file():
        raise FileNotFoundError(f"Debug APK not found: {args.input}")
    args.output.parent.mkdir(parents=True, exist_ok=True)

    replaced_audio = 0
    with zipfile.ZipFile(args.input, "r") as source, zipfile.ZipFile(
        args.output, "w"
    ) as destination:
        for entry in source.infolist():
            if is_signature_file(entry.filename):
                continue
            if entry.filename.startswith("res/raw/audio_") and entry.filename.endswith(".mp3"):
                destination.writestr(entry, b"")
                replaced_audio += 1
            else:
                destination.writestr(entry, source.read(entry.filename))

    if replaced_audio == 0:
        raise RuntimeError("No bundled audio resources were found to replace")
    print(f"Replaced {replaced_audio} audio resources in {args.output}")


if __name__ == "__main__":
    main()
