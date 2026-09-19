# iOS catalog and rights gate

Only records in `catalog.json` under `tracks` may be shipped or played. Every shipped recording must include a rights status of `approved`, a source URL, a non-empty license/rights statement, and a SHA-256 hash of the exact bundled file.

The current Mozart candidate is intentionally blocked. The Android filename is evidence of an existing file, not proof of its recording identity, license, or redistribution rights. Mozart's compositions being public domain does not clear a modern performance.

To approve a recording, add it to `tracks`, preserve the exact work and performer facts from the source, add territory and verification date, calculate the hash, and run `python3 Scripts/validate_catalog.py`.
