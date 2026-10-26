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

## D03 — Provincial forest evidence-status coverage

### Objective

Represent the availability and classification of provincial
forest-inventory evidence on the same 100 m grid as the
2026 federal FBP study raster.

Preserve mixed evidence within individual grid cells instead
of prematurely assigning one category to an entire cell.

### Study data

- Nova Scotia Halifax West interpreted forest inventory.
- Reference: 2026 FBP candidate raster, 200 x 200 cells.
- Study window: Westwood Hills / Upper Tantallon.
- Provincial forested land: `LNDCLASS = 99`.
- Intersecting forested polygon records: 4,810.

### Evidence categories

Three principal categories are defined from the provincial
species-description fields:

1. Named species composition.
2. Explicitly unclassified species (`SPECIES = UC10`).
3. No first-story species description.

A fourth layer identifies records in category 3 that have
the clear-cut classification (`FORNON = 60`).

The clear-cut layer is a subset, not an additional mutually
exclusive forest-coverage category.

### Spatial method

Provincial polygons are clipped to the study boundary,
restricted to the forested land class, and transformed into
the federal raster coordinate system.

Each evidence category is rasterized separately using
`terra::rasterize(..., cover = TRUE)`.

Raster cell values represent approximate fractional coverage
between zero and one.

Geographically corrected cell areas are used when reporting
hectares.

### Results

| Evidence category | Polygons | Intersected cells | Area (ha) |
|---|---:|---:|---:|
| Named species composition | 4,372 | 29,866 | 21,670.81 |
| Explicitly unclassified species | 150 | 2,238 | 1,071.93 |
| No first-story species description | 288 | 3,290 | 1,512.03 |
| Clear-cut subset | 238 | 2,814 | 1,299.49 |

The three principal categories reconstruct a total
forest-covered area of 24,254.77 ha.

### Validation

The three principal category rasters were summed cell by cell
and compared with an independently rasterized total
forest-coverage layer.

Results:

- Maximum absolute cell difference: approximately 4.10e-8.
- Mean absolute cell difference: approximately 1.31e-8.
- Cells differing by more than 0.001: zero.
- Cells with reconstructed coverage above 1.01: zero.
- Reconstructed and reference forest areas: 24,254.77 ha.
- Clear-cut coverage exceeding no-description coverage:
  zero cells.

These results demonstrate internal spatial consistency
to numerical precision.

### Interpretation

The provincial inventory can represent multiple evidence
conditions within the same federal raster cell.

Named species, explicitly unclassified species, and absent
first-story descriptions remain separate.

Mapped clear cuts are also distinguished from generic
absence of species information.

Evidence-category coverage is not itself a measure of
observation accuracy or current vegetation condition.

### Limitations

- Fractional rasterization approximates polygon boundaries.
- The categories describe available inventory information,
  not probabilities of correctness.
- Named species composition may derive from older observations.
- No first-story description does not necessarily imply an
  evidentiary failure.
- Provincial evidence categories have not yet been converted
  into federal FBP fuel classifications.
- No empirical exposure comparison has yet been performed.

### Reproducible artifacts

Script:
`scripts/d03_provincial_evidence_coverage.R`

Generated rasters, excluded from Git:

- `data/processed/provincial-evidence/named_species_100m.tif`
- `data/processed/provincial-evidence/unclassified_species_100m.tif`
- `data/processed/provincial-evidence/no_first_story_description_100m.tif`
- `data/processed/provincial-evidence/clearcut_no_description_100m.tif`

### Next step

Visualize the provincial evidence categories on the common
100 m grid.

Use the validated coverage layers to examine the spatial
relationship between evidence availability, provincial
forest classifications, and federal FBP fuel categories.

### D03 visualization — provincial evidence and federal comparison

Two complementary visualizations were generated from the
validated 100 m evidence-coverage layers.

#### Provincial evidence coverage

The three-panel figure displays:

A. Named species composition.
B. Explicitly unclassified species.
C. No first-story species description.

All panels use the same spatial extent and fractional
coverage scale from zero to one.

The figure demonstrates that provincial inventory evidence
varies spatially in type, not merely in presence or absence.

#### Federal–provincial comparison

The four-panel figure displays:

A. Federal 2026 FBP fuel classifications, grouped into
   seven broad display families.
B. Provincial named-species coverage.
C. Provincial explicitly unclassified-species coverage.
D. Provincial no-first-story-description coverage.

The federal display families are:

- Conifer FBP: C-1 through C-4.
- Mixedwood FBP: 25%, 50%, and 75% conifer categories.
- Deciduous FBP: D-1.
- Grass FBP: O-1a.
- Non-fuel.
- Water.
- Vegetated area without an effective FBP match.

These groupings are used only for presentation. The original
12 numerical codes and their documented interpretations
remain unchanged.

#### Interpretation

The figures provide a common spatial reference for comparing
federal fuel classification with provincial species-evidence
availability.

They identify locations suitable for subsequent investigation,
particularly where the federal map assigns a fuel type while
the provincial inventory records unclassified species or no
first-story species description.

Such locations do not necessarily represent classification
errors or contradictions. The products have different sources,
purposes, and classification conventions.

White areas in the provincial panels mean zero coverage by
the particular evidence category shown. They do not
necessarily indicate missing inventory coverage, nonforest,
or low wildfire exposure.

No uncertainty score or exposure estimate is derived from
these visualizations.

#### Reproducible artifacts

Scripts:

- `scripts/plot_d03_provincial_evidence.R`
- `scripts/plot_d03_federal_provincial_comparison.R`

Figures:

- `outputs/figures/d03_provincial_evidence_coverage.png`
- `outputs/figures/d03_federal_provincial_comparison.png`

#### Next investigation

Quantify the spatial relationships between federal FBP fuel
families and provincial evidence-status categories.

Use fractional provincial coverage within each federal raster
cell rather than treating all intersecting cells as fully
covered.

Preserve distinctions among named species, explicitly
unclassified species, mapped disturbance, and absence of
first-story descriptions.

The objective is to identify differences in available
evidence and representation, not to assume that either
dataset provides ground truth.

## D04 — Federal 2026 FBP vs provincial forest evidence cross-tabulation

**Status:** Completed (analysis and figure generation complete; commit pending)

### Objective
Quantify how federal 2026 FBP fuel families intersect provincial forest evidence coverage, then examine the subset of federal **Non-fuel** cells that are at least 90% covered by provincially mapped forest.

### Inputs
- Federal raster: `data/processed/study-window/fbp_2026_candidate_100m.tif`
- Provincial evidence rasters from D03:
  - `data/processed/provincial-evidence/named_species_100m.tif`
  - `data/processed/provincial-evidence/unclassified_species_100m.tif`
  - `data/processed/provincial-evidence/no_first_story_description_100m.tif`
  - `data/processed/provincial-evidence/clearcut_no_description_100m.tif`
- Provincial vector source:
  - `data/raw/ns-forest-inventory/halifax-west/forest.shp`

### Methods
1. Performed an area-weighted cross-tabulation between federal FBP fuel families and provincial forest evidence coverage.
2. Identified federal **Non-fuel** cells (`code 101`) with at least 90% provincial forest coverage.
3. Reconstructed those qualifying cells as polygons and intersected them with the provincial forest inventory polygons (`LNDCLASS = 99`).
4. Summarized `SPECIES`, `PHOTOYR`, and `FORNON` within the qualifying cells using **intersection area in hectares** as weights.
5. Generated a map of provincial `PHOTOYR` categories within the qualifying federal Non-fuel cells.

### Main findings

#### D04 overall cross-tabulation
- The cross-tabulation accounted for all **40,000** federal cells.
- Total provincially classified forest coverage in the study window: **24,254.77 ha**.

#### Federal Non-fuel cells
- Federal Non-fuel cells: **3,438**
- Provincial forest area within federal Non-fuel cells: **1,315.66 ha**
- Federal Non-fuel cells with at least 90% provincial forest coverage: **850**
- Total area of those 850 cells: **818.8119 ha**
- Provincial forest coverage within those 850 cells:
  - Raster-derived estimate: **813.7256 ha**
  - Vector-intersection estimate: **813.3697 ha**
  - Difference: **-0.3558 ha** (**-0.0437%**)

#### Provincial evidence composition within the 850 qualifying Non-fuel cells
- Named species: **722.017 ha** (**88.77%**)
- Explicitly unclassified species (`UC10`): **32.386 ha** (**3.98%**)
- No first-story description: **58.966 ha** (**7.25%**)

#### Provincial photograph years within the 850 qualifying Non-fuel cells
- `PHOTOYR 2003`: **629.357 ha** (**77.38%**)
- `PHOTOYR 1992`: **172.514 ha** (**21.21%**)
- Other `PHOTOYR` values combined: **11.499 ha** (**1.41%**)

#### Relationship between photograph year and evidence status
- All **1992** area in this subset had **named species descriptions**.
- The **2003** area included:
  - **547.140 ha** named species
  - **32.386 ha** `UC10`
  - **49.831 ha** with no first-story description

#### FORNON within the 850 qualifying Non-fuel cells
- `FORNON = 0`: **745.015 ha** (**91.60%**)
- `FORNON = 60`: **50.649 ha** (**6.23%**)
- All other `FORNON` values combined: **17.706 ha** (**2.18%**)

#### Missing species descriptions and clear-cut association
- Area with no first-story species description: **58.966 ha**
- Of that, area with `FORNON = 60`: **50.649 ha**

### Figure
- `outputs/figures/d04_nonfuel_photo_year_map.png`

### Interpretation
The federal 2026 FBP **Non-fuel** class has a substantial spatial association with provincially mapped forest evidence, including many cells that are almost entirely provincially forest-covered. Most of that provincial evidence has named species descriptions rather than missing or explicitly unclassified species codes.

At the same time, the provincial evidence in those cells is dominated by `PHOTOYR` values from **1992** and **2003**. This supports the broader project concern that apparent classification disagreement should not be interpreted without attention to the age, source, and representational purpose of the evidence being compared.

### Limitations
- This analysis does **not** establish that either dataset is correct.
- Federal and provincial products may differ in classification purpose, update cycle, minimum mapping unit, and source evidence.
- `PHOTOYR` refers to recorded source photography year and should not be treated as equivalent to forest condition in 2026.
- The D04 cross-tabulation used fractional raster evidence layers, while the detailed D04 subset analysis used vector intersections. Their close agreement supports consistency, but the two methods are not identical.
- Provincial subset analysis was restricted to polygons with `LNDCLASS = 99`, matching the D03 evidence-construction rule.

### Outputs and scripts created
- `outputs/d04_fbp_provincial_evidence_cross_tab.csv`
- `outputs/figures/d04_nonfuel_photo_year_map.png`
- `scripts/d04_fbp_provincial_cross_tab.R`
- `scripts/d04_nonfuel_analysis.R`

The consolidated non-fuel analysis reproduces the verified
850-cell selection, 2,047 polygon intersections, area-weighted
attribute summaries, and photograph-year figure. Intermediate
diagnostic scripts remain available in Git history.

### Next step
Condense the D04 results into the root `README.md`, then review the D04 scripts for possible consolidation before committing the new analysis outputs and figure.

### D05 — 2024 FBP aligned raster verification (2026-10-26)

**Status:** Completed

The 2024 FBP source raster was cropped in its native CRS
and aligned to the existing 200 × 200 cell 2026 study grid
using nearest-neighbour categorical transformation.

Output:
`data/processed/study-window/fbp_2024_aligned_100m.tif`

Verification:
- Geometry matches the 2026 study raster.
- All 40,000 cells contain recognized 2024 classifications.
- Independent extraction from the national 2024 raster
  matched all 40,000 aligned cell classifications.
- Zero mismatches or missing values.

The source remains unchanged. The derived GeoTIFF is
excluded from Git.

Next: paired 2024–2026 classification comparison with
version-specific code meanings and explicit uncertainty
about source and representation differences.

### D06 — Paired 2024–2026 classification baseline (2026-10-26)

**Status:** Initial cross-tabulation verified

### Method

Compared the aligned 2024 and 2026 FBP classification
rasters on the same 200 × 200, 100 m study grid.

Both editions were interpreted through their respective
documented numeric code registers.

Reproducible script:
`scripts/d06_fbp_2024_2026_cross_tab.R`

Result:
`outputs/tables/d06_fbp_2024_2026_cross_tab.csv`

### Results

- Paired cells: 40,000
- Observed 2024 codes: 13
- Observed 2026 codes: 12
- Possible classification combinations: 156
- Same numeric code: 17,003 (42.51%)
- Different numeric code: 22,997 (57.49%)
- Both editions use code 13: 303 cells

Five largest different-code pairs:

| 2024 code | 2026 code | Cells |
|---|---|---:|
| 4 | 2 | 3,568 |
| 675 | 2 | 1,607 |
| 11 | 650 | 1,289 |
| 4 | 650 | 1,138 |
| 4 | 3 | 1,119 |

### Interpretation

These are differences between two mapped FBP products.
They are not direct evidence of changes in forest cover,
fuel conditions, wildfire exposure, or classification accuracy.

Numeric agreement is not equivalent to semantic agreement.

In particular, 303 cells use code 13 in both editions,
but the documented descriptions differ:

- 2024: D-1/D-2 Aspen
- 2026: Vegetated fuel without effective FBP type match

The cause of this apparent dictionary difference remains
to be investigated.

The largest different-code pair is 2024 code 4 versus
2026 code 2. This is a difference in mapped fuel type,
not evidence that one forest type physically became another.

### Next investigation

Distinguish numeric agreement, comparable fuel-family
classifications, and unresolved semantic differences.

Then investigate the spatial distribution and possible
source-evidence explanations for the dominant discrepancies.

### D06 — Broad fuel-family comparison (2026-10-26)

**Status:** Completed and reproducibly verified

Compared the 2024 and 2026 classification pairs using
version-specific analytical fuel-family groupings.

Script:
`scripts/d06_fbp_family_comparison.R`

Outputs:
- `outputs/tables/d06_fbp_family_summary.csv`
- `outputs/tables/d06_fbp_family_cross_tab.csv`

Results across 40,000 paired cells:

| Category | Cells | Percent |
|---|---:|---:|
| Same code, same family | 16,700 | 41.7500% |
| Different code, same family | 7,234 | 18.0850% |
| Same code, different family | 303 | 0.7575% |
| Different code, different family | 15,763 | 39.4075% |

Total different-family assignments:
16,066 cells (40.1650%).

The 303 same-code/different-family cells correspond
to code 13, whose documented descriptions differ
between the 2024 and 2026 registers.

The broad families are analytical groupings, not
an official NRCan cross-edition equivalence scheme.

Special categories such as water, non-fuel, vegetated
non-fuel, and unmatched vegetation remain distinct.

These findings describe disagreement between mapped
products. They do not establish landscape change,
classification accuracy, or wildfire exposure change.

Next: map the spatial distribution of disagreement
categories and investigate selected concentrations.

### D06 — Spatial disagreement map (2026-10-26)

**Status:** Completed and reproducibly verified

Mapped the four-category disagreement classification derived from
the paired 2024–2026 family comparison.

Script:
`scripts/d06_fbp_disagreement_map.R`

Output figure:
`outputs/figures/d06_fbp_disagreement_map.png`

Derived processed raster:
`data/processed/study-window/d06_fbp_disagreement_category_100m.tif`

Mapped categories and counts:

| Category | Cells | Percent |
|---|---:|---:|
| Same code, same family | 16,700 | 41.7500% |
| Different code, same family | 7,234 | 18.0850% |
| Same code, different family | 303 | 0.7575% |
| Different code, different family | 15,763 | 39.4075% |

The map reproduces the committed D06.5 family-summary totals exactly.

Initial interpretation:
- disagreement is spatially structured rather than uniformly random;
- broad areas of agreement coexist with extensive different-family disagreement;
- the rare same-code/different-family class is sparse, consistent with the code 13 cross-edition meaning difference.

This figure is suitable for analysis and documentation.
A later presentation-oriented version may tighten margins and styling.

Next:
identify concentrated disagreement zones and summarize their dominant paired transitions.

### D06 — Geographic registration screening (2026-10-26)

**Status:** Preliminary screening completed; source registration
question remains open.

#### Source registration qualification

An informal report raised the possibility of a geographic
registration issue in earlier FBP products. This has not
been independently verified and is not used to explain
the observed classification differences.

#### Prior processing validation

D05 independently verified that all 40,000 aligned 2024
raster cells reproduce the native source classification
at corresponding output-cell centres.

This validates the transformation procedure, not the
geographic correctness of the source classifications.

#### D06.11 water registration screening

Compared 2024 and 2026 water classifications (code 102)
under translations of up to ten 100 m cells in each direction.

All 441 comparisons used the same central 180 × 180-cell region.

Results:
- Current alignment Jaccard similarity: 0.8408538
- Highest-scoring translation: dx=0, dy=0
- Second-highest similarity: 0.7004520
- No tested translation improved water overlap

This supports the current water-feature registration within
the study region, but does not exclude geographic distortion
of the underlying forest-source evidence.

Rotation and nonlinear deformation were not tested.

#### D06.10 maximum-density neighbourhood

Cell 7313 has 121 of 121 cells with different analytical
family assignments in its 11 × 11 neighbourhood.

Dominant paired classifications:
- 2024 code 105 to 2026 code 13: 114 cells
- 2024 code 2 to 2026 code 13: 4 cells
- 2024 code 105 to 2026 code 101: 2 cells
- 2024 code 4 to 2026 code 13: 1 cell

This is predominantly a special-vegetation classification
difference, not a conifer-to-mixedwood disagreement.

#### Interpretation

The published D06 disagreement percentages remain valid
descriptions of the two aligned raster products.

They must not be interpreted as measured landscape change,
map accuracy, or differences caused solely by classification
rules.

#### Next

Seek independent geographic control or authoritative
confirmation of the reported registration issue before
attributing spatial disagreement to particular causes.

### D06 — Fuel-bearing versus special-category differences (2026-10-26)

**Status:** Completed and reproducibly verified

Script:
`scripts/d06_disagreement_types.R`

Output:
`outputs/tables/d06_disagreement_types.csv`

Across 40,000 paired cells:

| Comparison category | Cells | Percent |
|---|---:|---:|
| Same analytical family | 23,934 | 59.8350% |
| Different recognized fuel families | 11,223 | 28.0575% |
| Fuel-to-special disagreement | 3,822 | 9.5550% |
| Special-to-special disagreement | 1,021 | 2.5525% |

Recognized fuel families here include conifer, deciduous,
mixedwood and grass. Special classes include water,
non-fuel, vegetated non-fuel and unmatched vegetation.

Of the 16,066 different-family cells, 69.86% involve
two recognized FBP fuel families.

#### Ecological applicability question

Natural Resources Canada identifies the Maritimes
with the Acadian forest region, characterized by
species including red spruce, balsam fir and yellow birch.

Several standard FBP fuel types, including C-2, C-4
and M-1/M-2, are described using boreal forest
species and stand structures.

The 2024 national FBP classification map was developed
using national source information including SCANFI,
Canadian ecozones and burned-area data.

This creates a question about the applicability of
particular FBP model assignments to local Acadian forest
composition. It does not establish that either edition
is incorrect or that the map was built exclusively from
boreal forest data.

Sources:
- https://natural-resources.canada.ca/forests-forestry/sustainable-forest-management/forest-classification
- https://natural-resources.canada.ca/forests-forestry/wildland-fires/canada-fire-behaviour-prediction-system-fuel-types
- https://open.canada.ca/data/en/dataset/4e66dd2f-5cd0-42fd-b82c-a430044b31de

#### Next investigation

Use provincial forest-inventory composition to examine
selected locations with substantial conifer/mixedwood
or deciduous/mixedwood disagreement.

Keep three questions separate:
- Do the 2024 and 2026 mapped classifications differ?
- What forest composition does provincial evidence describe?
- How well does each assigned FBP fuel model represent
  that composition?

No map accuracy or fuel-behaviour validation is claimed.

### D07 — Provincial evidence for C-4 to C-2 disagreement (2026-10-26)

**Status:** Reproducible exploratory analysis completed

#### Research question

What does provincial forest-inventory evidence describe
in cells classified C-4 in the 2024 FBP map and C-2
in the 2026 FBP map?

These are two conifer fuel models, but they describe
different species associations and stand structures.

#### Reproducible implementation

Script:
`scripts/d07_c4_to_c2_provincial_composition.R`

Outputs:
- `outputs/tables/d07_c4_to_c2_area_summary.csv`
- `outputs/tables/d07_c4_to_c2_species_composition.csv`
- `outputs/tables/d07_c4_to_c2_evidence_years.csv`

The analysis uses aligned national FBP rasters,
provincial forest polygons, exact polygon intersections,
and area-weighted first-story species components.

#### Verified study population

- Selected paired FBP cells: 3,568.
- Projected target ground area: 3,436.711 ha.
- Intersecting provincial forest area: 3,040.746 ha.
- Provincial forest coverage: 88.478%.
- Forest area with complete species-component encoding:
  2,834.208 ha (93.208% of provincial forest).
- Forest area without species components:
  206.538 ha (6.792% of provincial forest).

The provincial forest intersection is not equivalent
to a complete contemporary ground survey.

#### Leading first-story species codes

Percentages below use the 2,834.208 ha with complete
recorded species components as their denominator.

| Code | Documented description | Percent |
|---|---|---:|
| RS | Red spruce | 27.932% |
| BF | Balsam fir | 15.268% |
| BS | Black spruce | 14.724% |
| RM | Red maple | 12.446% |
| XS | Mixed red and black spruce category | 8.699% |
| UC | Unclassified species | 5.135% |

The five leading codes represent approximately
79.07% of described first-story composition.

XS is retained as a combined category. UC is not
treated as an identified botanical species.

Species contributions reconcile with the described
area to floating-point precision.

#### Evidence age

Among described provincial forest area:

- PHOTOYR 2003: 75.81%.
- PHOTOYR 1992: 14.49%.
- Both years combined: 90.29%.

PHOTOYR records the inventory's year of forest-attribute
collection, subject to documented field conventions.

All described-area PHOTOYR values in this comparison
precede the 2023 Westwood Hills fire.

High compositional coverage does not imply that the
forest conditions remain unchanged.

#### Interpretation and limitations

The provincial evidence describes a mixture dominated
by red spruce, balsam fir, black spruce, red maple,
and a combined red/black spruce category.

This composition raises a substantive question about
the local ecological representativeness of the C-4
and C-2 national fuel-model assignments.

However, species composition alone is insufficient
to establish the correct FBP fuel model. Stand age,
structure, surface fuels, disturbance history and
other characteristics may also matter.

The provincial inventory is not treated as ground
truth or as necessarily independent of national
source information.

No fire-behaviour or exposure consequences have yet
been calculated for this transition.

#### Next investigation

Examine how the recorded composition varies among
individual disagreement locations rather than
treating the entire C-4 to C-2 footprint as one stand.

Maintain separate accounts of:
- Fuel-map classification disagreement.
- Provincial composition and observation age.
- Model applicability and eventual exposure sensitivity.

### D07 — Dominant species and recorded stand mixtures (2026-10-26)

**Status:** Reproducible analysis completed

#### Purpose

Examine how first-listed provincial species categories
and species-component mixtures vary within cells
classified C-4 in the 2024 FBP edition and C-2 in 2026.

#### Reproducible implementation

Script:
`scripts/d07_c4_to_c2_dominant_species.R`

Outputs:
- `outputs/tables/d07_c4_to_c2_dominant_species.csv`
- `outputs/tables/d07_c4_to_c2_stand_mixing.csv`

The analysis uses exact intersections between
provincial inventory polygons and the selected
FBP raster-cell footprints.

Area weighting is based on polygon-intersection area.

#### Verified results

The denominator is 2,834.208 ha of provincially
described first-story forest composition.

First-listed species categories:

| Code | Share of described area |
|---|---:|
| RS | 40.57% |
| BS | 21.58% |
| XS | 12.25% |
| BF | 7.73% |
| RM | 5.59% |
| UC | 5.14% |

Recorded mixture indicators:

- Single 100% species component:
  219.977 ha (7.76%).
- Multiple recorded species components:
  2,614.232 ha (92.24%).
- Largest recorded component 50% or less:
  1,194.882 ha (42.16%).

SP1 is verified to be a largest recorded component
for the described polygons in this intersection.

A first-listed species code does not imply a pure stand.

Multiple recorded species components do not
necessarily indicate an FBP mixedwood fuel type.
For example, mixtures of different softwood species
must be distinguished from softwood-hardwood mixtures.

#### Interpretation

The C-4 to C-2 disagreement footprint includes
substantial variation in recorded provincial
first-story composition.

The aggregate species percentages therefore
should not be interpreted as describing one
representative forest stand.

Both the national FBP assignments and provincial
inventory descriptions are abstractions. Their
different purposes, spatial support, observation
periods and classification rules must be considered.

This analysis does not determine which national
fuel classification is more accurate.

#### Next investigation

Examine spatially localized differences in:

- Dominant species and component proportions.
- Softwood versus hardwood composition.
- Provincial evidence age and completeness.

Identify contrasting locations suitable for
a paired exposure and uncertainty demonstration.

### D07.10 — Spatially localized provincial evidence (2026-10-26)

**Status:** Reproducible neighbourhood evidence summary completed;
local demonstration locations remain provisional.

#### Purpose

Examine geographical variation in provincial inventory evidence
within the 2024 C-4 to 2026 C-2 disagreement footprint.

Distinguish national classification disagreement, provincial
species composition, evidence completeness, and evidence dates.

#### Reproducible implementation

Script: `scripts/d07_neighbourhood_evidence.R`

Output: `outputs/tables/d07_neighbourhood_evidence.csv`

The established 200 x 200-cell study grid is partitioned into
100 non-overlapping 2 x 2 km neighbourhoods.

Provincial evidence is evaluated only where forest polygons
intersect the 3,568 C-4 to C-2 disagreement cells.

Species and completeness measurements are weighted by exact
polygon-intersection area.

#### Spatial structure

Eight-neighbour connectivity identified 1,321 disagreement
components. Of the 3,568 disagreement cells, 49.72% belong
to components of four cells or fewer.

The largest component contains 130 cells (3.64%).

The 2 km neighbourhood partition therefore provides a more
useful initial comparison unit than individual components.

Of 100 neighbourhoods, 97 contain disagreement cells.
The median count is 34, and the maximum is 91.

Across the footprint:

- Provincial forest intersection: 3,040.746 ha.
- Described first-story forest: 2,834.208 ha.
- Neighbourhoods with at least 20 ha described forest: 59.
- Neighbourhoods with description completeness below 80%: 7.

The 20 ha criterion is exploratory, not a statistical
or ecological threshold.

#### Regional evidence contrasts

Neighbourhood 98:

- 77 disagreement cells.
- BS first-listed across 99.27% of described area.
- Leading component at most 50% across 10.46%.
- Complete first-story descriptions.
- Recorded PHOTOYR values: 2002 and 2003.

Neighbourhood 40:

- 76 disagreement cells.
- BF first-listed across 34.93% of described area.
- Leading component at most 50% across 86.59%.
- Description completeness: 98.30%.
- Recorded PHOTOYR values: 1992 and 2003.

Neighbourhood 71:

- 84 disagreement cells.
- Description completeness: 67.60%.
- Recorded PHOTOYR values within described area:
  1992, 2003, 2005 and 2006.

These are contrasts in recorded inventory evidence,
not demonstrations of classification accuracy.

#### Local reference neighbourhoods

Westwood Hills reference point lies in neighbourhood 35:

- 31 disagreement cells.
- Provincial forest intersection: 20.175 ha.
- Described area: 19.342 ha.
- Description completeness: 95.87%.
- Most common first-listed species: RS (46.56%).
- Multiple recorded components: 93.17%.
- Leading component at most 50%: 33.70%.
- Recorded PHOTOYR values: 1992 and 2003.

Upper Tantallon reference point lies in neighbourhood 56:

- 25 disagreement cells.
- Provincial forest intersection: 23.578 ha.
- Description completeness: 100%.
- Most common first-listed species: BS (66.85%).
- Multiple recorded components: 99.50%.
- Leading component at most 50%: 65.48%.
- Recorded PHOTOYR values: 1992 and 2003.

Neighbourhood 35 is retained as a local reference despite
falling slightly below the exploratory 20 ha described-area
criterion.

#### Interpretation and limitations

The disagreement footprint contains geographically varying
provincial evidence, including differences in first-listed
species, component proportions, description completeness,
and recorded inventory years.

The share of area with a particular first-listed species
must not be interpreted as the average proportion of that
species within stands.

Multiple species components do not necessarily indicate
a softwood-hardwood mixture or an FBP mixedwood fuel type.

PHOTOYR indicates historical inventory evidence, not
verified present-day forest condition.

The provincial inventory is not automatically ground truth
and may share underlying evidence with national products.

These measurements do not establish which FBP edition
is more accurate or whether exposure estimates differ.

#### Next investigation

Compare neighbourhoods near Westwood Hills using the
maintained CSV, rather than selecting only the most
extreme regional examples.

Verify softwood/hardwood species-code groupings before
adding composition-family indicators.

Select contrasting local candidates and assess whether
the national classification differences produce meaningful
changes in estimated exposure.

No new exposure calculations or maps have been performed
in D07.10.
