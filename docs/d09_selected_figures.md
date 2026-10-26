# D09 — Selected visualization prototypes

**Date:** 2026-10-26
**Status:** Selected after visual review; final layout pending

## Figure 1 — Reference exposure

### Panel 1A: Satellite context

`outputs/figures/d09_satellite_exposure_grayscale_45.png`

### Panel 1B: Cartographic context

`outputs/figures/d09_cartographic_exposure_grayscale_45.png`

Reproduction source for both:

`scripts/d09_render_reference_exposure_pair_grayscale_45.R`

Both panels display the identical 2026 reference exposure
raster, using the same extent, scale, opacity, and
classification breaks.

The exposure model is illustrative and uses the broad
binary vegetation representation.

## Figure 2 — Sensitivity and interpretation

### Panel 2A: C-2/C-4 assumption sensitivity

`outputs/figures/d09_conifer_stability_map_v2.png`

Source:

`scripts/d09_render_conifer_stability_map_v2.R`

This panel classifies the direction of the calculated
2026-minus-2024 exposure difference under two opposing
hypothetical C-2/C-4 treatments.

Its categories are:
- robust opposing directions
- robust agreement in direction
- direction not established

It does not directly measure the reliability of the
single 2026 reference exposure surface.

### Panel 2B: Unresolved-input sensitivity

`outputs/figures/d09_unresolved_sensitivity_map_v2.png`

Source:

`scripts/d09_render_unresolved_sensitivity_map_v2.R`

This panel shows the calculated exposure difference
between assigning unresolved 2026 fuel categories 1
versus 0.

Computational zero is displayed separately from
positive sensitivity.

A zero value does not establish that the source
evidence is complete or that the exposure estimate
is reliable.

## Common geography

All panels use the same approximately 6 x 8 km
Westwood Hills viewing window.

Selected analytical neighbourhoods:
- Block 25
- Block 35 (Westwood Hills)
- Block 44

The blocks are analytical partitions, not natural
wildfire boundaries.

## Visual review outcome

The selected designs use:
- satellite and cartographic context for exposure
- a grayscale basemap for sensitivity
- a categorical scale for assumption sensitivity
- a sequential violet scale for unresolved-input
  sensitivity, with zero distinguished separately

## Outstanding editorial work

- Improve legend spacing.
- Explain the reference-point symbol.
- Align terminology across figure titles and captions.
- Retain appropriate basemap attribution.
- Document imagery acquisition dates if obtainable;
  otherwise state that dates are unverified.
- Consolidate reproduction scripts.
- Decide which selected figures should be tracked in Git.

Intermediate rendering prototypes are not intended
for the final repository.

No new numerical findings are claimed in this record.

## Future historical comparison

The 2019 FBP edition should be evaluated as a
potential pre-2023-fire landscape representation.

A subsequent investigation may compare:
- 2019, 2024, and 2026 FBP classifications;
- calculated exposure under harmonized assumptions;
- an authoritative perimeter of the 2023 Tantallon fire.

Edition differences must not automatically be
interpreted as actual landscape change.

The acquisition dates, source inventories, classification
rules, and comparability of the FBP editions require
verification.

A post-fire exposure representation must not be
used as independent predictive validation of the
2023 fire.

The current D09 exposure styling is provisional:
grayscale basemaps and a common 45% opacity.

## Maintained reproduction workflow

The four selected figures are generated through one
maintained entry point:

`scripts/d09_render_selected_figures.R`

Dry-run verification:

`Rscript scripts/d09_render_selected_figures.R --dry-run`

Full reproduction:

`Rscript scripts/d09_render_selected_figures.R`

The entry point invokes three maintained renderers:

- `scripts/d09_render_reference_exposure_pair_grayscale_45.R`
- `scripts/d09_render_conifer_stability_map_v2.R`
- `scripts/d09_render_unresolved_sensitivity_map_v2.R`

The four selected figures were regenerated successfully
and independently compared with their selected originals.

All four decoded PNG pixel arrays were identical in
the tested local environment.

This verifies local rendering reproducibility. It does
not guarantee identical output across future basemap
updates, software versions, or computing environments.

## Current rendering status

The figure selection is provisionally complete.

Common features:
- 6 x 8 km geographic extent;
- EPSG:3978 map projection;
- Westwood Hills reference point;
- blocks 25, 35, and 44;
- OpenStreetMap geographic context where applicable.

Exposure maps use:
- the same verified 2026 reference raster;
- grayscale basemaps;
- 45% exposure overlay opacity;
- identical exposure breaks and colours.

The satellite image is from Esri World Imagery.

The imagery acquisition dates have not been verified.
The satellite basemap must not be described as showing
a known date or independently validating fuel classes.

The sensitivity maps retain separate, explicitly
defined analytical meanings.

## Repository scope

Retain only the four selected figures and four
maintained rendering scripts.

Intermediate map prototypes and their rendering
scripts were removed after visual assessment and
successful reproduction testing.

The root README remains unchanged pending final
interpretation and documentation review.
