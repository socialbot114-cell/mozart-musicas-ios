#!/usr/bin/env python3
"""Fail closed on missing rights metadata or incorrect Mozart attribution."""
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
    for field in ("rightsStatus", "license", "sourceUrl", "sha256"):
        if not item.get(field):
            errors.append(f"{item.get('id', '<unknown>')}: missing {field}")
    if item.get("rightsStatus") != "approved":
        errors.append(f"{item.get('id', '<unknown>')}: audio is not approved")
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
print(f"Catalog validation passed: {len(tracks)} approved track(s), {len(catalog.get('candidates', []))} candidate(s).")
