#!/usr/bin/env python3
"""Validate bundled audio integrity and flag rights that still need review."""
import hashlib
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
catalog = json.loads((ROOT / "Catalog/catalog.json").read_text(encoding="utf-8"))
errors = []
tracks = catalog.get("tracks", [])
for item in tracks:
    path_value = item.get("audioPath")
    if not path_value:
        errors.append(f"{item.get('id', '<unknown>')}: audioPath is required for a shipped track")
        continue
    audio = ROOT / path_value
    if not audio.is_file():
        audio = ROOT / "MusicasParaEstudar/Resources" / path_value
    if item.get("rightsStatus") not in {"approved", "unverified"}:
        errors.append(f"{item.get('id', '<unknown>')}: invalid rightsStatus")
    if not item.get("sha256"):
        errors.append(f"{item.get('id', '<unknown>')}: missing sha256")
    if not audio.is_file():
        errors.append(f"{item.get('id', '<unknown>')}: audio file does not exist: {path_value}")
    elif item.get("sha256") and hashlib.sha256(audio.read_bytes()).hexdigest() != item["sha256"]:
        errors.append(f"{item.get('id', '<unknown>')}: SHA-256 does not match audio")

for item in tracks + catalog.get("candidates", []):
    composer = item.get("composer", "")
    if re.search(r"mozart", composer, re.I):
        if composer != "Wolfgang Amadeus Mozart":
            errors.append(f"{item.get('id', '<unknown>')}: invalid Mozart composer value")
        if not item.get("work") or not item.get("recording"):
            errors.append(f"{item.get('id', '<unknown>')}: Mozart work and recording facts are required")

if errors:
    print("Catalog validation failed:")
    print("\n".join(f"- {error}" for error in errors))
    sys.exit(1)
print(f"Catalog validation passed: {len(tracks)} track(s), {len(catalog.get('candidates', []))} candidate(s).")
unverified = sum(item.get("rightsStatus") == "unverified" for item in tracks)
if unverified:
    print(f"WARNING: {unverified} track(s) remain unverified and require rights review before App Review.")
