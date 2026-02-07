# Replication Guide

**Paper:** "Gender-Directed Sector-Specific Technical Change" (Cozzi & Goop, 2026)

This guide provides step-by-step instructions for replicating all empirical results in the paper.

---

## Prerequisites

### 1. Data Access

**Public data:** Download immediately (see Step 1 below)  
**Restricted data:** Apply for FSO access (3-6 months)

**See DATA_ACCESS.md for detailed application instructions.**

### 2. Software Requirements

**R version:** 4.0.0 or higher

**Required packages:**
```r
# Data manipulation
install.packages(c("dplyr", "tidyr", "data.table", "readr", "haven", "readxl"))

# Econometrics
install.packages(c("AER", "ivreg", "fixest", "lfe", "broom"))

# Visualization
install.packages(c("ggplot2", "sf", "scales"))

# Utilities
install.packages(c("stringr", "lubridate"))
```

### 3. Computational Resources

- **RAM:** 8 GB minimum, 16 GB recommended
- **Storage:** ~5 GB for data and outputs
- **Runtime:** 15-30 minutes for full replication on standard desktop

---

## File Structure Setup

Create the following directory structure:

```
project_root/
├── code/
│   ├── 0_setup.R                      # (you create this - see below)
│   ├── 1_get_loaded.R                 # Load and link LSE+STATPOP+ZAS
│   ├── 2_get_clean.R                  # Data quality filtering
│   ├── 3_get_all_variables.R          # Variable construction
│   ├── 1_get_descriptives.R           # (previously script "1")
│   ├── 2b_get_data_for_bartik_2012.R  # (previously script "2b")
│   ├── 3_1_get_naive_estimation.R     # Auxiliary estimation (minor)
│   ├── 3_2_get_iv.R                   # Main IV estimation + OLS baseline
│   └── 3_3_get_iv_sectors.R           # Sector-specific IV
├── data/
│   ├── raw/                           # FSO microdata (not included)
│   ├── public/                        # Public BFS productivity data
│   ├── joined/                        # Intermediate: linked datasets
│   ├── cleaned/                       # Intermediate: cleaned datasets
│   └── processed/                     # Final: analysis-ready datasets
├── output/
│   ├── tables/
│   ├── figures/
│   └── logs/
└── documentation/
    ├── README.md
    ├── CODEBOOK.md
    ├── DATA_ACCESS.md
    ├── DATA_CLEANING.md
    └── REPLICATION_GUIDE.md (this file)
```

---

## Step-by-Step Replication

### Step 0: Setup Script

Create a file `0_setup.R` with your file paths:

```r
# 0_setup.R
# Modify paths to match your local environment

# Working directories
wd <- "C:/your/project/path"  # Main project directory
wd_confidential <- "C:/your/secure/data/path"  # Secure directory for FSO data

# Create output directories if they don't exist
dir.create(paste0(wd, "/output/tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(paste0(wd, "/output/figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(paste0(wd, "/output/logs"), recursive = TRUE, showWarnings = FALSE)

# Create data directories (in secure location)
dir.create(paste0(wd_confidential, "/Joined_data"), recursive = TRUE, showWarnings = FALSE)
dir.create(paste0(wd_confidential, "/Joined_and_cleaned_raw_data"), recursive = TRUE, showWarnings = FALSE)
dir.create(paste0(wd_confidential, "/Data_for_IV"), recursive = TRUE, showWarnings = FALSE)

# Load required packages
library(dplyr)
library(tidyr)
library(readr)
library(readxl)
library(ggplot2)
library(AER)
library(fixest)
library(scales)
library(stringr)

# Set ggplot theme
theme_set(theme_minimal())

# Custom colors (University of St. Gallen branding)
hsggreen <- "#6CBF4B"
hsgdarkgreen <- "#5A9F3D"
hsggreyblue <- "#8FA3B0"
hsggreyblue2 <- "#5F7D8C"

# Define variable selections for data loading (see 1_get_loaded.R)
# LSE variables
my_cols_lse <- c("AHV_N", "MBLS", "IBGR", "IWAZ", "BEZSTD", "FS03", 
                 "NOG_2_08", "BERUFST", "VA_PS07_19", "ISCO19_2")
my_cols_lse_20 <- c("AHV_N", "MBLS", "IBGR", "IWAZ", "BEZSTD", "FS03",
                    "NOG_2_08_PUB", "BERUFST", "VA_PS07_19", "ISCO19_2")

# STATPOP variables
my_cols_statpop <- c("PSEUDOVN", "AGE", "SEX", "ARBKTO", "AUSBILD")

# SAKE variables (not used in main analysis)
my_cols_sake <- c("PSEUDOVN")  # Placeholder

# ZAS variables
my_cols_zas <- c("noavs", "mrevcot", "ddeb", "dfin")

# Define wage thresholds (calculated from data, but set here for reference)
# These will be calculated dynamically in cleaning script
lower <- NULL  # Will be set to median(MBLS) / 3
upper <- NULL  # Will be set to median(MBLS) * 15

# Define regions for mapping
my_region <- c("Région Lémanique", "Espace Mittelland", "Nordwestschweiz",
               "Ostschweiz", "Ticino", "Zentralschweiz", "Zürich")


### Step 1: Download Public Data

**BFS Productivity Statistics:**

1. Visit: https://www.bfs.admin.ch/
2. Navigate: *Themen* → *Volkswirtschaft* → *Volkswirtschaftliche Gesamtrechnung* → *Wachstum und Produktivität*
3. Download tables for years 2012-2020
4. Save to: `data/public/productivity_2012_2020.xlsx` (or similar name)

**Alternative:** The productivity data is used only in the naive OLS specification. 
If unavailable, you can skip Step 3.1 and proceed directly to IV estimation.

### Step 2: Obtain FSO Restricted Data

**Timeline:** 3-6 months

Follow instructions in **DATA_ACCESS.md** to apply for:
- Swiss Earnings Structure Survey (LSE) 2012, 2014, 2016, 2018, 2020
- Central Compensation Office (ZAS) administrative wage data 2012-2020

Once approved, FSO will provide:
- Linked microdata file(s)
- Codebook
- Data use agreement

**Save received data to:** `data/raw/` (secure directory)

**Expected filename:** `final_lse_statpop_zas_allyears.rds` (or as provided by FSO)

## Step-by-Step Replication

### Step 0: Setup Script

Create a file `0_setup.R` with your file paths (see template above). 
This file defines all paths and loads required packages.

### Step 1: Download Public Data

**BFS Productivity Statistics:**

1. Visit: https://www.bfs.admin.ch/
2. Navigate: *Themen* → *Volkswirtschaft* → *Volkswirtschaftliche Gesamtrechnung* → *Wachstum und Produktivität*
3. Download tables for years 2012-2020
4. Save to: `data/public/productivity_2012_2020.xlsx` (or similar name)

**Note:** The productivity data is used only in auxiliary OLS specifications. 
You can proceed without it for main IV results.

### Step 2: Obtain FSO Restricted Data

**Timeline:** 3-6 months

Follow instructions in **DATA_ACCESS.md** to apply for:
- Swiss Earnings Structure Survey (LSE) 2012, 2014, 2016, 2018, 2020
- STATPOP (population register) 2012-2020
- Central Compensation Office (ZAS) administrative wage data 2012-2020

Once approved, FSO will provide linked pseudonymized microdata files.

**Save received data to:** `data/raw/` (secure directory as specified in `wd_confidential`)

**Expected files:**
- `LSE[YEAR]_[PROJECT]_pseudo.csv` (5 files, one per survey year)
- `statpop_[YEAR]_[PROJECT]_pseudo.csv` (9 files, annual)
- `cibasecot[YEAR]_pseudo.csv` (9 files, annual ZAS data)
- Optional: `SAKE[YEAR]_pseudo.csv` (not used in main analysis)

### Step 3: Data Preparation Scripts

#### 3.1 Load and Link Data

**Script:** `1_get_loaded.R`

**What it does:**
- Loads LSE, STATPOP, and ZAS raw CSV files
- Cleans ZAS data (removes implausible months, calculates monthly wages)
- Aggregates ZAS across multiple employers
- Links all three datasets by pseudonymized ID (AHV_N / PSEUDOVN / noavs)
- Renames LSE 2020 sector variable for consistency

**Outputs (saved to `wd_confidential/Joined_data/`):**
- `joined_lse_statpop_zas_2012.rds`
- `joined_lse_statpop_zas_2014.rds`
- `joined_lse_statpop_zas_2016.rds`
- `joined_lse_statpop_zas_2018.rds`
- `joined_lse_statpop_zas_2020.rds`

**Run:**
```r
source("code/1_get_loaded.R")
```

**Expected runtime:** 1-2 hours

**Check:**
```r
# Verify files were created
list.files(paste0(wd_confidential, "/Joined_data"))

# Load one file to check structure
df_2012 <- readRDS(paste0(wd_confidential, "/Joined_data/joined_lse_statpop_zas_2012.rds"))
dim(df_2012)  # Should show ~1.8M observations
```

---

#### 3.2 Apply Data Quality Filters

**Script:** `2_get_clean.R`

**What it does:**
- Applies Filters A-E (see DATA_CLEANING.md for details):
  - Filter A: Remove missing FTE
  - Filter B: Remove implausible FTE (< 10% or > 150%)
  - ZAS validation: Cross-check LSE vs. ZAS wages
  - Filter C: Remove wages below threshold (< median/3)
  - Filter D: Remove wages above threshold (> median×15)
  - Filter E: Remove implausible hours (< 36 or > 80 per week)
- Calculates standardized hours and actual hours worked
- Renames variables to standard names

**Outputs (saved to `wd_confidential/Joined_data/`):**
- `cleaned_lse_statpop_zas_2012.rds`
- `cleaned_lse_statpop_zas_2014.rds`
- `cleaned_lse_statpop_zas_2016.rds`
- `cleaned_lse_statpop_zas_2018.rds`
- `cleaned_lse_statpop_zas_2020.rds`

**Run:**
```r
source("code/2_get_clean.R")
```

**Expected runtime:** 20-30 minutes

**Check:**
```r
df_clean_2012 <- readRDS(paste0(wd_confidential, "/Joined_data/cleaned_lse_statpop_zas_2012.rds"))
dim(df_clean_2012)  # Should show ~1.7M observations (after filters)

# Check key variables exist
names(df_clean_2012)  # Should include: monthlywage, hours, hours_std, sex, age, etc.
```

---

#### 3.3 Construct Analysis Variables

**Script:** `3_get_all_variables.R`

**What it does:**
- Adds year variable to each dataset
- Checks and reports missing occupation rates by year
- Removes observations with missing occupation codes (ISCO == -9)
- Maps cantons to major regions (7 Grossregionen)
- Maps NOGA 2-digit sectors to NOGA 1-digit aggregations
- Combines small sector categories (B-E, L/N, R/S)
- Excludes sectors A (agriculture) and P (education)
- Calculates potential experience from age and education
- Combines all years into single analysis dataset

**Outputs (saved to `wd_confidential/Joined_and_cleaned_raw_data/`):**
- `final_lse_statpop_zas_2012.rds` (individual years)
- `final_lse_statpop_zas_allyears.rds` (combined, main file)
- `final_lse_statpop_zas_allyears_educationiscomplete.rds` (with experience variable)

**Run:**
```r
source("code/3_get_all_variables.R")
```

**Expected runtime:** 5-10 minutes

**Check:**
```r
df_final <- readRDS(paste0(wd_confidential, "/Joined_and_cleaned_raw_data/final_lse_statpop_zas_allyears.rds"))
dim(df_final)  # Should show ~5.7-6.3M observations across all years

# Check final structure
table(df_final$year)  # Should show observations for 2012, 2014, 2016, 2018, 2020
table(df_final$sector_01)  # Should show 12 sectors
table(df_final$region)  # Should show 7 regions
```

---

### Step 4: Descriptive Analysis

**Script:** `1_get_descriptives.R` (note: runs after data preparation)

**What it does:**
- Loads final cleaned dataset
- Creates sector aggregation variables (Manufacturing vs. Services)
- Generates descriptive plots by sector and gender
- Creates time series of wage and labor supply ratios

**Outputs:**
- `output/figures/wages_sector_01.png` → Appendix Figure A.4
- `output/figures/wages_sector_ter.png` → Appendix Figure A.2
- `output/figures/hours_worked_sector_01.png` → Appendix Figure A.3
- `output/figures/hours_worked_sector_ter.png` → Appendix Figure A.1
- `output/figures/ratios_by_year.png` → Figure 1 (main paper)

**Run:**
```r
source("code/1_get_descriptives.R")
```

**Expected runtime:** 2-5 minutes

---

### Step 5: Construct Bartik Instruments

**Script:** `2b_get_data_for_bartik_2012.R`

**What it does:**
- Calculates regional sectoral shares (z_{j,r,s,2012}) in base year 2012
- Calculates national sectoral shifts (g_{j,s,t}) from 2012 baseline
- Constructs leave-one-out shifts (excluding each region)
- Creates Bartik instruments (standard and LOO)
- Calculates aggregated shift version (economy-wide growth)
- Computes outcome variables (wage ratios, labor supply ratios)
- Constructs control variables (skill composition by gender)
- Merges all components into estimation-ready datasets

**Outputs (saved to `wd_confidential/Data_for_IV/`):**
- `data_for_iv_by_region.rds` → Main dataset (12 sectors × 7 regions × 4 years)
- `data_for_iv_by_region_tertiary.rds` → Manufacturing/Services aggregation
- `data_with_sector_labels.rds` → Full microdata with sector labels

**Run:**
```r
source("code/2b_get_data_for_bartik_2012.R")
```

**Expected runtime:** 5-10 minutes

**Check:**
```r
df_iv <- readRDS(paste0(wd_confidential, "/Data_for_IV/data_for_iv_by_region.rds"))
dim(df_iv)  # Should be 336 rows (7 regions × 12 sectors × 4 years)

# Check key variables
summary(df_iv$loo_bartik_log)  # Should show variation, no NAs
summary(df_iv$wage_ratio)  # Log wage ratios
summary(df_iv$hours_ratio)  # Log labor supply ratios
```

---

### Step 6: Main IV Estimation

**Script:** `3_2_get_iv.R`

**What it does:**
- **OLS baseline estimation** (line 15): Simple OLS of wage ratio on labor supply ratio
- Bartik IV estimation (standard shifts)
- **Bartik IV LOO** (leave-one-out, main specification)
- Bartik IV with aggregated shifts (robustness)
- Computes elasticity of substitution σ for different ε values
- Generates regression tables and figures

**Corresponds to:** 
- Paper Table 3 (all four specifications including OLS in column 1)
- Paper Figure 4 (σ as function of ε)
- Paper Figure 5 (Manufacturing vs. Services)

**Run:**
```r
source("code/3_2_get_iv.R")
```

**Expected runtime:** 2-5 minutes

**Outputs:**
- `output/tables/table3_main_results.txt`
- `output/figures/figure4_elasticity_by_epsilon.png`
- `output/figures/figure5_manuf_services.png`

**Check key results:**
```r
# OLS coefficient (biased, should be ~0.951)
# Bartik IV LOO coefficient (should be ~0.903)
# Implied σ for ε=0.1 (should be ~3.37)
```

---

### Step 7: Sector-Specific IV Estimation

**Script:** `3_3_get_iv_sectors.R`

**What it does:**
- Estimates Bartik IV separately for Manufacturing and Services
- Estimates Bartik IV for each of 12 individual NOGA sectors
- Computes sector-specific elasticities of substitution
- Generates comparison plots across sectors

**Corresponds to:** 
- Paper Table 4 (Manufacturing vs. Services)
- Paper Table 5 (Individual sectors)
- Paper Figure 6 (Sector heterogeneity)

**Run:**
```r
source("code/3_3_get_iv_sectors.R")
```

**Expected runtime:** 5-10 minutes

**Outputs:**
- `output/tables/table4_manufacturing_services.txt`
- `output/tables/table5_individual_sectors.txt`
- `output/figures/figure6_sector_heterogeneity.png`

**Check key results:**
```r
# Manufacturing: σ ≈ 4.13
# Services: σ ≈ 3.58
# Individual sectors: σ ranges from 3.24 to 3.97
```

---

### Step 8 (Optional): Naive/Auxiliary Estimation

**Script:** `3_1_get_naive_estimation.R`

**What it does:**
- Contains auxiliary estimation mentioned in paper (not the main OLS baseline)
- This is a **minor helper script** referenced in paper but not part of main results

**Note:** This script is included for completeness but is not essential for 
replicating main results. The main OLS baseline is in `3_2_get_iv.R` (Step 6).

---

## Reproducibility Statement

This replication package is designed to enable exact numerical replication of 
all main results and figures in the paper, subject to access to the 
restricted FSO microdata.

**Reproducibility level:** 
- **Public data only:** Figures 1, 2, 3, Appendix A (descriptive maps/plots)
- **With FSO data access:** All tables, figures, and numerical results

**Deviations from exact replication:**
 Output may require FSO approval before publication (aggregated results only)

---

## Citation

If you use this replication package, please cite:

```bibtex
@misc{cozzi_goop_2026_replication,
  author = {Cozzi, Guido and Goop, Theresa},
  title = {Replication Package for: Gender-Directed Sector-Specific Technical Change},
  year = {2026},
  publisher = {Zenodo},
  doi = {[DOI to be assigned]},
  url = {https://github.com/theresagoop/gdstc-cozzi-goop}
}
```

---

**Last updated:** February 2, 2026  
**Replication package version:** 1.0  
**Corresponds to paper version:** January 25, 2026

---

## Appendix: Session Info Template

After successful replication, run the following to document your environment:

```r
writeLines(capture.output(sessionInfo()), 
           "output/logs/sessionInfo.txt")
```

This creates a log of your R version and all loaded packages for reproducibility documentation.
