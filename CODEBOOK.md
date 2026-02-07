# Codebook: Variable Definitions and Construction

**Replication Package for:** "Gender-Directed Sector-Specific Technical Change" (Cozzi & Goop, 2026)

This codebook documents all variables used in the empirical analysis, 
including raw FSO data variables, publicly available productivity data, 
and constructed analytical variables.

---

## Table of Contents

1. [Raw FSO Variables](#raw-fso-variables)
2. [Public Productivity Data](#public-productivity-data)
3. [Geographic and Sector Classifications](#geographic-and-sector-classifications)
4. [Constructed Labor Market Variables](#constructed-labor-market-variables)
5. [Bartik Instrument Components](#bartik-instrument-components)
6. [Outcome and Control Variables](#outcome-and-control-variables)

---

## 1. Raw FSO Variables

These variables come directly from the Swiss Earnings Structure Survey (LSE) and Central Compensation Office (ZAS) datasets.

### Individual-Level Variables (LSE)

| Variable | Description | Source | Values/Units |
|----------|-------------|--------|--------------|
| `monthlywage` | Monthly gross wage (standardized to full-time equivalent) | LSE | CHF |
| `hours` | Weekly hours worked | LSE | Hours/week |
| `sex` | Gender | LSE | 1 = Male, 2 = Female |
| `year` | Survey year | LSE | 2012, 2014, 2016, 2018, 2020 |
| `sector_01` | Economic sector (NOGA 2008, 1-digit) | LSE | See Section 3 |
| `region` | Major region (Grossregion) | LSE | See Section 3 |
| `AUSBILD` | Education level | LSE | 1-4 = Tertiary, 5+ = Non-tertiary |

### Data Cleaning Notes

**Exclusion criteria applied (see paper Section 5.1):**
- Work time percentage < 20% or > 150%
- Weekly hours < 36 or > 80
- Standardized gross wage < 1/3 median or > 15× median (outlier removal)
- Missing occupation information (13–27% of observations per year)

**Final sample:** 5,730,140 individual-year observations across 2012–2020

---

## 2. Public Productivity Data

### Wachstums- und Produktivitätsstatistik (WPS)

| Variable | Description | Source | Values/Units |
|----------|-------------|--------|--------------|
| `Ps,t` | Sectoral productivity (value added per worker) | BFS WPS | CHF/worker |
| `sector` | Economic sector | BFS WPS | NOGA 2008 classification |
| `year` | Calendar year | BFS WPS | 2012–2020 (annual) |

**Access:** Freely available at https://www.bfs.admin.ch/ (Navigate: Themen → Volkswirtschaft → Wachstum und Produktivität)

**Usage in analysis:** Included as control variable `log(Ps,t)` 
in auxiliary OLS regressions (Section 5.1, naive estimation)

---

## 3. Geographic and Sector Classifications

### Geographic Units

**Swiss Major Regions (Grossregionen)** — 7 regions used in analysis:

| Code | Region Name | Cantons Included |
|------|-------------|------------------|
| 1 | Région Lémanique | VD, VS, GE |
| 2 | Espace Mittelland | BE, FR, SO, NE, JU |
| 3 | Nordwestschweiz | BS, BL, AG |
| 4 | Zürich | ZH |
| 5 | Ostschweiz | GL, SH, AR, AI, SG, GR, TG |
| 6 | Zentralschweiz | LU, UR, SZ, OW, NW, ZG |
| 7 | Ticino | TI |

**Note:** These regions provide sufficient geographic variation while 
maintaining sample sizes adequate for sectoral analysis.

### Sector Classification

**NOGA 2008 (1-digit level)** — 12 sectors used in analysis:

| Code | Sector Name | Broad Category |
|------|-------------|----------------|
| B-E | Processing/energy supply | Manufacturing |
| F | Construction | Manufacturing |
| G | Wholesale and retail trade, repair of motor vehicles and motorcycles | Services |
| H | Transportation and storage | Services |
| I | Accommodation and food service activities | Services |
| J | Information and communication | Services |
| K | Financial and insurance activities | Services |
| L/N | Real estate, other economic services | Services |
| M | Professional, scientific and technical activities | Services |
| O | Public administration and defence, compulsory social security | Services |
| Q | Human health and social work activities | Services |
| R/S | Arts, entertainment, other services | Services |

**Aggregation levels used:**

1. **Individual sectors** (12 NOGA-01 codes) — for sector-specific elasticity estimates
2. **Manufacturing** (B-E, F) vs. **Services** (G, H, I, J, K, L/N, M, O, Q, R/S) — for broader analysis

**Variable names in code:**
- `sector_01`: Individual NOGA-01 code
- `noga_01_description`: Full sector name (text)
- `sector_tertiary`: "secondary" (manufacturing) or "tertiary" (services)
- `tertiary_description`: "Manufacturing" or "Services"

---

## 4. Constructed Labor Market Variables

### Gender-Specific Labor Supply

**Total hours worked** by gender, sector, region, and year:

```r
Lj,r,s,t = sum(hours) for sex j, region r, sector s, year t
```

| Variable | Definition | Unit | Aggregation |
|----------|------------|------|-------------|
| `hours_men` | Total hours worked by men | Million hours/year | Region × Sector × Year |
| `hours_women` | Total hours worked by women | Million hours/year | Region × Sector × Year |
| `hours_ratio` | Log male-to-female hours: log(hours_men / hours_women) | Log ratio | Region × Sector × Year |

**Code location:** `2b_get_data_for_bartik_2012.R`, function `get_y()`

### Gender-Specific Wages

**Total wages** by gender, sector, region, and year:

```r
wj,r,s,t = sum(monthlywage) for sex j, region r, sector s, year t
```

| Variable | Definition | Unit | Aggregation |
|----------|------------|------|-------------|
| `wage_men` | Total monthly wages paid to men | CHF million/year | Region × Sector × Year |
| `wage_women` | Total monthly wages paid to women | CHF million/year | Region × Sector × Year |
| `wage_ratio` | Log male-to-female wage: log(wage_men / wage_women) | Log ratio | Region × Sector × Year |

**Code location:** `2b_get_data_for_bartik_2012.R`, function `get_y()`

**Note:** These are **aggregated sectoral wages**, not individual wage rates. They reflect both employment levels and wage rates.

---

## 5. Bartik Instrument Components

The Bartik instrument exploits variation in regional exposure to national 
sectoral labor supply changes. Construction follows Borusyak et al. (2025).

### Shares (zj,r,s,2012)

**Regional sectoral shares in base year 2012:**

```
zj,r,s,2012 = Lj,r,s,2012 / Lj,r,2012
```

Where:
- `Lj,r,s,2012` = Hours worked by gender j in region r, sector s in 2012
- `Lj,r,2012` = Total hours worked by gender j in region r (all sectors) in 2012

| Variable | Definition | Unit | Fixed at |
|----------|------------|------|----------|
| `share_2012_m` | Male sectoral share: hours worked by men in sector s as fraction of total male labor in region r | Proportion [0,1] | 2012 |
| `share_2012_w` | Female sectoral share: hours worked by women in sector s as fraction of total female labor in region r | Proportion [0,1] | 2012 |

**Code location:** `2b_get_data_for_bartik_2012.R`, function `get_shares_2012()`

**Geographic distribution:** See Appendix A.3 of paper for maps showing regional shares by sector.

### Shifts (gj,s,t)

**National sectoral growth (2012 baseline):**

```
gj,s,t = Lj,s,t - Lj,s,2012
```

Where:
- `Lj,s,t` = National (all-region) hours worked by gender j in sector s in year t
- `Lj,s,2012` = National hours worked by gender j in sector s in base year 2012

| Variable | Definition | Unit | Time-varying |
|----------|------------|------|--------------|
| `shift_m` | Change in national male labor supply in sector s since 2012 | Million hours | Yes (2014, 2016, 2018, 2020) |
| `shift_w` | Change in national female labor supply in sector s since 2012 | Million hours | Yes (2014, 2016, 2018, 2020) |
| `growth_m` | Proportional growth: shift_m / national_2012_m | Growth rate | Yes |
| `growth_w` | Proportional growth: shift_w / national_2012_w | Growth rate | Yes |

**Code location:** `2b_get_data_for_bartik_2012.R`, function `get_shifts()`

**Exogeneity source:** National sectoral trends are assumed exogenous to individual regional labor market conditions.

### Leave-One-Out Shifts (g⁻ʳj,s,t)

**National sectoral growth excluding own region:**

```
g⁻ʳj,s,t = L⁻ʳj,s,t - L⁻ʳj,s,2012

where L⁻ʳj,s,t = Lj,s,t - Lj,r,s,t (national excluding region r)
```

| Variable | Definition | Unit | Time-varying |
|----------|------------|------|--------------|
| `loo_shift_m` | LOO change in national male labor supply in sector s | Million hours | Yes |
| `loo_shift_w` | LOO change in national female labor supply in sector s | Million hours | Yes |
| `loo_growth_m` | LOO proportional growth for men | Growth rate | Yes |
| `loo_growth_w` | LOO proportional growth for women | Growth rate | Yes |

**Purpose:** Addresses potential mechanical correlation between national shifts and regional outcomes when regions are large.

**Code location:** `2b_get_data_for_bartik_2012.R`, function `get_loo_shifts()`

**Primary specification:** LOO shifts are used in main results (Table 3, column 3).

### Bartik Instruments

**Standard Bartik instrument:**

```
Bj,r,s,t = zj,r,s,2012 × gj,s,t
```

**Leave-one-out Bartik instrument:**

```
B⁻ʳj,r,s,t = zj,r,s,2012 × g⁻ʳj,s,t
```

**Ratio instruments (used in estimation):**

| Variable | Definition | Formula | Specification |
|----------|------------|---------|---------------|
| `bartik_log` | Log Bartik ratio | log(Bm,r,s,t) / log(Bw,r,s,t) | Standard |
| `loo_bartik_log` | Log LOO Bartik ratio | log(B⁻ʳm,r,s,t) / log(B⁻ʳw,r,s,t) | **Main (preferred)** |
| `agg_bartik` | Aggregated shifts version | Uses economy-wide growth instead of sector-specific | Robustness check |

**Log transformation:** Following Borusyak et al. (2025), when using log-transformed endogenous variables, we use:

```r
bartik_m_log = share_2012_m * log(1 + growth_m)
bartik_w_log = share_2012_w * log(1 + growth_w)
bartik_log = bartik_m_log / bartik_w_log
```

**Code location:** `2b_get_data_for_bartik_2012.R`, functions `get_bartik()` and `get_bartik_loo()`

### Aggregated Shifts (Robustness)

**Economy-wide labor supply trends (not sector-specific):**

| Variable | Definition | Purpose |
|----------|------------|---------|
| `agg_growth_m` | National male labor supply growth (all sectors) | Conservative IV specification |
| `agg_growth_w` | National female labor supply growth (all sectors) | Conservative IV specification |
| `agg_bartik` | Bartik using aggregated shifts | Addresses sector-specific endogeneity concern |

**Motivation:** If sector-specific shifts themselves are endogenous to GDSTC, using only economy-wide variation provides a conservative test.

**Results:** Table 3, column 4 ("Bartik IV Agg")

---

## 6. Outcome and Control Variables

### Outcome Variable (Second Stage)

| Variable | Definition | Formula | Unit |
|----------|------------|---------|------|
| `wage_ratio` | Log male-to-female wage ratio | log(wage_men / wage_women) | Log ratio |

**Interpretation:** A value of 0.1 indicates men earn approximately 10% more than women in that region-sector-year.

**Regression equation (second stage):**

```r
wage_ratio ~ β0 + β1 * hours_ratio + controls
```

### Endogenous Regressor (First Stage)

| Variable | Definition | Formula | Unit |
|----------|------------|---------|------|
| `hours_ratio` | Log male-to-female labor supply ratio | log(hours_men / hours_women) | Log ratio |

**Regression equation (first stage):**

```r
hours_ratio ~ γ0 + γ1 * loo_bartik_log + controls
```

### Control Variables

**Skill composition control:**

| Variable | Definition | Formula | Purpose |
|----------|------------|---------|---------|
| `frac_skilled_men` | Fraction of men with tertiary education | n(AUSBILD ∈ {1,2,3,4}) / n(all men) | Control for educational upgrading |
| `frac_skilled_women` | Fraction of women with tertiary education | n(AUSBILD ∈ {1,2,3,4}) / n(all women) | Control for educational upgrading |
| `frac_skilled_ratio` | Male-to-female skill ratio | frac_skilled_men / frac_skilled_women | **Main control variable** |

**Educational categories:**
- AUSBILD 1-4: Tertiary education (university, applied sciences, advanced professional)
- AUSBILD 5+: Non-tertiary (vocational, secondary, or less)

**Code location:** `2b_get_data_for_bartik_2012.R`, function `get_skills()`

**Motivation:** Controls for differential educational upgrading by gender that could confound wage-labor supply relationship.

**Fixed effects:**

| Variable | Definition | Purpose |
|----------|------------|---------|
| Year FE | Dummy variables for each survey year | Absorb common time trends |
| Sector FE | Dummy variables for each sector | Absorb time-invariant sectoral characteristics |
| Year × Sector FE | Interactions | Absorb sector-specific time trends (main specification) |

**Implementation:** Year × Sector fixed effects are included in main Bartik IV specifications (Table 3, columns 3-4).

---

## Variable Construction Workflow

### Step 1: Load and Clean Raw Data
**Script:** `1_get_descriptives.R`
- Loads FSO microdata
- Applies data cleaning criteria
- Creates sector aggregation variables

### Step 2: Construct Bartik Components
**Script:** `2b_get_data_for_bartik_2012.R`
- Calculates shares (zj,r,s,2012)
- Calculates shifts (gj,s,t and g⁻ʳj,s,t)
- Constructs Bartik instruments
- Creates outcome and control variables
- Merges all components into estimation datasets

### Step 3: Estimation
**Scripts:**
- `3_1_get_naive_estimation.R` — OLS (biased)
- `3_2_get_iv.R` — Bartik IV (main results)
- `3_3_get_iv_sectors.R` — Sector-specific IV

---

## Data Structure

### Final estimation dataset structure:

**Unit of observation:** Region × Sector × Year

**Dimensions:**
- **Aggregated analysis:** 7 regions × 12 sectors × 4 years = 336 observations
- **Manufacturing analysis:** 7 regions × 2 sectors × 4 years = 56 observations
- **Services analysis:** 7 regions × 10 sectors × 4 years = 280 observations
- **Individual sector analysis:** 7 regions × 1 sector × 4 years = 28 observations each

**Key identifier variables:**
- `region` (1-7)
- `sector_01` (NOGA code) or `sector_tertiary` (secondary/tertiary)
- `year` (2014, 2016, 2018, 2020)

**Note:** 2012 is excluded from estimation as it is the base year for constructing shares and shifts.

---

## Missing Data

**Missing values:** Minimal after data cleaning. Any region-sector-year cells with <10 observations are suppressed for confidentiality.

**Handling in estimation:** Observations with missing Bartik instruments (due to zero employment in sector in 2012) are excluded. This affects primarily small sectors in small regions.

---

## Derived Parameter: Elasticity of Substitution (σ)

The coefficient β₁ from the second-stage regression relates to the elasticity of substitution σ through:

```
β₁ = (σ - 2 - ε) / (εσ + 1)
```

Where ε is the R&D cost elasticity parameter (assumed values: 0.1, 0.5, 1.0).

**Inversion formula to recover σ from β₁:**

```
σ = (β₁ + 2ε·β₁ + 1) / (1 - ε·β₁)
```

**Reported elasticities** (Table 4, Table 5) use ε = 0.1 unless otherwise noted.

**Code for σ calculation:** See paper Section 5.2 and Figure 4.

---

## Replication Notes

1. **Exact replication** requires access to confidential FSO microdata (see DATA_ACCESS.md)

2. **Variable naming conventions:**
   - Suffix `_m` or `_men` = Male/Men
   - Suffix `_w` or `_women` = Female/Women
   - Suffix `_ratio` = Male-to-female ratio
   - Suffix `_log` = Log-transformed
   - Prefix `loo_` = Leave-one-out specification

3. **Sector aggregation:**
   - Manufacturing = NOGA sectors B-E, F
   - Services = NOGA sectors G, H, I, J, K, L/N, M, O, Q, R/S

4. **Sample period:** 2012–2020, biannual observations

5. **Geographic coverage:** All seven major Swiss regions

---

## References

Borusyak, K., Hull, P., & Jaravel, X. (2025). A Practical Guide to Shift-Share Instruments. *Journal of Economic Perspectives*, 39(1), 181–204.

Goldsmith-Pinkham, P., Sorkin, I., & Swift, H. (2020). Bartik Instruments: What, When, Why, and How. *American Economic Review*, 110(8), 2586–2624.

---

**Last updated:** February 2, 2026 
**Codebook version:** 1.0  
**Corresponds to paper version:** January 25, 2026
