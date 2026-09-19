# iOS catalog and rights gate

Only records in `catalog.json` under `tracks` are bundled. Playback accepts only records with a rights status of `approved`. Every approved recording must include a source URL, a non-empty license/rights statement, territory, verification date, and a SHA-256 hash of the exact bundled file.

Development validation reports unverified recordings without treating them as licensed. Distribution validation (`python3 Scripts/validate_catalog.py --distribution`) fails if any bundled recording is not approved; the release workflow runs this gate before signing or uploading.

The current catalog is intentionally empty. Existing audio candidates were removed from both iOS and Android because filenames, catalog labels, and composition public-domain status do not prove rights to the specific recording or its redistribution.

To approve a recording, preserve the exact work and performer facts from the source, add territory and verification date, calculate the hash, and run both validator modes. Approval must be based on actual rights evidence; catalog metadata and composition age are not evidence of recording rights.
