# iOS catalog and rights gate

Only records in `catalog.json` under `tracks` are bundled. Playback accepts only records with a rights status of `approved`. Every approved recording must include a source URL, a non-empty license/rights statement, territory, verification date, and a SHA-256 hash of the exact bundled file.

Development validation reports unverified recordings without treating them as licensed. Distribution validation (`python3 Scripts/validate_catalog.py --distribution`) fails if any bundled recording is not approved; the release workflow runs this gate before signing or uploading.

The bundled catalog contains 50 approved recordings. Every approved recording preserves the exact work and performer facts from its source, includes territory and verification date, and carries a SHA-256 hash of the bundled file. Approval is based on actual rights evidence; catalog metadata and composition age alone are not evidence of recording rights.
