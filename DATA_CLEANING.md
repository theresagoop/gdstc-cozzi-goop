# Data Cleaning Documentation

**Replication Package:** Gender-Directed Sector-Specific Technical Change (Cozzi & Goop, 2026)

This document provides detailed information about data cleaning procedures 
applied to the raw FSO microdata before analysis.

---

## Overview

The analysis uses three linked FSO datasets:
1. **Swiss Earnings Structure Survey (LSE)** - wage and employment data
2. **STATPOP** - demographic characteristics
3. **Central Compensation Office (ZAS)** - administrative wage validation data

All three datasets are linked at the individual level using pseudonymized 
identifiers (AHV_N/PSEUDOVN).

**Initial sample:** ~1.6–2.1 million observations per survey year (raw LSE)  
**Final sample:** 5,730,140 individual-year observations (2012–2020 combined)  
**Exclusion rate:** 13–27% per year (varies by survey year)

**Data cleaning reference:** Procedures follow standard LSE practices 
documented in BFS (2017) *Lohnanalysen LSE 2014* 
(https://www.buerobass.ch/fileadmin/Files/2017/BFS_2017_LohnanalysenLSE2014.pdf)

---

## Data Sources and Linkage

### Three Linked Datasets

**1. LSE (Lohnstrukturerhebung):**
- Employer-reported survey of wages and employment
- Variables: MBLS (monthly wage), IBGR (FTE percentage), IWAZ (monthly hours), 
BEZSTD (weekly hours), FS03 (wage type), NOG_2_08 (NOGA sector), 
BERUFST (professional position), VA_PS07_19 (skill level), ISCO19_2 (occupation)

**2. STATPOP (Statistik der Bevölkerung und Haushalte):**
- Population registry data
- Variables: AGE, SEX, ARBKTO (work canton), education level (AUSBILD)
- Linkage: AHV_N (social security number, pseudonymized) = PSEUDOVN in STATPOP

**3. ZAS (Zentrale Ausgleichsstelle):**
- Administrative social security contribution records
- Variables: noavs (social security number), mrevcot (total reported income), 
ddeb (start month), dfin (end month)
- Purpose: Validation and plausibility checks for LSE-reported wages
- Multi-employer handling: Aggregates income across all employers for individuals

### Linkage Procedure

**Step 1: Clean ZAS data** (`1_get_loaded.R`):
```r
# Remove implausible month values
datf_zas <- datf_zas %>% filter(ddeb <= 12, dfin <= 12)

# Calculate monthly wage from total income
datf_zas$periods <- dfin - ddeb + 1
datf_zas$monthly_wage <- mrevcot / periods

# Aggregate across employers
datf_zas_clean <- datf_zas %>%
  group_by(noavs) %>%
  summarise(
    n_employers = n(),
    monthly_wage_all_employers = sum(monthly_wage)
  )
```

**Step 2: Link LSE + STATPOP + ZAS** (`1_get_loaded.R`):
```r
# Join LSE and STATPOP
datf_joined <- inner_join(lse, statpop, by = c("AHV_N" = "PSEUDOVN"))

# Add ZAS validation data
datf_full <- inner_join(datf_joined, zas_clean, by = c("AHV_N" = "noavs"))
```

---

## Cleaning Criteria

The cleaning function (`clean_joined_data()` in `2_get_clean.R`) 
applies the following filters sequentially:

### Filter A: Missing FTE Information

**Variable:** IBGR (Beschäftigungsgrad, full-time equivalent percentage)

**Exclusion rule:**
```r
datf <- datf %>% filter(!is.na(IBGR))
```

**Rationale:** FTE is essential for standardizing wages and hours  
**Observations excluded:** <1% per year

---

### Filter B: Implausible FTE Values (20%–150%)

**Variable:** IBGR, with handling for different wage reporting types (FS03)

**Exclusion rules:**
```r
# Monthly earners
datf <- datf %>% 
  filter(is.na(FS03) | FS03 %in% c(3,5) |
         (FS03 %in% c(1,2,4) & IBGR >= 0.1 & IBGR <= 1.5))

# Hourly earners with reported hours
datf <- datf %>%
  filter(is.na(FS03) | FS03 %in% c(1,2,4) |
         (FS03 %in% c(3,5) & BEZSTD != 0) |
         (FS03 %in% c(3,5) & BEZSTD == 0 & IBGR >= 0.1 & IBGR <= 1.5))

# Missing wage type
datf <- datf %>%
  filter(FS03 %in% c(3,5) | FS03 %in% c(1,2,4) |
         (is.na(FS03) & IBGR >= 0.1 & IBGR <= 1.5))
```

**Rationale:**
- **Lower bound (10% = 0.1):** Excludes very marginal employment
- **Upper bound (150% = 1.5):** Allows documented overtime; higher values likely data errors
- **Wage type specific:** Different rules for monthly vs. hourly earners to 
account for reporting differences

**Observations excluded:** ~3–5% per year

---

### ZAS Validation: Multi-Employer Cross-Check

**Purpose:** Identify implausible wage discrepancies when individuals have multiple employers

**Exclusion rule:**
```r
# Calculate wage difference
datf$wage_diff <- (MBLS - monthly_wage_all_employers) / monthly_wage_all_employers

# Exclude if LSE wage > 2× ZAS wage for multi-employer individuals
datf <- datf %>%
  filter(!(n_employers > 1 & wage_diff > 1))
```

**Rationale:** 
- LSE reports wage from single employer; ZAS sums all employers
- For multi-employer workers, LSE wage should not exceed 2× total ZAS income
- Protects against misreported primary employment

**Observations excluded:** ~1–2% per year

---

### Filter C: Minimum Wage Threshold

**Variable:** MBLS (monthly gross wage, standardized to FTE)

**Exclusion rules:**
```r
# Calculated: lower = median(MBLS) / 3

datf <- datf %>%
  filter(MBLS >= lower,
         !(n_employers == 1 & monthly_wage_all_employers < lower))
```

**Threshold:** Approximately CHF 2,167 (1/3 of median monthly wage)  
**Rationale:** Removes data entry errors and extremely low wages likely to be mis-coded  
**Observations excluded:** ~1% per year

---

### Filter D: Maximum Wage Threshold  

**Variable:** MBLS (monthly gross wage, standardized to FTE)

**Exclusion rules:**
```r
# Calculated: upper = median(MBLS) * 15

datf <- datf %>%
  filter(MBLS <= upper,
         !(n_employers == 1 & monthly_wage_all_employers > upper))
```

**Threshold:** Approximately CHF 97,530 (15× median monthly wage)  
**Rationale:** Removes extreme outliers and likely data errors while retaining top earners  
**Observations excluded:** ~1% per year

---

### Filter E: Standardized and Actual Hours

**Step 1: Calculate standardized weekly hours**

Hours standardized to full-time equivalent (40-hour week):

```r
# Monthly earners (FS03 in 1, 2, 4)
datf$hours_std[FS03 %in% c(1,2,4)] <- IWAZ * 4 / IBGR

# Hourly earners (FS03 in 3, 5)
datf$hours_std[FS03 %in% c(3,5)] <- BEZSTD / IBGR

# Missing wage type
datf$hours_std[is.na(FS03) & BEZSTD == 0] <- IWAZ * 4 / IBGR
datf$hours_std[is.na(FS03) & IWAZ == 0] <- BEZSTD / IBGR
```

**Step 2: Filter standardized hours (Part 1 of Filter E)**

```r
# Exclude Inf and NaN values
datf <- datf %>% filter(hours_std != "Inf", hours_std != "NaN")

# Require 36–80 hours per week (×4 for monthly)
datf <- datf %>% filter(hours_std >= 36*4, hours_std <= 80*4)
```

**Step 3: Calculate actual hours worked**

```r
# Monthly earners
datf$hours[FS03 %in% c(1,2,4)] <- IWAZ * 4

# Hourly earners  
datf$hours[FS03 %in% c(3,5)] <- BEZSTD

# Missing wage type
datf$hours[is.na(FS03) & BEZSTD == 0] <- IWAZ * 4
datf$hours[is.na(FS03) & IWAZ == 0] <- BEZSTD
```

**Step 4: Filter actual hours (Part 2 of Filter E)**

```r
datf <- datf %>% filter(hours <= 80*4)
```

**Rationale:**
- **36-hour minimum:** Focuses on near-full-time and full-time workers for comparability
- **80-hour maximum:** Excludes extreme values likely representing multiple jobs or errors
- **Standardized vs. actual:** Both must pass plausibility checks

**Observations excluded:** ~5–8% per year

---

### Missing ZAS Data

**Exclusion rule:**
```r
datf <- datf %>% filter(monthly_wage_all_employers > 0)
```

**Rationale:** ZAS data needed for validation; zero or missing indicates non-matched individuals  
**Observations excluded:** ~2–3% per year

---

## Final Variable Construction (`3_get_all_variables.R`)

After cleaning, additional variables are constructed:

### 1. Remove Missing Occupation Codes

**Variable:** occupation (ISCO-08 2-digit codes)

**Exclusion rule:**
```r
datf <- datf %>% filter(occupation != -9)
```

**Missing rates by year:**
- 2012: ~13%
- 2014: ~19%
- 2016: ~22%
- 2018: ~27%
- 2020: ~18%

**Rationale:** Occupation codes are essential for sector classification 
(NOGA codes link to ISCO). This is the **largest source of exclusions**.

**Why variation across years?** The LSE is employer-reported; 
completeness varies by survey wave quality.

---

### 2. Regional Classification

**Variable:** Region (Major region / Grossregion)

**Construction:**
```r
# Map canton (ARBKTO) to major region
regions <- list(
  "Région Lémanique" = c("VD", "VS", "GE"),
  "Espace Mittelland" = c("BE", "FR", "SO", "NE", "JU"),
  "Nordwestschweiz" = c("BS", "BL", "AG"),
  "Zürich" = c("ZH"),
  "Ostschweiz" = c("GL", "SH", "AR", "AI", "SG", "GR", "TG"),
  "Zentralschweiz" = c("LU", "UR", "SZ", "OW", "NW", "ZG"),
  "Ticino" = c("TI")
)

datf$region <- case_when(
  ARBKTO %in% regions$`Région Lémanique` ~ "Région Lémanique",
  ARBKTO %in% regions$`Espace Mittelland` ~ "Espace Mittelland",
  # ... etc
)
```

**Purpose:** Geographic variation for Bartik IV identification

---

### 3. Sector Aggregation

**Step 1: Map NOGA 2-digit to 1-digit codes**

Using official NOGA crosswalk (`isco_nace_noga.xlsx`):
```r
noga_mapping <- read_excel("isco_nace_noga.xlsx", sheet = "NOGA")

datf <- datf %>%
  left_join(noga_mapping %>% select(noga_02, noga_01, noga_01_description),
            by = c("sector" = "noga_02"))
```

**Step 2: Combine small categories**

```r
datf <- datf %>%
  mutate(sector_01 = case_when(
    sector_01 %in% c("B", "C", "D", "E") ~ "B-E",  # Manufacturing
    sector_01 %in% c("L", "N") ~ "L/N",            # Real estate + admin
    sector_01 %in% c("R", "S") ~ "R/S",            # Arts + other services
    TRUE ~ sector_01
  ))
```

**Step 3: Exclude sectors**

```r
datf <- datf %>%
  filter(!sector_01 %in% c("A", "P"))
```

**Excluded:**
- **A (Agriculture):** Only 786 observations; atypical employment
- **P (Education):** No comparable national hours worked data for teachers

**Final sectors (12 NOGA-01 codes):**
- Manufacturing: B-E, F
- Services: G, H, I, J, K, L/N, M, O, Q, R/S

---

### 4. Potential Experience

**Construction:**
```r
# Map education codes (AUSBILD) to typical years of schooling
training_years <- c(17, 15, 14, 15, 13, 12, 11, 7)  # By AUSBILD category

datf$training_years <- training_years[AUSBILD]
datf$experience <- pmax(age - training_years - 6, 0)  # Assume school starts at age 6
```

**Purpose:** Control variable for wage regressions (not used in main IV specifications)

---

### 5. Variable Renaming

**Final standardized names:**
```r
datf <- datf %>%
  rename(
    age = AGE,
    sex = SEX,
    monthlywage = MBLS,
    profposition = BERUFST,
    skillevel = VA_PS07_19,
    occupation = ISCO19_2,
    sector = NOG_2_08
  )
```

---

## Cleaning Workflow Summary

**Script execution order:**

1. **1_get_loaded.R** - Load and link LSE + STATPOP + ZAS
   - Clean ZAS data (remove implausible months, aggregate across employers)
   - Inner join three datasets by pseudonymized ID
   - Output: `joined_lse_statpop_zas_YYYY.rds` (one per year)

2. **2_get_clean.R** - Apply data quality filters
   - Filter A: Missing FTE
   - Filter B: Implausible FTE (10–150%)
   - ZAS validation: Multi-employer wage checks
   - Filter C: Minimum wage threshold
   - Filter D: Maximum wage threshold
   - Filter E: Standardized and actual hours (36–80 per week)
   - Output: `cleaned_lse_statpop_zas_YYYY.rds` (one per year)

3. **3_get_all_variables.R** - Construct analysis variables
   - Add year variable
   - Check and remove missing occupation codes (ISCO == -9)
   - Create regional classifications from cantons
   - Map sectors to NOGA-01 codes
   - Aggregate small sector categories
   - Exclude agriculture (A) and education (P)
   - Calculate potential experience
   - Combine all years into single dataset
   - Output: `final_lse_statpop_zas_allyears.rds`

---

## Code Location

**Data loading and linkage:** `1_get_loaded.R`  
**Data quality filtering:** `2_get_clean.R`  
**Variable construction:** `3_get_all_variables.R`

**All cleaning procedures are documented in the code with comments referencing filter names (A, B, C, D, E).**

---

## Cross-validation with ZAS Administrative Data

**Built into cleaning process:**
- ZAS data validates LSE-reported wages
- Individuals with >2× discrepancy (for multi-employer) are flagged and excluded
- Single-employer cases: Both LSE and ZAS wages must pass min/max thresholds

**Result:** Retained observations show strong LSE-ZAS wage concordance (within 10% for 90%+ of sample)

---

### Variable Name Changes Across Years

**Important:** LSE 2020 uses different variable name for sector:
```r
# Required rename for 2020 data
datf_lse20 <- datf_lse20 %>% rename(NOG_2_08 = NOG_2_08_PUB)
```

This is handled automatically in `1_get_loaded.R` (line 89).

---

## FSO Confidentiality Compliance

**Aggregated outputs only:**
- All published tables use cells with ≥10 observations
- Individual-level data never disclosed
- Exact exclusion counts may be rounded for confidentiality

**This cleaning documentation:**
- Describes procedures and criteria
- Does not disclose individual-level data patterns
- Compliant with FSO data use agreement for methodological transparency

---

## References

Bundesamt für Statistik (BFS). (2017). *Lohnanalysen LSE 2014*. Available at: https://www.buerobass.ch/fileadmin/Files/2017/BFS_2017_LohnanalysenLSE2014.pdf

Swiss Federal Statistical Office (BFS). (2021). *Methodological Documentation: Swiss Earnings Structure Survey*. Neuchâtel: Bundesamt für Statistik.

---

**Last updated:** February 7, 2026  
**Version:** 1.0  
**Corresponds to paper:** Cozzi & Goop (2026), "Gender-Directed Sector-Specific Technical Change"
