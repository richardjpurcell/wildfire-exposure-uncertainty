#!/usr/bin/env python3
"""Inventory local raw geospatial files without modifying them."""

from pathlib import Path
import csv
import hashlib

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "raw"
OUTPUT = ROOT / "docs" / "datasets" / "local-data-manifest.csv"

def sha256_file(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()

files = sorted(path for path in DATA.rglob("*") if path.is_file())

assert len(files) == 16, (
    f"Expected 16 raw files; found {len(files)}"
)

rows = []

for path in files:
    rows.append({
        "relative_path": path.relative_to(ROOT).as_posix(),
        "size_bytes": path.stat().st_size,
        "sha256": sha256_file(path),
    })

OUTPUT.parent.mkdir(parents=True, exist_ok=True)

with OUTPUT.open("w", newline="") as stream:
    writer = csv.DictWriter(
        stream,
        fieldnames=["relative_path", "size_bytes", "sha256"],
    )
    writer.writeheader()
    writer.writerows(rows)

print("Manifest:", OUTPUT.relative_to(ROOT))
print("Files:", len(rows))
print("Total bytes:", sum(row["size_bytes"] for row in rows))
print("Unique checksums:", len(set(row["sha256"] for row in rows)))
print("Data manifest creation: PASSED")
