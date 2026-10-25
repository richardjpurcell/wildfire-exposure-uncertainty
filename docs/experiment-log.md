# Experiment Log

## Purpose

This log records the development of the wildfire exposure uncertainty investigation, including technical work, experimental decisions, observations, results, and unresolved questions.

Entries distinguish completed work from planned activities. Numerical findings must be traceable to their source data, parameters, and analysis scripts.

## Entry conventions

Each experimental entry should document:

- **Identifier and date:** Unique experiment number (E01, E02, etc.) and execution date.
- **Question:** What are we investigating, and why?
- **Evidence:** Datasets, versions, and geographic coverage.
- **Method:** Parameters, calculations, and scripts.
- **Observations:** Directly measured or computed results.
- **Interpretation:** What the observations suggest.
- **Limitations:** What the experiment does not establish.
- **Next step:** Questions or experiments arising from the findings.

Not every entry requires all fields. Repository setup and other administrative steps may be recorded more briefly.

---

## 2026-10-25 — Project initialization

**Status:** Completed

### Objective

Establish a reproducible local Git repository and corresponding GitHub repository for investigating uncertainty in wildfire exposure assessments.

### Completed

- Selected repository name: `wildfire-exposure-uncertainty`.
- Created Conda environment `wildfire-exposure`.
- Installed and verified R 4.4.3 on macOS Apple Silicon.
- Initialized local Git repository using branch `main`.
- Established the initial `.gitignore`.
- Created the root README describing the research objective, study region, planned methods, and limitations.

- Created the public GitHub repository `richardjpurcell/wildfire-exposure-uncertainty`.
- Connected the local repository to GitHub using `origin`.
- Verified the initial push of commit `f2c4725` and synchronization of `main` with `origin/main`.
- Created `environment.yml` specifying the initial Conda environment with R 4.4.

### Next activities

- Establish and verify required R packages, including `terra` and `fireexposuR`.
- Inventory the 2019, 2024, and 2026 federal FBP fuel datasets.
- Identify relevant Nova Scotia provincial forest inventory products.
- Document dataset provenance, observation dates, classification definitions, spatial characteristics, and acquisition procedures.

### Research status

No new experimental results have been generated for Westwood Hills.

The first planned research activity is an inventory of the 2019, 2024, and 2026 federal FBP fuel maps and Nova Scotia provincial forest inventory evidence.

The inventory will establish source documentation, geographic coverage, classification definitions, resolution, projection, provenance, and relevant observation dates before comparative analyses begin.

## 2026-10-25 — Synthetic exposure functionality tests

**Status:** Completed
**Type:** Software verification
**Environment:** Conda R 4.4.3, fireexposuR 1.2.0

### Objective

Verify that continuous and directional exposure
functions execute successfully using controlled
synthetic inputs.

These tests do not validate wildfire behaviour
or establish results for Westwood Hills.

### Test 1 — Continuous exposure

Script: `scripts/test_fire_exp.R`

Input:
- 51 x 51 synthetic hazard raster
- 100 m resolution
- 25 hazardous cells in a central 5 x 5 patch
- Transmission distance: 500 m

Results:
- Output raster: 51 x 51 cells
- Valid exposure cells: 1,681
- Missing exposure cells: 920
- Minimum exposure: 0.0000
- Maximum exposure: 0.3000
- Mean exposure: 0.0148721

The output passed checks for dimensions,
finite values, and the expected 0-1 range.

The cause and spatial distribution of missing
cells have not been independently verified.

### Test 2 — Directional exposure

Script: `scripts/test_fire_exp_dir.R`

Input:
- Uniform synthetic exposure raster
- Extent: 20 x 20 km
- Resolution: 100 m
- Bearings: 10-degree intervals
- Segments: three of 2 km each
- Exposure threshold: 0.60
- Viability threshold: 0.80

Results:

| Exposure | Viable | Nonviable |
|---|---:|---:|
| 0.75 | 108 | 0 |
| 0.40 | 0 | 108 |

Both cases produced 108 directional features,
with 36 features in each segment group.

All automated structural and classification
assertions passed.

### Interpretation

The installed software executes the two principal
calculations needed for our experimental workflow.

The directional function returns binary
classification results.

Continuous segment-level measurements will need
to be reconstructed separately for the proposed
threshold-stability investigation.

### Limitations

- Synthetic inputs only.
- No independent numerical reference calculation.
- No real landscape data.
- No validation of predictive performance.
- No uncertainty calibration.

### Next experiment

Investigate directional classification transitions
using spatially varying synthetic exposure.

Measure continuous high-exposure proportions and
decision margins before exploring the full
two-dimensional threshold space.

## E01 — Directional exposure across a synthetic boundary

**Date:** 2026-10-25
**Status:** Completed
**Type:** Synthetic methodology experiment

### Research question

Can we reconstruct the continuous high-exposure
support underlying the binary directional
classifications returned by fire_exp_dir()?

### Experimental setup

Scripts:
- `scripts/e01_directional_transition.R`
- `R/directional_support.R`

Landscape:
- Synthetic exposure raster, 20 x 20 km
- Resolution: 100 m
- CRS: EPSG:3978
- Western exposure: 0.40
- Eastern exposure: 0.75
- Reference point: (10000, 10000)

Directional parameters:
- 36 bearings, 10-degree intervals
- Three segments of 2 km per bearing
- Exposure threshold: 0.60
- Viability threshold: 0.80

### Original classifications

The directional calculation returned 108 segments.

- 54 viable
- 54 nonviable
- 18 viable and 18 nonviable in each segment group

Bearings 10-180 degrees were viable.
Bearings 190-360 degrees were nonviable.

### Continuous reconstruction

The reconstructed measurement was:

P = high-exposure intersection length /
    complete segment length

The decision margin was:

M = P - viability threshold

Applying the viability threshold to the
reconstructed values reproduced all 108
fire_exp_dir() classifications.

Selected measurements:

| Bearing | Support P | Margin M | Viable |
|---|---:|---:|---:|
| 90 | 1.00 | +0.20 | 1 |
| 180 | 1.00 | +0.20 | 1 |
| 270 | 0.00 | -0.80 | 0 |
| 360 | 0.00 | -0.80 | 0 |

All three segments at each selected bearing
had the same support and classification.

### Interpretation

The reconstruction agrees with the original
directional classifications in this controlled test.

The result establishes implementation consistency,
not independent validation of the exposure method.

The imposed exposure boundary produced support
fractions of either zero or one.

Consequently, this experiment did not establish
gradual decision-margin sensitivity.

### Limitations

- Artificial exposure values and boundary
- No landscape evidence or fuel classification
- No independent validation of numerical accuracy
- Missing exposure evidence not explicitly modelled
- No calibrated uncertainty or safety interpretation

### Next experiment

E02 will introduce partial intersections between
directional segments and high-exposure regions.

The objective is to produce intermediate continuous
support fractions and examine how decision margins
can change without altering binary classifications.

## E02 — Partial directional support and classification stability

**Date:** 2026-10-25
**Status:** Completed
**Type:** Synthetic methodology experiment

### Research question

Can continuous directional exposure support change
without changing the binary viability classification?

### Experimental setup

Script:
- `scripts/e02_partial_support.R`

Supporting function:
- `R/directional_support.R`

Landscape:
- Synthetic exposure raster, 20 x 20 km
- Resolution: 100 m
- CRS: EPSG:3978
- Exposure inside circular region: 0.75
- Exposure outside circular region: 0.40
- Reference point: (10000, 10000)

Scenarios:
- A: high-exposure radius 3500 m
- B: high-exposure radius 3550 m

Directional parameters:
- 36 bearings at 10-degree intervals
- Three consecutive 2 km segments per bearing
- Exposure threshold: 0.60
- Viability threshold: 0.80

All other parameters were held constant.

### Baseline results

At a radius of 3500 m:

| Segment | Mean support | Viable | Nonviable |
|---|---:|---:|---:|
| seg1 | 1.00000 | 36 | 0 |
| seg2 | 0.74797 | 0 | 36 |
| seg3 | 0.00000 | 0 | 36 |

The middle-segment support ranged from
0.72739 to 0.76642.

The reconstructed classifications agreed
with fire_exp_dir() for all 108 segments.

### Scenario comparison

Increasing the radius by 50 m produced:

- Mean seg2 support change: +0.02266
- Maximum seg2 support change: +0.05784
- Minimum seg2 support change: 0
- No support changes in seg1 or seg3
- Binary classification changes: 0 of 108

The reconstructed classifications agreed
with fire_exp_dir() in both scenarios.

### Illustrative segment

At bearing 60 degrees, segment 2:

| Measurement | Scenario A | Scenario B |
|---|---:|---:|
| Support | 0.73505 | 0.79289 |
| Decision margin | -0.06495 | -0.00711 |
| Viable | 0 | 0 |

The segment approached the viability threshold
without crossing it.

### Interpretation

This experiment demonstrates that continuous
directional support and decision margins can
change while binary viability classifications
remain unchanged.

The binary result alone therefore does not
communicate the observed numerical sensitivity.

Support changes differed by bearing even though
the underlying region was nominally circular.
The rasterized boundary is a plausible contributor,
but its effects have not yet been isolated.

Decision margins are distances from an operational
threshold, not uncertainty probabilities.

### Limitations

- Fully synthetic landscape
- No actual wildfire fuel or exposure data
- No independent accuracy validation
- Missing exposure evidence not explicitly modelled
- Raster discretization effects not yet isolated
- One exposure threshold and one viability threshold

### Next experiment

Extend E02 to larger radius changes to identify
classification transitions and examine their
relationship to the continuous decision margins.

Subsequently, vary exposure and viability thresholds
separately to study conclusion stability across
threshold choices.

## E03 — Directional classification transitions

**Date:** 2026-10-25
**Status:** Completed
**Type:** Synthetic methodology experiment

### Research question

How does an expanding high-exposure region affect
continuous directional support, decision margins,
and the point at which binary classifications change?

### Experimental setup

Script:
- `scripts/e03_classification_transition.R`

Supporting function:
- `R/directional_support.R`

Landscape:
- Synthetic exposure raster, 20 x 20 km
- Resolution: 100 m
- CRS: EPSG:3978
- Exposure inside circular region: 0.75
- Exposure outside circular region: 0.40
- Reference point: (10000, 10000)

Tested high-exposure radii:
- 3550 m
- 3600 m
- 3650 m

Directional parameters:
- 36 bearings at 10-degree intervals
- Three consecutive 2 km segments per bearing
- Exposure threshold: 0.60
- Viability threshold: 0.80

### Middle-segment results

| Radius (m) | Mean support | Mean margin | Viable bearings |
|---|---:|---:|---:|
| 3550 | 0.77063 | -0.02937 | 0 / 36 |
| 3600 | 0.79285 | -0.00715 | 12 / 36 |
| 3650 | 0.81497 | +0.01497 | 32 / 36 |

At 3600 m, the mean support remained below 0.80,
but 12 individual bearings were classified as viable.

This occurs because viability is determined separately
for each directional segment, not by thresholding
the mean across bearings.

### First observed viable radius

Across all 108 directional segments:

| First tested viable radius | Segment count |
|---|---:|
| 3550 m | 36 |
| 3600 m | 12 |
| 3650 m | 20 |
| Not viable by 3650 m | 40 |

The 36 segments already viable at 3550 m were
inner segments.

Of the 40 segments remaining nonviable at 3650 m,
36 were outer segments and four were middle segments.

These are first observed viable radii among the
three tested values, not exact transition locations.

### Selected directional examples

At bearing 90 degrees, middle-segment support
increased from 0.75062 at 3550 m to 0.80063
at 3600 m, crossing the viability threshold.

At bearing 60 degrees, middle-segment support
was 0.79289 at 3550 m and 0.79345 at 3650 m.
It remained nonviable throughout the tested range.

### Verification

The continuous reconstruction reproduced all
108 fire_exp_dir() classifications in each
of the three radius scenarios.

Across the 108 segment identities:

- Continuous support was nondecreasing: 108 / 108
- Binary viability was nondecreasing: 108 / 108

### Interpretation

As the synthetic high-exposure region expanded,
continuous directional support increased or
remained unchanged.

Binary viability changed discontinuously when
individual support fractions reached the chosen
viability threshold.

Different bearings crossed that threshold at
different tested radii.

The direction-dependent response is consistent
with effects of raster discretization and spatial
intersection geometry, but the contributions of
those mechanisms have not been isolated.

Together with E02, this experiment distinguishes
changes in numerical support from changes in
the resulting classification.

### Limitations

- Synthetic circular exposure representation
- Only three tested radius values
- Exact classification transition radii unknown
- Raster discretization effects not isolated
- No real wildfire fuel or exposure observations
- Missing exposure evidence not explicitly modelled
- Fixed exposure and viability thresholds
- No operational safety interpretation

### Next experiment

Investigate stability across a two-dimensional
grid of exposure and viability thresholds.

Separate numerical sensitivity, decision margins,
and changes in classification.

Before application to real landscape datasets,
explicitly distinguish missing exposure evidence
from measured low exposure.
