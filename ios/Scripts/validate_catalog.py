#!/usr/bin/env python3
"""Validate bundled audio integrity and enforce recording rights for releases."""
import argparse
import hashlib
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
DONATION_PRODUCT_ID = "musicapara.estudar.donation.r10"
parser = argparse.ArgumentParser()
parser.add_argument(
    "--distribution",
    action="store_true",
    help="fail unless every bundled track has verified distribution rights",
)
args = parser.parse_args()
catalog = json.loads((ROOT / "Catalog/catalog.json").read_text(encoding="utf-8"))
errors = []
tracks = catalog.get("tracks", [])
seen_ids = set()
for item in tracks:
    item_id = item.get("id", "<unknown>")
    if item_id in seen_ids:
        errors.append(f"{item_id}: duplicate track id")
    seen_ids.add(item_id)
    path_value = item.get("audioPath")
    if not path_value:
        errors.append(f"{item_id}: audioPath is required for a bundled track")
        continue
    relative_path = pathlib.PurePosixPath(path_value)
    if relative_path.is_absolute() or ".." in relative_path.parts:
        errors.append(f"{item_id}: audioPath must be a safe bundle-relative path")
        continue
    audio = ROOT / "MusicasParaEstudar/Resources" / relative_path
    if item.get("rightsStatus") not in {"approved", "unverified"}:
        errors.append(f"{item_id}: invalid rightsStatus")
    if args.distribution and item.get("rightsStatus") != "approved":
        errors.append(f"{item_id}: distribution blocked because recording rights are unverified")
    if item.get("rightsStatus") == "approved":
        for field in ("sourceUrl", "license", "territory", "verificationDate"):
            if not item.get(field):
                errors.append(f"{item_id}: approved track is missing {field}")
    if not item.get("sha256"):
        errors.append(f"{item_id}: missing sha256")
    if not audio.is_file():
        errors.append(f"{item_id}: audio file does not exist: {path_value}")
    elif item.get("sha256") and hashlib.sha256(audio.read_bytes()).hexdigest() != item["sha256"]:
        errors.append(f"{item_id}: SHA-256 does not match audio")

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
mode = "distribution" if args.distribution else "development"
print(f"Catalog {mode} validation passed: {len(tracks)} track(s), {len(catalog.get('candidates', []))} candidate(s).")
unverified = sum(item.get("rightsStatus") == "unverified" for item in tracks)
if unverified:
    print(f"WARNING: {unverified} track(s) remain unverified and require rights review before App Review.")

storekit_config = json.loads((ROOT / "StoreKit/Donation.storekit").read_text(encoding="utf-8"))
donation_products = [
    product for product in storekit_config.get("products", [])
    if product.get("productID") == DONATION_PRODUCT_ID
]
assert len(donation_products) == 1, "StoreKit configuration must contain the App Store Connect donation Product ID"
assert donation_products[0].get("type") == "NonConsumable", "Donation product must match the App Store Connect non-consumable type"
donation_source = (ROOT / "MusicasParaEstudar/Services/DonationStore.swift").read_text(encoding="utf-8")
assert f'static let productID = "{DONATION_PRODUCT_ID}"' in donation_source, "DonationStore Product ID does not match App Store Connect"
assert any(
    localization.get("locale") == "pt_BR"
    for localization in donation_products[0].get("localizations", [])
), "Donation product must have a Brazilian Portuguese localization"
print(f"StoreKit IAP contract validation passed: {DONATION_PRODUCT_ID} (NonConsumable).")
