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