# Representing Uncertainty in Wildfire Exposure Assessments

A reproducible technical investigation of how landscape evidence, fuel representations, and assessment thresholds influence wildfire exposure estimates and the stability of directional conclusions.

## Overview

Wildfire exposure assessments describe how surrounding landscape conditions may contribute to potential fire exposure at a location. However, their results depend on the available evidence, how landscape characteristics are represented, and the parameters used to interpret the calculations.

This project investigates how those dependencies can be measured and communicated alongside conventional exposure results.

The central proposal is to produce two complementary pictures:

1. **Exposure:** What does the assessment indicate about the surrounding landscape?
2. **Stability:** How strongly does that conclusion depend on the evidence, representation, and thresholds used?

An exposure result may remain in the same classification even when its underlying numerical value or distance from a decision threshold changes substantially. Understanding these distinctions is an important part of the investigation.

## Study area

The initial study region surrounds the 2023 Westwood Hills / Upper Tantallon wildfire in Nova Scotia, Canada.

The historical wildfire provides geographic context. This project does not attempt to reconstruct the fire or validate predictions of its behaviour.

## Landscape evidence

The investigation will consider four principal landscape representations:

- Canadian national Fire Behaviour Prediction (FBP) fuel maps from 2019, 2024, and 2026.
- Nova Scotia provincial forest inventory data, including forest composition and land classification.

These products may differ in observation dates, classification methods, spatial resolution, and underlying evidence. Differences between them will not automatically be interpreted as classification errors.

## Experimental approach

The investigation is organized into four layers:

1. **Evidence:** Examine source datasets, provenance, coverage, and classification differences.
2. **Representation:** Construct comparable experimental landscape representations while preserving assumptions and missing information.
3. **Exposure:** Calculate continuous and directional exposure assessments using controlled parameters.
4. **Communication:** Develop paired exposure and stability visualizations.

The initial technical environment uses R, `terra`, and `fireexposuR`.

Planned experiments include sensitivity to transmission distance, alternative fuel representations, and two-dimensional exposure and directional-viability threshold combinations.

We will distinguish evidence disagreement, numerical sensitivity, decision-margin sensitivity, and classification stability rather than treating them as a single measure of uncertainty.

## Project status

**Stage: Repository establishment**

The research framework has been defined, but no new Westwood Hills exposure experiments have been completed within this project.

Prior exploratory work in other Nova Scotia locations informs the experimental design but does not constitute evidence of results in the new study area.

## Findings

No experimental findings have yet been established for this study region.

This section will be updated as reproducible experiments are completed.

## Reproducibility

The project will maintain analysis scripts, parameter configurations, dataset provenance records, numerical results, figures, and experiment notes.

Large source datasets will not be distributed directly through Git. Official acquisition sources, relevant versions, and processing instructions will be documented.

## Documentation

Technical documentation and a chronological research record are maintained in [docs/](docs/).

The [experiment log](docs/experiment-log.md) records completed steps, important decisions, and unresolved questions.

## Limitations

This project investigates the sensitivity and stability of exposure representations. Stability should not be interpreted as a calibrated probability of correctness or as a measure of operational safety.

Alternative fuel weights and composition-based representations, where used, will be identified as experimental assumptions rather than validated fire-behaviour parameters.