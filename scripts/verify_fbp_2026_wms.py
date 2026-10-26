#!/usr/bin/env python3
"""Compare local 2026 FBP raster codes with official WMS descriptions."""

import argparse
import csv
import os
import subprocess
import tempfile
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[1]

RASTER = (
    ROOT / "data/processed/study-window/"
    "fbp_2026_candidate_100m.tif"
)

WMS = "https://ca.nfis.org/mapserver/cgi-bin/fbp_eng.cgi"


class TableCells(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_td = False
        self.cells = []

    def handle_starttag(self, tag, attrs):
        if tag == "td":
            self.in_td = True

    def handle_endtag(self, tag):
        if tag == "td":
            self.in_td = False

    def handle_data(self, data):
        if self.in_td and data.strip():
            self.cells.append(data.strip())


def sample_cells(code, count):
    r_code = r'''
library(terra)

args <- commandArgs(trailingOnly = TRUE)
raster_path <- args[1]
code <- as.numeric(args[2])
count <- as.integer(args[3])
output <- args[4]

r <- rast(raster_path)
cells <- which(values(r, mat = FALSE) == code)

if (length(cells) == 0) {
  stop("Requested code not present in local raster")
}

indices <- unique(as.integer(round(
  seq(1, length(cells), length.out = min(count, length(cells)))
)))

selected <- cells[indices]
xy <- xyFromCell(r, selected)

write.csv(
  data.frame(code = code, x = xy[, 1], y = xy[, 2]),
  output,
  row.names = FALSE
)
'''

    rscript = Path(os.environ["CONDA_PREFIX"]) / "bin" / "Rscript"

    with tempfile.TemporaryDirectory() as directory:
        output = Path(directory) / "samples.csv"

        subprocess.run(
            [
                str(rscript),
                "-e",
                r_code,
                str(RASTER),
                str(code),
                str(count),
                str(output),
            ],
            check=True,
        )

        with output.open(newline="") as stream:
            return list(csv.DictReader(stream))


def query_wms(x, y):
    params = {
        "SERVICE": "WMS",
        "VERSION": "1.3.0",
        "REQUEST": "GetFeatureInfo",
        "LAYERS": "fpb100m2026",
        "QUERY_LAYERS": "fpb100m2026",
        "STYLES": "default",
        "CRS": "EPSG:3978",
        "BBOX": f"{x-150},{y-150},{x+150},{y+150}",
        "WIDTH": 101,
        "HEIGHT": 101,
        "I": 50,
        "J": 50,
        "FORMAT": "image/png",
        "INFO_FORMAT": "text/html",
    }

    url = WMS + "?" + urlencode(params)

    with urlopen(url, timeout=30) as response:
        html = response.read().decode("utf-8", errors="replace")

    parser = TableCells()
    parser.feed(html)

    if len(parser.cells) < 2 or parser.cells[0] != "Fuel Types":
        raise ValueError("WMS response contained no fuel-type description")

    return parser.cells[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("code", type=int)
    parser.add_argument("--samples", type=int, default=4)
    args = parser.parse_args()

    if args.samples < 1:
        parser.error("--samples must be positive")

    samples = sample_cells(args.code, args.samples)

    print(f"\n=== FBP code {args.code} WMS verification ===")

    responses = []

    for index, sample in enumerate(samples, 1):
        x = float(sample["x"])
        y = float(sample["y"])

        try:
            classification = query_wms(x, y)
            responses.append(classification)

            print(
                f"{index}: ({x:.2f}, {y:.2f}) -> "
                f"{classification}"
            )

        except Exception as exc:
            print(f"{index}: QUERY FAILED: {exc}")

    print(f"\nSuccessful queries: {len(responses)}/{len(samples)}")

    if responses and len(set(responses)) == 1:
        print("Consistent returned classification:", responses[0])
    elif responses:
        print("WARNING: Different classifications returned")

    print("WMS sampling inspection: COMPLETE")


if __name__ == "__main__":
    main()
