# Megathrust Shear-Zone Model

This repository contains the numerical model setup and parameter combinations used to investigate deformation within a heterogeneous subduction-interface shear zone.

## Code

The source code in `src/` is **based on and modified from Norma-VEP**, a two-dimensional visco-elasto-plastic finite-difference marker-in-cell code developed by Ruh et al. (2024).

**Original Norma-VEP repository:**  
https://github.com/Norma-VEP/

**Norma reference:**  
Ruh, J., Behr, W., & Tokle, L. (2024). *Effect of Grain-Size and Textural Weakening in Polyphase Crustal and Mantle Lithospheric Shear Zones*. Tektonika, 2(1), 91–110.  
https://doi.org/10.55575/tektonika2024.2.1.68

Please cite the original Norma paper when using the source code.

## Model setup

`two_phase_shearzone.m` contains the study-specific model setup.

The numerical experiments vary three main parameters:

- block-to-matrix ratio;
- seamount aspect ratio;
- matrix pore-fluid pressure ratio.

The parameter combinations for all experiments are provided in:

`experiment_table.csv`

## Repository structure

```text
.
├── two_phase_shearzone.m    # Study-specific model setup
├── experiment_table.csv     # Parameters for TY1–TY25
└── src/                     # Source code based on and modified from Norma-VEP
```

## Acknowledgement

The numerical framework used in this study is derived from Norma-VEP. We thank the Norma developers for making the original code openly available.
