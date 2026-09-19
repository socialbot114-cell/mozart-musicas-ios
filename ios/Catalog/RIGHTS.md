# iOS catalog and rights gate

Only records in `catalog.json` under `tracks` are bundled. Playback accepts only records with a rights status of `approved`. Every approved recording must include a source URL, a non-empty license/rights statement, territory, verification date, and a SHA-256 hash of the exact bundled file.

Development validation reports unverified recordings without treating them as licensed. Distribution validation (`python3 Scripts/validate_catalog.py --distribution`) fails if any bundled recording is not approved; the release workflow runs this gate before signing or uploading.

The current Mozart candidate is intentionally blocked. The Android filename is evidence of an existing file, not proof of its recording identity, license, or redistribution rights. Mozart's compositions being public domain does not clear a modern performance.

To approve a recording, preserve the exact work and performer facts from the source, add territory and verification date, calculate the hash, and run both validator modes. Approval must be based on actual rights evidence; catalog metadata and composition age are not evidence of recording rights.
