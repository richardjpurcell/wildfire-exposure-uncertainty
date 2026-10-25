# R Environment and Reproducibility

**Established:** 2026-10-25
**Platform tested:** macOS Apple Silicon
**Status:** Package installation verified; numerical testing pending.

## Environment

The project uses a Conda environment named `wildfire-exposure`.

The principal specification is [environment.yml](../../environment.yml).

Create and activate the environment:

    conda env create -f environment.yml
    conda activate wildfire-exposure

## CRAN packages

The following packages were installed separately from CRAN:

| Package | Verified version |
|---|---|
| tidyterra | 1.3.0 |
| MultiscaleDTM | 1.0.1 |
| fireexposuR | 1.2.0 |

Install using Conda R:

    "$CONDA_PREFIX/bin/Rscript" -e 'install.packages(
      c("tidyterra", "MultiscaleDTM", "fireexposuR"),
      repos = "https://cloud.r-project.org"
    )'

This installs currently available compatible CRAN
versions, not necessarily the exact versions listed above.

## R executable selection

The system R installation may take precedence over
Conda R, even when the environment is activated.

Use the explicit executable:

    "$CONDA_PREFIX/bin/Rscript"

## Verified package versions

| Package | Version |
|---|---|
| R | 4.4.3 |
| terra | 1.9.50 |
| sf | 1.1.3 |
| codetools | 0.2.20 |
| dplyr | 1.2.1 |
| geosphere | 1.6.8 |
| ggplot2 | 4.0.3 |
| rlang | 1.3.0 |
| tidyr | 1.3.2 |
| tidyselect | 1.2.1 |
| ggspatial | 1.1.11 |
| maptiles | 0.13.0 |
| tmap | 4.4.1 |
| rgl | 1.3.36 |
| tidyterra | 1.3.0 |
| MultiscaleDTM | 1.0.1 |
| fireexposuR | 1.2.0 |

## Verified functionality

The following have been confirmed:

- Conda R 4.4.3 launches successfully.
- terra and sf load successfully.
- fireexposuR 1.2.0 loads.
- fire_exp() is available.
- fire_exp_dir() is available.

Numerical calculations have not yet been tested.

## Remaining verification

- Test fire_exp() using a small synthetic raster.
- Test fire_exp_dir() with controlled directions.
- Verify output dimensions and numerical behaviour.
- Establish RStudio integration with Conda R.
- Pin CRAN package versions for reconstruction.
- Consider a complete environment lockfile.

Package availability alone does not establish
numerical reproducibility.
