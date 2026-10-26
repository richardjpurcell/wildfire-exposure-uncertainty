# D09.6 — Visualization design review

**Date:** 2026-10-26
**Status:** Proposed design, pending visual assessment

## Purpose

Use the verified D09 spatial products to select a
visualization arrangement that distinguishes apparent
exposure from the limitations of its supporting
representations and assumptions.

No new modelling assumptions are introduced.

## Geographic emphasis

Primary focal area:
- Block 35, Westwood Hills.

Contrasting areas:
- Block 44, strong C-2/C-4 assumption sensitivity.
- Block 25, strong unresolved-input sensitivity.

The contrasts are analytical examples, not rankings
of actual wildfire danger.

## D09.6 diagnostic findings

| Area | Opposing | Agreement | Indeterminate | Mean unresolved sensitivity |
|---|---:|---:|---:|---:|
| Study area | 53.84% | 29.25% | 16.91% | 0.03475 |
| Block 35 | 46.75% | 1.75% | 51.50% | 0.10709 |
| Block 44 | 58.00% | 33.75% | 8.25% | 0.00706 |
| Block 25 | 23.25% | 0.25% | 76.50% | 0.40372 |

These proportions describe valid exposure-assessment
cells, which are spatially related.

## Figure 1 — Reference exposure

Display the same verified 2026 reference exposure
surface in two geographic contexts:

- 1A: satellite imagery basemap
- 1B: cartographic basemap

Keep identical:
- raster data
- geographic extent
- colour scale
- classification thresholds
- opacity
- legend

The 2026 reference uses an experimental broad binary
vegetation assignment and fixes unresolved code 13
to zero.

It is not validated physical wildfire exposure.

## Figure 2 — Interpretive caution

Use separate visual layers or panels for:

1. C-2/C-4 assumption sensitivity in the comparison
   between the 2024 and 2026 FBP editions.
2. Unresolved-input sensitivity in the 2026
   reference exposure calculation.

The edition-comparison panel should distinguish:

- robust opposing signs
- robust directional agreement
- direction not established

Do not label all non-reversal cells as stable.

The unresolved-input sensitivity panel should retain
its continuous numerical meaning.

Do not combine the two signals into a single
unexplained uncertainty index.

## Interpretation boundaries

The comparison concerns modelled 2026-minus-2024
exposure differences, not measured environmental
change between those years.

Satellite imagery provides visible landscape context,
not independent validation of the mapped fuel types.

The 500 m exposure values are neighbourhood
proportions under experimental assignments, not
wildfire probabilities.

The sensitivity results are deterministic calculations,
not confidence intervals or probabilities of error.

## Visual assessment still required

Before selecting the final figure:

1. Inspect the geographic arrangement of blocks
   35, 44, and 25.
2. Determine whether the three areas fit in one
   readable regional map.
3. Assess the legibility of a three-category
   comparison alongside continuous sensitivity.
4. Verify satellite and cartographic basemap access,
   attribution, and available imagery-date information.
5. Review initial renderings before updating the README.

## Next milestone

Prepare a controlled geographic layout diagnostic
using existing rasters and reference points.

No final map design has yet been approved.
