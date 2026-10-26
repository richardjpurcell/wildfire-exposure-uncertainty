# D09 — Paired visualization design specification

**Date:** 2026-10-26
**Status:** Draft for review

## Purpose

Define the paired visualization demonstration that will
communicate:

1. an estimated wildfire exposure picture, and
2. a companion picture showing why that estimate should
   be interpreted cautiously.

This document is a design specification, not a numerical
result.

## Audience

Primary audience:
- technically interested wildfire practitioners
- semi-knowledgeable decision-makers
- researchers interested in uncertainty and representation

The visuals should be interpretable without requiring the
viewer to understand the full software workflow.

## Core communication goal

The paired demonstration should show that:

- an exposure estimate can appear clear and actionable,
  while
- the strength of that estimate depends on the underlying
  landscape representation, classification choices, and
  evidence completeness.

The goal is not to declare one national FBP edition
correct.

## Two-picture structure

### Picture 1 — Exposure

This picture should answer:

> What does the selected landscape representation suggest
> about wildfire exposure?

This is the “apparent answer” picture.

### Picture 2 — Stability / uncertainty / evidence caution

This picture should answer:

> Where does that apparent answer depend strongly on
> classification choices, representation choices, or
> limitations in the supporting evidence?

This is the “interpret with caution” picture.

## Basemap requirement

A design requirement for Picture 1 is:

- show the exposure on a **satellite / imagery basemap**
  so the viewer can see the actual landscape context
- also show the **same exposure on a cartographic map
  basemap**

This implies two renderings of the same exposure surface:

- Picture 1A: exposure over satellite imagery
- Picture 1B: exposure over map basemap

For Picture 2, the default assumption is:

- primary rendering on a map basemap

A satellite version of Picture 2 can be considered later
if it materially improves interpretation.

## Current evidence base

### Classification evidence

Relevant maintained work:
- D06 national FBP disagreement
- D07 provincial evidence by neighbourhood
- D08 broad binary exposure sensitivity
- D08 within-conifer sensitivity

### Key findings already available

1. The 2024 and 2026 national FBP editions differ
   substantially in the study area.

2. The provincial inventory provides spatially varying
   composition, completeness, and evidence-date context.

3. A broad binary hazard representation can conceal
   meaningful classification differences.

4. Opposing hypothetical treatments of C-2 and C-4 can
   reverse the direction of the regional exposure
   comparison.

5. Some neighbourhoods are more stable than others.

## Picture 1 candidate content

### Recommended interpretation

Picture 1 should present a **reference exposure
representation**, not “the true exposure”.

That reference representation should be clearly labelled
as a chosen baseline for communication.

### Candidate source

Initial candidate:
- one exposure surface from the maintained D08 framework,
  or
- a deliberately selected reference scenario derived
  from the national FBP representation.

This selection has not yet been finalized.

### Design note

Because no C-2 / C-4 treatment has been validated as the
physical truth for this investigation, Picture 1 must not
be labelled as “actual” or “best” exposure.

## Picture 2 candidate content

Picture 2 should not collapse every limitation into one
unexplained score.

Instead, it should emphasize one or more interpretable
sensitivity or evidence signals, such as:

- broad classification disagreement
- within-conifer sensitivity
- unresolved-category sensitivity
- provincial evidence completeness
- provincial evidence-date context

### Preferred role of Picture 2

Picture 2 should help the viewer identify:

- where the exposure picture is comparatively stable
- where the exposure picture depends strongly on modelling
  or classification assumptions
- where supporting evidence is older or less complete

## Candidate visualization strategy

### Exposure products

1. Picture 1A:
   exposure overlay on satellite imagery

2. Picture 1B:
   same exposure overlay on a cartographic map basemap

### Caution / stability product

3. Picture 2:
   uncertainty / stability / evidence-caution layer on a
   cartographic map basemap

Optional later companion:
- Picture 2B on satellite imagery, only if needed

## Preferred communication style

### Picture 1

Should feel:
- direct
- plausible
- easy to read

### Picture 2

Should feel:
- interpretive
- diagnostic
- cautionary, but not alarmist

The second picture should not imply failure of the first.
It should show limits and dependence.

## Geographic focus

The paired demonstration should likely focus on a small
set of candidate local areas rather than the full
20 × 20 km study window alone.

Current candidates already examined numerically include:
- neighbourhood 35 (Westwood Hills reference)
- neighbourhood 34
- neighbourhood 25
- neighbourhood 24
- neighbourhood 44
- neighbourhood 33

A later step should choose whether the final
demonstration uses:
- one focal area, or
- two contrasting focal areas

## What still needs to be decided

1. Which exposure representation becomes the displayed
   reference picture?

2. Whether the final demonstration should focus on
   Westwood Hills alone or compare Westwood Hills with a
   contrasting neighbourhood.

3. Which stability / uncertainty quantity should anchor
   Picture 2.

4. Whether Picture 2 should emphasize:
   - modelling sensitivity,
   - evidence completeness,
   - or a layered combination.

5. Which map extent best balances readability and local
   detail.

## Immediate next analytical task

Before making maps, prepare a small **data-to-visual
inventory** that identifies:

- which maintained outputs can already support
  Picture 1
- which maintained outputs can already support
  Picture 2
- which additional derived rasters or tables are still
  needed
- which basemap sources will be used for satellite and
  map renderings

## Status of README

The root README does not need updating yet.

The paired-visualization design should be settled first.

## Near-term workflow

1. Review this design specification.
2. Create a D09 input inventory for the two pictures.
3. Choose the focal area(s).
4. Only then begin the map-generation workflow.

