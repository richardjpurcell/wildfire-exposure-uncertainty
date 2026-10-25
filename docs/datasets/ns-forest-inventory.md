# Nova Scotia Provincial Forest Inventory

**Investigation:** D05
**Reviewed:** 2026-10-25
**Status:** Preliminary documentary review

## Purpose

Examine provincial forest composition and land
classification evidence for the Westwood Hills study.

The provincial inventory is not an FBP fuel map.
It provides an alternative description of the
landscape underlying potential fuel classifications.

## Provider and official sources

Provider: Government of Nova Scotia

Forest inventory overview:
https://novascotia.ca/natr/forestry/gis/forest-inventory.asp

County-based downloads:
https://novascotia.ca/natr/forestry/gis/dl_forestry.asp

Attribute descriptions and coding:
https://novascotia.ca/natr/forestry/gis/pdf/forest_metadata_web_attrib.pdf

Photo interpretation:
https://novascotia.ca/natr/forestry/programs/inventory/photo.asp

Government catalogue:
https://open.canada.ca/data/en/dataset/78f1249c-56ec-e97b-848b-494fb6a01bd8

## Data structure and projection

Primary representation: Forest inventory polygons
Download format: ESRI Shapefile
Published projection: NAD83 / UTM Zone 20N
Candidate study-region download: Halifax West

Coverage of the complete Westwood Hills study
boundary has not yet been verified.

## Inventory versions

The province documents multiple interpretation cycles:

- Cycle 1: Photography from 1985-1993.
- Cycle 2: Photography from 1994-2004.
- Current Forest Data: Combination of later
  interpretations and additional updates.

The current data is spatially heterogeneous
in its observation periods.

Its publication or download date must not
be treated as the date of field observation.

## Interpretation methodology

Provincial forest stands are delineated using
aerial photograph interpretation.

Interpreted attributes include:

- Tree species and composition
- Crown closure
- Stand height
- Land and forest classification

Additional stand characteristics can be calculated
from interpreted observations.

These attributes are estimates, not direct
measurements of wildfire fuel behaviour.

## Relevant attributes

The official attribute documentation identifies
species fields and associated proportions,
including SP1-SP4 and SP1P-SP4P.

Land classification and forest/non-forest
attributes are also documented.

Exact coding, missing-value conventions, and
species-percentage scaling must be verified
before analysis.

## Westwood Hills considerations

The 2023 wildfire may have changed vegetation
within part of the study region.

We have not established whether the provincial
inventory polygons covering the burned area
were interpreted before or after that event.

Differences from national FBP classifications
may therefore arise from observation dates,
landscape change, classification rules,
or spatial support.

## Proposed experimental uses

1. Compare forest and non-forest representations.
2. Examine national mixedwood classifications.
3. Estimate provincial softwood composition.
4. Investigate spatial variation within FBP classes.
5. Examine missing or unmatched evidence.
6. Assess sensitivity to alternative experimental
   landscape representations.

Provincial composition estimates must not
automatically be treated as ground truth.

## Outstanding verification

- Exact coverage of the study boundary
- Download edition and acquisition date
- Polygon-level observation or update dates
- Availability of historical inventory versions
- Species-code definitions and proportion scaling
- Land-class and missing-data codes
- Treatment of the 2023 burned area
- CRS and geometry validation
- Relationship to federal source inventories
- Appropriate comparison spatial support

## Research implications

The provincial inventory provides useful
independent institutional evidence, but it
may share underlying observations or methods
with national forest products.

It is not necessarily statistically independent
of federal fuel-map source information.

Our investigation should distinguish evidence
availability, estimated composition, land
classification, and experimental fuel assumptions.

No new Westwood Hills numerical results
have been produced in D05.
