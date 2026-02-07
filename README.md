# Replication for: Gender-Directed Sector-Specific Technical Change

**Authors:** Guido Cozzi, Theresa Goop  
**Affiliation:** University of St. Gallen  
**Date:** January 25, 2026  
**Paper:** "Gender-Directed Sector-Specific Technical Change"  
**Funding:** Swiss National Science Foundation (Grant 100018_219686)

---

## Overview

This repository contains all code and documentation necessary to replicate the 
empirical findings in "Gender-Directed Sector-Specific Technical Change" (Cozzi & Goop, 2026). 
The paper investigates how sectoral innovation responds endogenously to changes 
in the gender composition of the labor force in Switzerland between 2012 and 2020.

**Note:** Due to data confidentiality agreements with the 
Swiss Federal Statistical Office (FSO), the underlying microdata **cannot** 
be publicly shared. However, this repository provides:

- Complete analysis code (R scripts)
- Detailed data documentation
- Instructions for obtaining data access
- Metadata compliant with FAIR principles

---

## Repository Contents

```
├── README.md                          # This file
├── DATA_ACCESS.md                     # Instructions for obtaining restricted data
├── DATA_CLEANING.md                   # Detailed data cleaning procedures
├── CODEBOOK.md                        # Variable definitions and constructed measures
├── REPLICATION_GUIDE.md               # Step-by-step replication instructions
├── code/
│   ├── 1_get_loaded.R                 # Load and link LSE+STATPOP+ZAS data
│   ├── 2_get_clean.R                  # Data quality filtering (Filters A-E)
│   ├── 3_get_all_variables.R          # Variable construction and sector mapping
│   ├── 1_get_descriptives.R           # Descriptive statistics and figures
│   ├── 2b_get_data_for_bartik_2012.R  # Bartik instrument construction
│   ├── 3_1_get_naive_estimation.R     # Auxiliary estimation (minor)
│   ├── 3_2_get_iv.R                   # Main Bartik IV estimation + OLS baseline
│   └── 3_3_get_iv_sectors.R           # Sector-specific IV estimation
└── metadata/
    └── zenodo_metadata.json           # Machine-readable metadata
```

---

## Data Sources

### Restricted-Access Data (FSO)

The primary analysis uses confidential microdata from three linked sources 
provided by the Swiss Federal Statistical Office (FSO):

1. **Swiss Earnings Structure Survey (Lohnstrukturerhebung, LSE)**
   - **Years:** 2012, 2014, 2016, 2018, 2020 (biannual)
   - **Coverage:** Representative sample of 1.6–2.1 million employees per survey year
   - **Variables:** Individual-level earnings (MBLS), hours worked (IWAZ, BEZSTD), 
   FTE percentage (IBGR), occupation codes (ISCO-08), sector classification (NOGA 2008)
   - **Access:** Requires formal data use agreement with FSO
   - **Confidentiality:** Individual-level data subject to Swiss statistical confidentiality laws

2. **STATPOP (Statistik der Bevölkerung und Haushalte)**
   - **Years:** 2012–2020 (annual population register)
   - **Coverage:** Demographic characteristics for Swiss residents
   - **Variables:** Age, gender (SEX), work canton (ARBKTO), education level (AUSBILD)
   - **Access:** Linked to LSE via pseudonymized social security numbers
   - **Use:** Provides demographic controls and education information

3. **Central Compensation Office (Zentrale Ausgleichsstelle, ZAS) Wage Data**
   - **Years:** 2012–2020 (annual)
   - **Coverage:** Administrative records of social security contributions
   - **Variables:** Total reported income (mrevcot), employment periods (ddeb, dfin), number of employers
   - **Access:** Linked via pseudonymized social security numbers
   - **Use:** Data validation and plausibility checks for LSE-reported wages; handles multi-employer cases

**Data Linkage:** All three datasets are linked at the individual level using 
pseudonymized social security numbers (AHV_N/PSEUDOVN/noavs).

**Data Cleaning:** The raw data underwent extensive cleaning following standard 
LSE practices (see DATA_CLEANING.md). Between 13% and 27% of observations were 
removed due to missing occupation information; additional 15-20% excluded through 
data quality filters.

### Publicly Available Data

**Productivity Statistics (Wachstums- und Produktivitätsstatistik, WPS)**
- **Source:** Swiss Federal Statistical Office (Bundesamt für Statistik)
- **Years:** 2012–2020 (annual)
- **Variables:** Sectoral productivity measures, value added per worker
- **Classification:** NOGA 2008 (General Classification of Economic Activities)
- **Access:** Publicly available at https://www.bfs.admin.ch/
- **Direct URL:** [Add specific BFS link to WPS data]

---

## Key Constructed Variables

All analysis uses variables constructed from the raw FSO data sources. 
Key derived measures include:

- **Gender-specific labor supply ratios** (Lm/Lf) by sector, region, and year
- **Gender-specific wage ratios** (wm/wf) by sector, region, and year
- **Bartik shift-share instruments** combining:
  - Regional sectoral shares (2012 baseline)
  - National sectoral growth rates (2012–2020)
  - Leave-one-out specifications
- **Skill composition controls** (tertiary education ratios by gender)

See `CODEBOOK.md` for complete variable definitions.

---

## Software Requirements

### R Environment
- **R version:** 4.0.0 or higher recommended
- **Required packages:** (See individual script headers for details)
  - Data manipulation: `dplyr`, `tidyr`, `data.table`
  - Econometrics: `AER`, `ivreg`, `fixest`, `lfe`
  - Visualization: `ggplot2`, `sf` (for maps)
  - Other: `haven`, `readr`

### Computational Requirements
- **Runtime:** Approximately 15–30 minutes on standard desktop (8GB RAM)
- **Operating System:** Platform-independent (tested on Windows, macOS, Linux)

---

## Empirical Methodology

This replication package implements a **Bartik shift-share instrumental variable strategy** 
following Borusyak et al. (2025) and Goldsmith-Pinkham et al. (2020).

### Identification Strategy

**Research Question:** What is the elasticity of substitution between male and 
female labor within sectors?

**Challenge:** Endogeneity of labor supply changes to wage outcomes

**Solution:** Instrument for regional sectoral labor supply using:
- **Shifts:** National sectoral growth rates (excluding own region)
- **Shares:** Regional sectoral composition in 2012 (pre-period)
- **Exogeneity source:** Shifts are exogenous to regional labor market conditions

### Estimation Approach

1. **Baseline OLS** (`3_1_get_naive_estimation.R`): Demonstrates endogeneity bias
2. **Bartik IV** (`3_2_get_iv.R`): Main specification with leave-one-out shifts
3. **Sector-specific IV** (`3_3_get_iv_sectors.R`): Heterogeneity analysis across 12 NOGA sectors

**Geographic Units:** 7 Swiss major regions (Grossregionen)  
**Sectoral Classification:** 12 NOGA-01 sectors (2 manufacturing, 10 services)  
**Time Period:** 2012–2020 (5 survey waves)

---

## Main Results

The analysis estimates the elasticity of substitution σ between male and female labor:

- **Manufacturing sectors:** σ = 4.13
- **Service sectors:** σ = 3.58
- **Individual sectors:** σ ranges from 3.24 to 3.97

These estimates exceed the theoretical threshold (σ > 2 + ε) required for 
gender-directed technical change, validating the GDSTC mechanism proposed in the paper.

---

## Citation

If you use this replication package, please cite:

```bibtex
@article{cozzi_goop_2026,
  author = {Cozzi, Guido and Goop, Theresa},
  title = {Gender-Directed Sector-Specific Technical Change},
  year = {2026},
  journal = {[Journal name forthcoming]},
  note = {Replication package available at [Zenodo DOI]}
}
```

---

## Data Access and Replication

**For researchers seeking to replicate these results:**

1. Review `DATA_ACCESS.md` for FSO data application procedures
2. Download publicly available productivity data from BFS
3. Follow step-by-step instructions in `REPLICATION_GUIDE.md`
4. Variable construction details in `CODEBOOK.md`

**Expected timeline for data access:** 3–6 months from application to approval

---

## License

**Code:** MIT License (see LICENSE file)  
**Data:** Not included (subject to FSO confidentiality agreement)  
**Documentation:** CC BY 4.0

---

## Contact

For questions about replication or data access:

**Theresa Goop**  
theresa.goop@unisg.ch

**Guido Cozzi**  
guido.cozzi@unisg.ch

---

## Acknowledgments

We thank the Swiss Federal Statistical Office for providing access to the 
confidential microdata under grant 100018_219686. We are grateful to 
Daron Acemoglu, Patricia Cortes, Michelle Rendall, and Bruno Caprettini for 
valuable feedback to the paper. Financial support from the 
Swiss National Science Foundation is gratefully acknowledged.

All remaining errors are our own.

---

**Last updated:** February 7, 2026  
**Repository version:** 1.0  
**DOI:** 10.5281/zenodo.18518747

