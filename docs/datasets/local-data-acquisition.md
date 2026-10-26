# Local Data Acquisition Record

**Date:** 2026-10-26  
**Study:** Westwood Hills / Upper Tantallon, Nova Scotia  
**Status:** Local copies verified; original distribution provenance partially unresolved

## Acquisition

Three existing datasets were copied from the earlier
`WFCC_2026/EXP100/fireexposuR_learning/data` workspace
into this repository.

Original files were retained unchanged.

All 16 copied files were compared against their originals
using SHA-256 checksums. Every comparison passed.

File paths, byte sizes, and individual checksums are recorded in:

`docs/datasets/local-data-manifest.csv`

The manifest can be regenerated using:

`python3 scripts/create_data_manifest.py`

## Federal fuel raster

Local path:

`data/raw/fbp-2026-candidate/fss.tiff`

Verified characteristics:

- Format: GeoTIFF
- Resolution: 100 m
- CRS: NAD83 / Canada Atlas Lambert (EPSG:3978)
- Dimensions: 35,730 rows × 53,520 columns
- Embedded description identifies production on May 5, 2026
- Reported values range from 1 to 675

The raster is provisionally identified as a 2026
federal FBP fuel-type representation.

Its exact distribution edition, original download
URL, classification dictionary, and source evidence
still require verification.

The filename and production date alone do not
establish complete product provenance.

## Provincial forest inventories

Local paths:

- `data/raw/ns-forest-inventory/halifax-west/`
- `data/raw/ns-forest-inventory/halifax-east/`

Verified characteristics:

| Property | Halifax West | Halifax East |
|---|---:|---:|
| Polygon features | 69,794 | 50,270 |
| Attribute fields | 49 | 54 |
| CRS | EPSG:2961 | EPSG:2961 |

Both datasets contain interpreted forest attributes
including species, crown closure, and `PHOTOYR`.

The complete shapefile bundles and accompanying
metadata were preserved.

The two inventories have different attribute schemas.
They must not be merged without examining those differences.

Original acquisition dates, distribution editions,
polygon observation dates, and complete study-area
coverage remain to be verified.

## Data handling

Raw files are stored under `data/raw/`, which is
excluded from Git.

Derived study-area datasets will be stored separately
under `data/processed/`.

Original source rasters and polygons will not be
modified during processing.

## Interpretation limits

Successful checksum verification establishes that
local copies match the files in the earlier workspace.

It does not independently establish the identity,
currency, accuracy, or completeness of the source products.

The federal and provincial datasets must not be
assumed to describe identical observation periods
or use equivalent landscape classification systems.
