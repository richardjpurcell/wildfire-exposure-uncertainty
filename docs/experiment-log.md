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

## E04 — Two-dimensional threshold stability

**Date:** 2026-10-25
**Status:** Completed
**Type:** Synthetic methodology experiment

### Research question

How do exposure and directional viability thresholds
affect classifications when the underlying exposure
surface remains fixed?

### Experimental setup

Script:
- `scripts/e04_threshold_stability.R`

Supporting function:
- `R/directional_support.R`

Landscape:
- Synthetic radial exposure gradient
- Extent: 20 x 20 km
- Resolution: 100 m
- CRS: EPSG:3978
- Reference point: (10000, 10000)
- Exposure decreases with distance from the centre
- Exposure values bounded between 0.20 and 0.90

Threshold grid:
- Exposure threshold Te: 0.40 to 0.80, step 0.05
- Viability threshold Tv: 0.60 to 0.95, step 0.05
- Total threshold combinations: 72

Directional configuration:
- 36 bearings at 10-degree intervals
- Three consecutive 2 km segments per bearing
- Total directional segments: 108

### Verification

All 72 threshold combinations executed successfully.

The reconstructed classifications agreed with
fire_exp_dir() for all 7776 comparisons.

Each directional segment was evaluated under
exactly 72 threshold combinations.

The segment-level viable fraction was independently
verified against the integer count of viable outcomes.

### Threshold-grid viable fraction

For directional segment s:

S(s) = number of viable threshold combinations / 72

This quantity describes classification behaviour over
the selected threshold grid.

It is not a probability of correctness, a confidence
level, or an operational safety measure.

### Results

| Segment | Viable combinations | Mean viable fraction |
|---|---|---:|
| seg1 | 59-60 of 72 | 0.82870 |
| seg2 | 27-28 of 72 | 0.38310 |
| seg3 | 0 of 72 | 0.00000 |

At Te = 0.50, changing Tv from 0.70 to 0.80
did not change the number of viable segments.

At Te = 0.75, increasing Tv from 0.70 to 0.80
reduced the number of viable segments from
36 to zero.

At Te = 0.80, all 108 segments were nonviable
for every tested viability threshold.

### Interpretation

With the synthetic exposure surface held constant,
changing analytical thresholds altered directional
viability classifications.

The inner directional segments remained viable
under most tested threshold combinations.

Middle segments were substantially more dependent
on the selected thresholds.

Outer segments remained nonviable throughout the
tested threshold grid.

This is consistency within a defined analytical
parameter space, not evidence of environmental
certainty or operational safety.

Variation between segment groups was greater than
variation among bearings within each group, as
expected from the radial synthetic representation.

### Limitations

- Entirely synthetic exposure landscape
- Radially symmetric exposure gradient
- Results depend on the chosen threshold ranges
  and sampling increments
- Threshold combinations are not assigned
  evidence-based probabilities or weights
- No real fuel-map comparison
- No independent assessment of predictive accuracy
- Missing exposure evidence not explicitly modelled
- No operational safety interpretation

### Next experiment

Investigate a heterogeneous synthetic exposure
surface to test whether the threshold-grid viable
fraction reveals stronger directional variation.

Before using real landscape data, develop an
explicit treatment of missing exposure evidence.

## E05 — Directional stability under heterogeneous exposure

**Date:** 2026-10-25
**Status:** Completed
**Type:** Synthetic methodology experiment

### Research question

Can the threshold-grid viable fraction distinguish
directions with different exposure representations
at the same distance from the reference point?

### Experimental setup

Script:
- `scripts/e05_heterogeneous_exposure.R`

Supporting function:
- `R/directional_support.R`

Landscape:
- Synthetic 20 x 20 km exposure raster
- Resolution: 100 m
- CRS: EPSG:3978
- Reference point: (10000, 10000)
- E04 radial exposure gradient as baseline
- Exposure increment of 0.10 in the eastern half
- Exposure values clamped to [0.20, 0.90]

Threshold grid:
- Exposure threshold Te: 0.40 to 0.80, step 0.05
- Viability threshold Tv: 0.60 to 0.95, step 0.05
- 72 threshold combinations

Directional configuration:
- 36 bearings at 10-degree intervals
- Three consecutive 2 km segments per bearing
- 108 directional segments

### Exposure surface verification

At sample points approximately 3 km east and west
of the reference point:

- Eastern exposure: 0.694959
- Western exposure: 0.604958
- Difference: +0.090001

The measured difference is slightly below the
nominal eastern increment of 0.10 because the
sampled raster cell centres are not at identical
distances from the reference point.

### Initial directional comparison

At Te = 0.60 and Tv = 0.80:

| Segment | East support | West support |
|---|---:|---:|
| seg1 | 1.00000 | 1.00000 |
| seg2 | 1.00000 | 0.50053 |
| seg3 | 0.00071 | 0.00000 |

The eastern middle segment was viable; the western
middle segment was nonviable.

Across all bearings:
- seg1: 36 viable, 0 nonviable
- seg2: 18 viable, 18 nonviable
- seg3: 0 viable, 36 nonviable

### Threshold-grid viable fractions

| Segment | Minimum | Mean | Maximum |
|---|---:|---:|---:|
| seg1 | 0.81944 | 0.91435 | 1.00000 |
| seg2 | 0.37500 | 0.49421 | 0.61111 |
| seg3 | 0.00000 | 0.08025 | 0.16667 |

For middle segments at selected bearings:

- East (90 degrees): viable in 44 of 72 combinations
- West (270 degrees): viable in 28 of 72 combinations

### Paired threshold comparison

Across the 72 paired threshold combinations:

| Paired outcome | Combinations |
|---|---:|
| East viable, west nonviable | 16 |
| West viable, east nonviable | 0 |
| Same classification | 56 |

The eastern middle segment's continuous support
was never lower than the western segment's support
in the paired comparisons.

This verifies a consistent directional ordering
for the selected bearings and threshold grid.

### Verification

For each threshold combination, the reconstructed
classifications agreed with fire_exp_dir() for
all 108 segments.

A total of 7776 reconstructed classifications
were checked across the 72 combinations.

The paired east-west consistency assertions passed.

### Interpretation

The heterogeneous synthetic exposure surface
produced differences in directional support,
binary classifications, and threshold-grid
viable fractions.

The selected eastern middle segment remained
viable under more threshold combinations than
its western counterpart.

The paired comparison showed that this difference
was consistently ordered across the tested grid,
rather than reflecting opposing classification
patterns at different parameter combinations.

These findings establish properties of the
controlled synthetic assessment workflow.

They do not establish wildfire exposure,
environmental uncertainty, or operational
safety at a real location.

### Limitations

- Fully synthetic exposure representation
- Deliberately imposed east-west asymmetry
- Abrupt exposure increment at the dividing line
- Fixed raster resolution and alignment
- Results depend on the selected threshold grid
- Threshold combinations have no probability weights
- No real fuel-map observations or comparisons
- Missing exposure evidence not explicitly modelled
- No independent assessment of predictive accuracy

### Next steps

Develop visual representations that distinguish:

1. Directional classification at selected thresholds
2. Continuous support and distance from thresholds
3. Threshold-grid viable fractions
4. Where paired conclusions disagree

Before extending these methods to real landscape
evidence, explicitly address missing exposure
values and differences in data provenance.

## E06 — Missing evidence and directional coverage

**Date:** 2026-10-25
**Status:** Completed
**Type:** Synthetic methodology experiment

### Research question

Can directional classifications distinguish measured
low exposure from unavailable exposure evidence?

Can evidence coverage be measured independently
of the directional viability classification?

### Experimental setup

Script:
- `scripts/e06_missing_evidence.R`

Supporting function:
- `R/directional_coverage.R`

Landscape:
- Synthetic 20 x 20 km raster
- Resolution: 100 m
- CRS: EPSG:3978
- Reference point: (10000, 10000)

Directional parameters:
- 36 bearings at 10-degree intervals
- Three consecutive 2 km segments per bearing
- Exposure threshold: 0.60
- Viability threshold: 0.80

### Package behaviour

Three uniform-raster scenarios were initially tested.

Measured-low exposure (0.40):
- All 40000 raster cells contained valid values.
- fire_exp_dir() returned an error:
  no applicable method for 'mutate' applied to
  an object of class "SpatVector".

Measured-high exposure (0.75):
- All 40000 raster cells contained valid values.
- All 108 directional segments were viable.

Entirely missing exposure:
- All 40000 cells contained NA.
- fire_exp_dir() returned an error stating that
  exposure values must be between 0 and 1.

These errors are observed behaviour of the
installed package and dependency versions.
They are not valid directional classifications.

### Partial missing-data scenario

A raster containing high exposure (0.75) in the
eastern half and missing values in the western
half produced:

- Available raster cells: 20000 of 40000
- Viable directional segments: 54
- Nonviable directional segments: 54

At 90 degrees, all three segments were viable.
At 270 degrees, all three segments were nonviable.

### Paired evidence comparison

Two landscapes were compared:

Scenario A:
- Western exposure: 0.40
- Eastern exposure: 0.75

Scenario B:
- Western exposure: NA
- Eastern exposure: 0.75

The directional viability classifications agreed
for all 108 segments.

At 270 degrees, all three western segments were
nonviable in both scenarios despite their
different evidence conditions.

### Directional evidence coverage

Evidence coverage was defined as:

C = observed segment length / total segment length

Observed length was measured by intersecting
directional segments with raster cells containing
nonmissing exposure values.

At the selected bearings:

| Bearing | Measured scenario | Missing scenario |
|---|---:|---:|
| 90 degrees | 1.00 | 1.00 |
| 270 degrees | 1.00 | 0.00 |

These coverage results applied to all three
segments at each selected bearing.

The identical viability classifications therefore
concealed different evidence completeness.

### Intermediate coverage test

A 1 km-wide strip of missing exposure values
was introduced west of the reference point.

Measured coverage:

| Direction and segment | Coverage |
|---|---:|
| East 90 degrees, seg1 | 1.00000 |
| East 90 degrees, seg2 | 1.00000 |
| East 90 degrees, seg3 | 1.00000 |
| West 270 degrees, seg1 | 0.49982 |
| West 270 degrees, seg2 | 1.00000 |
| West 270 degrees, seg3 | 1.00000 |

The western first-segment result is consistent
with the expected partial intersection of
the missing-data strip.

### Interpretation

Binary directional classifications alone do not
reveal whether the underlying exposure evidence
is complete, incomplete, or absent.

Evidence coverage provides an independent
measurement of the spatial availability of
exposure values along directional segments.

It should remain separate from continuous
high-exposure support and threshold-grid
viability fractions.

### Limitations

- Fully synthetic exposure representations
- Controlled missing-data geometry
- Package errors observed for two uniform cases
- Coverage tested at selected directions
- No independent geometric accuracy validation
- Nonmissing values treated as available evidence
- Evidence age, quality, classification validity,
  and provenance not evaluated
- No real wildfire exposure observations
- No operational safety interpretation

### Next steps

Develop an assessment representation that
communicates three separate properties:

1. Continuous high-exposure support
2. Threshold-dependent classification behaviour
3. Evidence coverage

Before applying the workflow to Westwood Hills,
examine missing-data handling and evidence
provenance in the federal and provincial
landscape datasets.

## E06 extension — Integrated directional assessment

**Date:** 2026-10-25
**Status:** Completed
**Type:** Synthetic methodology integration

### Objective

Combine continuous directional high-exposure support
and evidence coverage without changing the existing
package-compatible viability calculation.

### Implementation

Reusable functions:

- `R/directional_support.R`
- `R/directional_coverage.R`
- `R/directional_assessment.R`

Validation script:

- `scripts/test_directional_assessment.R`

The integrated function reports:

1. High-exposure support over total segment length
2. Evidence coverage over total segment length
3. High-exposure support among observed evidence
4. Reconstructed package-compatible viability
5. Evidence status: complete, partial, or missing

Observed-only support is undefined (NA) when
evidence coverage is zero.

### Verified results

For the first western segment (270 degrees, seg1):

| Scenario | Total support | Coverage | Observed support | Viable |
|---|---:|---:|---:|---:|
| Measured low | 0.00000 | 1.00000 | 0.00000 | 0 |
| Missing west | 0.00000 | 0.00000 | NA | 0 |
| Partial high | 0.49982 | 0.49982 | 1.00000 | 0 |

All three scenarios produced the same reconstructed
binary viability classification, despite having
different evidence conditions.

### Interpretation

A nonviable classification does not establish
that complete measurements indicate low exposure.

Total-length support and observed-only support
answer different questions and must not be
substituted for one another.

Evidence coverage supplies additional context
needed to interpret the directional classification.

### Limitations

- Validation uses controlled synthetic landscapes.
- Package-compatible viability remains based on
  total-length high-exposure support.
- Coverage reflects the presence of raster values,
  not their accuracy, age, or provenance.
- No minimum evidence-coverage requirement has
  been imposed for interpreting viability.
- No real landscape assessment has been performed.

### Next step

Develop a paired presentation of exposure results
and their supporting evidence conditions.

Keep threshold sensitivity and evidence coverage
separate rather than combining them into a single
uncertainty score.

## E05 extension — Paired directional visualizations

**Date:** 2026-10-25
**Status:** Completed
**Type:** Synthetic methodology visualization

### Objective

Develop two complementary directional diagrams
that distinguish a baseline exposure assessment
from its sensitivity to analytical thresholds.

### Reproducible outputs

Source data:
- `outputs/e05_directional_assessment.csv`

Plotting scripts:
- `scripts/plot_e05_exposure_assessment.R`
- `scripts/plot_e05_threshold_stability.R`

Figures:
- `outputs/figures/e05_exposure_assessment.png`
- `outputs/figures/e05_threshold_stability.png`

Both figures represent 36 bearings and three
consecutive 2 km directional segments.

### Figure A — Baseline exposure

Fill colour represents continuous high-exposure
support at Te = 0.60.

Dark segment borders indicate baseline viability
at Tv = 0.80.

The baseline assessment contains:
- 108 directional segments
- 54 viable
- 54 nonviable
- Mean high-exposure support: 0.58297

### Figure B — Threshold stability

Fill colour represents the fraction of 72
threshold combinations producing a viable
classification for each directional segment.

Unlike Figure A, this figure does not repeat
the baseline viability border encoding.

The mean threshold-grid viable fraction across
all 108 segments is 0.49627.

### Interpretation

The paired figures distinguish what the assessment
indicates at selected thresholds from how frequently
those classifications persist across the tested
threshold grid.

The figures preserve directional relationships
and distance segments.

They are directional assessment diagrams, not
geographic maps of actual wildfire conditions.

### Limitations

- Entirely synthetic heterogeneous exposure surface
- Complete evidence coverage in the E05 landscape
- No indication of missing or outdated observations
- Threshold-grid fractions are not probabilities
  of correctness or operational safety
- Raster resolution and alignment remain fixed
- No real landscape results are represented

### Next step

Create a comparable evidence-coverage view using
a controlled incomplete-evidence representation.

Evaluate whether the exposure, threshold-sensitivity,
and evidence-coverage views communicate distinct
information without requiring a combined score.

## E06 extension — Evidence-coverage visualization

**Date:** 2026-10-26
**Status:** Completed
**Type:** Synthetic methodology visualization

### Objective

Demonstrate that identical directional viability
classifications can conceal differences in the
availability of supporting exposure measurements.

### Reproducible outputs

Source data:
- `outputs/e06_coverage_comparison.csv`

Scripts:
- `scripts/export_e06_coverage_comparison.R`
- `scripts/plot_e06_evidence_coverage.R`

Figure:
- `outputs/figures/e06_evidence_coverage.png`

### Experimental comparison

Two synthetic exposure representations were assessed:

1. Measured low exposure in the western half,
   with high exposure in the eastern half.
2. Missing exposure measurements in the western
   half, with the same high exposure in the east.

The directional viability classifications agreed
for all 108 corresponding segments.

### Evidence-coverage results

The comparison dataset contains 216 records:
108 directional segments per scenario.

Mean evidence coverage:

| Scenario | Mean coverage |
|---|---:|
| Measured low exposure | 1.00 |
| Missing western evidence | 0.50 |

The measured scenario has complete evidence
coverage in every direction.

The missing-evidence scenario has complete
coverage in the east and no coverage in the west.

### Visualization

The paired directional diagrams use identical
geometry, distance segments, and colour scales.

Fill colour represents the fraction of each
directional segment containing nonmissing
exposure measurements.

The figure intentionally omits viability borders
to isolate evidence completeness.

### Interpretation

The two assessments produce identical binary
directional classifications despite different
evidence conditions.

The evidence-coverage visualization reveals
that difference directly.

This supports communicating evidence availability
separately from exposure support and threshold
sensitivity.

### Limitations

- Entirely synthetic exposure representations
- Deliberately imposed missing-data boundary
- No partial coverage within individual segments
  in this visualization
- Coverage describes availability, not accuracy
- No real wildfire exposure observations
- No operational safety interpretation

### Next step

Evaluate a combined presentation containing:

1. Baseline directional exposure
2. Threshold-grid viability
3. Directional evidence coverage

Assess whether the three views remain independently
interpretable and whether their differences
help identify where further evidence is needed.

## E07 — Integrated exposure, threshold viability, and evidence coverage

**Date:** 2026-10-26
**Status:** Completed
**Type:** Synthetic methodology demonstration

### Objective

Evaluate three complementary properties of a directional wildfire
exposure assessment using the same underlying synthetic landscape:

1. Baseline high-exposure support and viability classification.
2. Viable fraction across a grid of analytical thresholds.
3. Spatial availability of supporting exposure measurements.

### Experimental configuration

- Raster: 200 × 200 cells, 100 m resolution
- Coordinate reference system: EPSG:3978
- Reference point: (10000, 10000)
- Directional grid: 36 bearings at 10-degree intervals
- Distance segments: three consecutive 2 km segments
- Total directional segments: 108

The exposure surface combines a radial gradient with an additional
0.10 exposure increment in the eastern half.

A 4 × 4 km southwest region is assigned missing exposure values.

The raster contains 38,400 available cells and 1,600 missing cells,
corresponding to 96% overall spatial coverage.

### Baseline assessment

The baseline uses:

- Exposure threshold: 0.60
- Viability threshold: 0.80

Results:

- Baseline viable segments: 45
- Baseline nonviable segments: 63
- Complete evidence segments: 81
- Missing evidence segments: 18
- Partially covered segments: 9
- Mean directional evidence coverage: approximately 0.8133

The difference between 96% raster coverage and 81.33% mean
directional coverage illustrates the importance of assessing
evidence availability along the actual observation geometry.

### Threshold-grid assessment

Exposure thresholds: 0.40 to 0.80 in increments of 0.05.

Viability thresholds: 0.60 to 0.95 in increments of 0.05.

The grid contains 72 parameter combinations and produces
7,776 directional classifications.

Every reconstructed classification agreed with the corresponding
fire_exp_dir() result.

Mean viable fraction by distance segment:

| Segment | Mean viable fraction |
|---|---:|
| 0–2 km | 0.707176 |
| 2–4 km | 0.398534 |
| 4–6 km | 0.080247 |

Mean viable fraction by evidence status:

| Evidence status | Mean viable fraction |
|---|---:|
| Complete | 0.52709 |
| Missing | 0 |
| Partial | 0 |

All 27 missing or partially observed segments were classified
nonviable across the 72 threshold combinations.

### Numerical boundary handling

Nine first-segment transects contained negligible positive
intersection lengths arising at the missing-data boundary.

Their observed lengths ranged from approximately 2.93e-9 m
to 1.37e-6 m.

A coverage tolerance of 1e-8 prevents these negligible
intersections from producing misleading observed-only support
ratios.

Raw lengths, coverage fractions, and package-compatible viability
classifications remain unchanged.

This tolerance addresses numerical geometry artifacts.
It is not an evidence-sufficiency threshold.

### Partial evidence

Nine third-segment transects had partial evidence coverage.

Their missing lengths ranged from approximately 1.41 m
to 1,230.89 m.

These partial classifications are retained rather than
reclassified using an arbitrary minimum coverage requirement.

### Integrated visualization

The three-panel figure presents:

A. Baseline high-exposure support, with black outlines marking
   segments classified viable at the baseline thresholds.

B. Fraction of the 72 threshold settings yielding a viable
   classification.

C. Fraction of each segment with available exposure measurements.

All three panels use identical directional geometry.

### Main finding

Consistency across analytical thresholds does not necessarily
establish that a directional classification is well supported
by available evidence.

Segments with incomplete or missing observations can remain
consistently nonviable because the assessment does not identify
high-exposure intersections in the unavailable portions.

The result motivates communicating exposure support,
threshold-grid viability, and evidence completeness separately.

### Interpretation limits

- Results arise from a deliberately constructed synthetic landscape.
- Missing evidence must not be interpreted as observed low exposure.
- Viable fraction is sensitivity to the selected threshold grid,
  not a probability of safety, correctness, or actual exposure.
- Evidence coverage measures availability, not accuracy.
- The experiment does not establish operational safety or
  real wildfire exposure conditions.
- Numerical boundary tolerance is distinct from any future
  evidence-sufficiency policy.

### Reproducible artifacts

Scripts:
- `scripts/e07_integrated_landscape.R`
- `scripts/plot_e07_integrated.R`

Dataset:
- `outputs/e07_integrated_directional_assessment.csv`

Figure:
- `outputs/figures/e07_integrated_three_views.png`

### Next step

Use the validated synthetic methodology as a reference when
examining the available federal FBP fuel maps from 2019,
2024, and 2026 and the Nova Scotia provincial forest inventory.

Document differences in provenance, spatial coverage,
classification, and resolution before drawing conclusions
from cross-dataset comparisons.

## 2026-10-26 — 2026 FBP fuel-code interpretation

### Objective

Establish the meanings of all numerical classifications
present in the local 2026 FBP candidate raster before using
it in exposure and uncertainty assessments.

### Study data

The study window contains 40,000 cells at 100 m resolution.

The numerical-code inventory is recorded in:

- `outputs/d02_fbp_2026_code_counts.csv`
- `docs/datasets/fbp-2026-code-register.csv`

### Verification procedure

Numerical values were read from the local GeoTIFF.

Selected cell-centre coordinates were submitted to the
official 2026 100 m FBP Web Map Service using WMS
GetFeatureInfo with an HTML response.

Service:
`https://ca.nfis.org/mapserver/cgi-bin/fbp_eng.cgi`

Layer:
`fpb100m2026`

Reproducible verification script:
`scripts/verify_fbp_2026_wms.py`

For nine numerical codes, four sampled locations returned
consistent classifications.

Code 1 occurred in only one cell, so its classification
was verified at that single location.

Codes 11 and 13 retain their catalogue-supported
interpretations.

### Results

All 12 observed numerical codes now have documented meanings.

Verification coverage:

| Verification basis | Codes | Cells | Study-area share |
|---|---|---:|---:|
| Four WMS samples per code | 2, 3, 4, 31, 101, 102, 625, 650, 675 | 35,617 | 89.0425% |
| Catalogue interpretation | 11, 13 | 4,382 | 10.9550% |
| Single WMS sample | 1 | 1 | 0.0025% |
| Total | 12 observed codes | 40,000 | 100% |

Mixedwood classifications include separate 25%, 50%,
and 75% conifer categories.

The raster also distinguishes Non-fuel (101),
Water (102), and vegetation without an effective
FBP classification match (13).

### Interpretation

The numerical vocabulary of the local 2026 raster
is now fully interpreted.

This resolves uncertainty about what the observed
numerical values represent in the map product.

It does not resolve uncertainty about whether the
underlying classifications accurately describe
current landscape conditions.

### Limitations

- WMS comparisons were sampled, not exhaustive.
- Code 1 has only one location-level verification.
- Catalogue-based and WMS-based interpretations
  have different verification provenance.
- Agreement with the WMS is not ground validation.
- Classification labels do not independently establish
  measured species proportions or stand maturity.
- The raster's production date does not establish
  the observation date of every cell.
- No agreement with the 2019, 2024, or Nova Scotia
  provincial classifications has yet been established.
- Full code interpretation does not imply complete
  or sufficient evidence for exposure assessment.

### Next step

Document the spatial and classification relationships
between the interpreted 2026 FBP raster and the
Nova Scotia provincial forest inventory.

Keep unavailable evidence, unclassified vegetation,
non-fuel land, and classified fuels distinct before
constructing empirical exposure scenarios.

## 2026-10-26 — Provincial forest area and raster alignment

### Objective

Validate the spatial area calculations used to align Nova Scotia
provincial forest inventory polygons with the 2026 federal FBP
100 m study grid.

### Study data

- Reference raster: 200 x 200 cells at 100 m nominal resolution.
- Provincial inventory: Halifax West forest polygons.
- Forested land definition: `LNDCLASS = 99`.
- Forested polygons intersecting the study window: 4,810.

### Polygon geometry verification

The sum of individual polygon areas agreed with their geometric
union area to the reported precision, indicating no measurable
overlapping forest-polygon area in the study window.

### Area convention

The reference grid uses EPSG:3978.

Projected-coordinate cell area is approximately 1 hectare,
but geographically corrected area differs because of map
projection distortion.

In `terra`, `expanse(..., transform = TRUE)` calculates
geographically corrected area. Multiplying raster coverage
fractions by projected cell dimensions uses planar grid area.

These measurements must not be directly compared.

### Raster-footprint comparison

The forest polygons were intersected with the exact reference
raster footprint.

| Area convention | Exact geometry (ha) | Fractional raster (ha) | Difference (ha) |
|---|---:|---:|---:|
| Projected-coordinate | 25,173.41 | 25,182.02 | +8.61 |
| Geographically corrected | 24,246.50 | 24,254.77 | +8.27 |

The remaining difference is approximately 0.034% of the
exact area under either convention.

Rasterizing the individual polygons and their dissolved
union produced identical fractional coverage results.

### Interpretation

The initial apparent discrepancy of approximately 887 ha
arose primarily from comparing different area conventions.

Fractional rasterization closely reproduces the geometric
forest area when the measurement convention and spatial
footprint are consistent.

### Limitations

- Fractional raster coverage remains an approximation.
- Coverage is distinct from attribute reliability.
- These results validate forest footprint representation,
  not provincial-to-federal fuel classification agreement.
- Subsequent evidence-category area calculations should
  use a consistent area convention and preserve
  fractional coverage at category boundaries.

### Next step

Construct provincial evidence-status coverage layers on
the federal 100 m grid, distinguishing named species,
explicitly unclassified species, and absent first-story
species descriptions.

Retain clear-cut and other mapped disturbance classifications
rather than treating all absent species descriptions as
missing observations.
