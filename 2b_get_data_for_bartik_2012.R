# Prepare data for Bartik instrument estimation #################################

# Not composition-adjusted #
# Base year = 2012 # 

# Clear environment --------------------------
rm(list=ls())

source("D:/PhD Docs/thesisgit/gender-directed-change/data/0_setup.R")

# Load data ----------------------------------
# All observations
df_raw <- readRDS(file = paste0(wd_confidential,
                                "/Joined_and_cleaned_raw_data/final_lse_statpop_zas_allyears.rds"))

# Add labels for secondary and tertiary sector
# Group workers
get_labels <- function(df) {
  df %>%
    mutate(sector_tertiary = case_when(
      sector_01 %in% c("B-E", "F") ~ "secondary",
      sector_01 %in% c("G", "H", "I", "J", "K", "L/N", "M", "O", "Q", "R/S") ~ "tertiary",
    )) %>%
    mutate(tertiary_description = case_when(
      sector_tertiary == "secondary" ~ "Manufacturing",
      sector_tertiary == "tertiary" ~ "Services"
    ))
} 

df_labels <- get_labels(df_raw)

# Get z: local industry shares in year t=2012 ----------------------------------
# Share = sector's share of regional employment (e.g., share of sector A in region 1)
get_shares_2012 <- function(my_sector_level, my_description) {
  df_labels %>% 
    filter(year==2012) %>%
    # Get region-sector labor supplies
    group_by(sex, {{my_sector_level}}, region, {{my_description}}) %>%
    summarise(hours_2012 = sum(hours)) %>%
    pivot_wider(names_from = sex, values_from = hours_2012) %>%
    rename(hours_2012_m = '1',
           hours_2012_w = '2') %>%
    mutate(hours_2012_tot = hours_2012_m + hours_2012_w) %>%
    
    # Get regional totals (sum over all sectors in region x)
    group_by(region) %>%
    mutate(region_hours_2012_w = sum(hours_2012_w),
           region_hours_2012_m = sum(hours_2012_m)) %>%
    ungroup() %>%
    
    # Calculate shares: z_{j,r,s,2012} = L_{j,r,s,2012} / L_{j,r,2012}
    mutate(
      share_2012_m = hours_2012_m / region_hours_2012_m,
      share_2012_w = hours_2012_w / region_hours_2012_w
    )
}

df_shares_2012_01 <- get_shares_2012(sector_01, noga_01_description)
df_shares_2012_ter <- get_shares_2012(sector_tertiary, tertiary_description)

# Get g: Growth rates (national-level sectoral labor supply growth) ------------
# ------------------------------------------------------------------------------

# Get g: National shifts by sector ---------------------------------------------
# Calculate national growth by sector
get_shifts <- function(my_sector_level, my_description) {
  # Step 1: Get national hours by sector-year (all regions)
  national_hours <- df_labels %>%
    group_by(sex, {{my_sector_level}}, {{my_description}}, 
             year) %>%
    summarise(national_hours = sum(hours), .groups = 'drop') %>%
    pivot_wider(names_from = sex, values_from = national_hours) %>%
    rename(national_m = '1', national_w = '2')
  
  # Step 2: Get regional hours by region-sector-year
  regional_hours <- df_labels %>%
    group_by(sex, {{my_sector_level}}, {{my_description}},  
             region, year) %>%
    summarise(regional_hours = sum(hours), .groups = 'drop') %>%
    pivot_wider(names_from = sex, values_from = regional_hours) %>%
    rename(regional_m = '1', regional_w = '2')
  
  # Step 3: Calculate shifts
  sector_string <- as.character(ensym(my_sector_level))
  desc_string <- as.character(ensym(my_description))
  
  regional_hours %>%
    left_join(national_hours, 
              by = c(sector_string, desc_string, "year")) %>%
    # Get 2012 baseline for each region-sector
    group_by(region, {{my_sector_level}}) %>%
    arrange(region, {{my_sector_level}}, year) %>%
    mutate(
      national_2012_m = national_m[year == 2012],
      national_2012_w = national_w[year == 2012]
    ) %>%
    ungroup() %>%
    # Calculate shift: g_{j,s,t} = L_{j,s,t} - L_{j,s,2012}
    mutate(
      shift_m = national_m - national_2012_m,
      shift_w = national_w - national_2012_w,
      # Calculate growth rates for reference
      growth_m = shift_m / national_2012_m,
      growth_w = shift_w / national_2012_w
    ) %>%
    filter(year != 2012)  # Remove 2012 (base year)
}

df_shifts_01 <- get_shifts(sector_01, noga_01_description)
df_shifts_ter <- get_shifts(sector_tertiary, tertiary_description)

# Get g: Leave-one-out national shifts -----------------------------------------
# For each region r, calculate national growth excluding region r
get_loo_shifts <- function(my_sector_level, my_description) {
  
  # Step 1: Get national hours by sector-year (all regions)
  national_hours <- df_labels %>%
    group_by(sex, {{my_sector_level}}, {{my_description}}, year) %>%
    summarise(national_hours = sum(hours), .groups = 'drop') %>%
    pivot_wider(names_from = sex, values_from = national_hours) %>%
    rename(national_m = '1', national_w = '2')
  
  # Step 2: Get regional hours by region-sector-year
  regional_hours <- df_labels %>%
    group_by(sex, {{my_sector_level}}, {{my_description}}, region, year) %>%
    summarise(regional_hours = sum(hours), .groups = 'drop') %>%
    pivot_wider(names_from = sex, values_from = regional_hours) %>%
    rename(regional_m = '1', regional_w = '2')
  
  # Step 3: Calculate leave-one-out national hours and shifts
  sector_string <- as.character(ensym(my_sector_level))
  desc_string <- as.character(ensym(my_description))
  
  regional_hours %>%
    left_join(national_hours, 
              by = c(sector_string, desc_string, "year")) %>%
    # LOO national = National - Regional (exclude own region)
    mutate(
      loo_national_m = national_m - regional_m,
      loo_national_w = national_w - regional_w
    ) %>%
    # Get 2012 baseline for each region-sector
    group_by(region, {{my_sector_level}}) %>%
    arrange(region, {{my_sector_level}}, year) %>%
    mutate(
      loo_national_2012_m = loo_national_m[year == 2012],
      loo_national_2012_w = loo_national_w[year == 2012]
    ) %>%
    ungroup() %>%
    # Calculate LOO shift: g^{-r}_{j,s,t} = L^{-r}_{j,s,t} - L^{-r}_{j,s,2012}
    mutate(
      loo_shift_m = loo_national_m - loo_national_2012_m,
      loo_shift_w = loo_national_w - loo_national_2012_w,
      # Calculate growth rates for reference
      loo_growth_m = loo_shift_m / loo_national_2012_m,
      loo_growth_w = loo_shift_w / loo_national_2012_w
    ) %>%
    filter(year != 2012)  # Remove 2012 (base year)
}

df_loo_shifts_01 <- get_loo_shifts(sector_01, noga_01_description)
df_loo_shifts_ter <- get_loo_shifts(sector_tertiary, tertiary_description)

# Get aggregated (over all sectors) national labor supplies
agg_hours <- df_labels %>% dplyr::filter(year != 2012) %>%
  group_by(sex, year) %>%
  summarise(hours = sum(hours)) %>%
  pivot_wider(names_from = sex, values_from = hours) %>%
  rename(agg_hours_m = '1',
         agg_hours_w = '2')

agg_growth_df <- agg_hours %>% 
  left_join(df_shifts_01 %>% group_by(year) %>% 
              summarise(agg_hours_2012_m = sum(national_2012_m),
                        agg_hours_2012_w = sum(national_2012_w)),
            by="year") %>%
  mutate(agg_growth_m = (agg_hours_m-agg_hours_2012_m)/agg_hours_2012_m,
         agg_growth_w = (agg_hours_w-agg_hours_2012_w)/agg_hours_2012_w)

# Bartik instrument variables --------------------------------------------------
# ------------------------------------------------------------------------------
# Get Bartik instrument --------------------------------------------------------
# B_{j,r,s,t} = z_{j,r,s,2012} × g_{j,s,t}
get_bartik <- function(shares_df, shifts_df, 
                       my_sector_level_str, my_description_str) {
  
  shares_df %>%
    dplyr::select({{my_sector_level_str}}, {{my_description_str}}, region,
                  share_2012_m, share_2012_w) %>%
    left_join(
      shifts_df %>% 
        dplyr::select({{my_sector_level_str}}, {{my_description_str}}, region, year,
                      shift_m, shift_w, growth_m, growth_w),
      by = c(my_sector_level_str, my_description_str, "region")
    ) %>%
    left_join(agg_growth_df, by = "year") %>%
    # Calculate Bartik
    mutate(
      # Using shifts (as in paper formula)
      bartik_m = share_2012_m * shift_m,
      bartik_w = share_2012_w * shift_w,
      
      # Alternative: using log growth rates (as in original code)
      bartik_m_log = share_2012_m * log(1 + growth_m),
      bartik_w_log = share_2012_w * log(1 + growth_w),
      
      # National aggregated shifts
      agg_bartik_m = share_2012_m * log((1+agg_growth_m)),
      agg_bartik_w = share_2012_w * log((1+agg_growth_w)),
      
      # Ratio instruments
      bartik = bartik_m / bartik_w,
      bartik_log = bartik_m_log / bartik_w_log,
      agg_bartik = agg_bartik_m / agg_bartik_w
      
    )
}

df_bartik_01 <- get_bartik(df_shares_2012_01, df_shifts_01, 
                           "sector_01", "noga_01_description")
df_bartik_ter <- get_bartik(df_shares_2012_ter, df_shifts_ter, 
                            "sector_tertiary", "tertiary_description")


# Get LOO Bartik instrument ----------------------------------------------------
# B^{LOO}_{j,r,s,t} = z_{j,r,s,2012} × g^{-r}_{j,s,t}
get_bartik_loo <- function(shares_df, shifts_df, 
                           my_sector_level_str, my_description_str) {
  
  shares_df %>%
    dplyr::select({{my_sector_level_str}}, {{my_description_str}}, region,
                  share_2012_m, share_2012_w) %>%
    left_join(
      shifts_df %>% 
        dplyr::select({{my_sector_level_str}}, {{my_description_str}}, region, year,
                      loo_shift_m, loo_shift_w, loo_growth_m, loo_growth_w),
      by = c(my_sector_level_str, my_description_str, "region")
    ) %>%
    # Calculate LOO Bartik
    mutate(
      # Using shifts (as in paper formula)
      loo_bartik_m = share_2012_m * loo_shift_m,
      loo_bartik_w = share_2012_w * loo_shift_w,
      
      # Alternative: using log growth rates (as in original code)
      loo_bartik_m_log = share_2012_m * log(1 + loo_growth_m),
      loo_bartik_w_log = share_2012_w * log(1 + loo_growth_w),
      
      # Ratio instruments
      loo_bartik = loo_bartik_m / loo_bartik_w,
      loo_bartik_log = loo_bartik_m_log / loo_bartik_w_log
    )
}

df_bartik_loo_01 <- get_bartik_loo(df_shares_2012_01, df_loo_shifts_01, 
                                   "sector_01", "noga_01_description")
df_bartik_loo_ter <- get_bartik_loo(df_shares_2012_ter, df_loo_shifts_ter, 
                                    "sector_tertiary", "tertiary_description")

# Merge LOO and baseline -------------------------------------------------------

df_bartik_joined_01 <- df_bartik_01 %>% 
  left_join(df_bartik_loo_01, 
            by = c("sector_01", "noga_01_description", "region", "share_2012_m",
                   "share_2012_w", "year"))

df_bartik_joined_ter <- df_bartik_ter %>% 
  left_join(df_bartik_loo_ter, 
            by = c("sector_tertiary", "tertiary_description", "region", "share_2012_m",
                   "share_2012_w", "year"))

# Other variables for IV -------------------------------------------------------
# ------------------------------------------------------------------------------

# Get y: relative wages --------------------------------------------------------
get_y <- function(my_sector_level, my_description) {
  df_labels %>% 
    group_by(sex, {{my_sector_level}}, {{my_description}}, region, year) %>%
    summarise(wage = sum(monthlywage),
              hours = sum(hours), .groups = 'drop') %>% 
    pivot_wider(id_cols = c({{my_sector_level}}, {{my_description}}, region, year), 
                names_from = sex, values_from = c(wage, hours),
                values_fill = 0) %>%
    rename(wage_men = 'wage_1',
           wage_women = 'wage_2',
           hours_men = 'hours_1',
           hours_women = 'hours_2') %>%
    mutate(wage_ratio = log(wage_men / wage_women),
           hours_ratio = log(hours_men / hours_women))
}

df_y_01 <- get_y(sector_01, noga_01_description)
df_y_ter <- get_y(sector_tertiary, tertiary_description)

# Get skill levels -------------------------------------------------------------
get_skills <- function(my_sector_level, my_description) {
  df_labels %>% 
    group_by({{my_sector_level}}, {{my_description}}, 
             region, year, sex) %>%
    summarise(total_n = n(), 
              n_skilled = sum(AUSBILD %in% 1:4, na.rm = TRUE),
              frac_skilled = n_skilled / total_n, .groups = 'drop') %>%
    dplyr::select(-total_n, -n_skilled) %>%
    pivot_wider(names_from = sex, values_from = frac_skilled) %>%
    rename(frac_skilled_men = "1",
           frac_skilled_women = "2") %>%
    mutate(frac_skilled_ratio = frac_skilled_men / frac_skilled_women)
}

df_skills_01 <- get_skills(sector_01, noga_01_description)
df_skills_ter <- get_skills(sector_tertiary, tertiary_description)

# Get full data set for IV -----------------------------------------------------
get_iv <- function(my_sector_level_str, my_description_str, 
                   bartik_df, y_df, skills_df) {
  bartik_df %>%
    left_join(y_df, by = c(my_sector_level_str, my_description_str, 
                           "region", "year")) %>%
    left_join(skills_df, by = c(my_sector_level_str, my_description_str, 
                                "region", "year"))
}

df_iv_01 <- get_iv("sector_01", "noga_01_description", 
                   df_bartik_joined_01, df_y_01, df_skills_01)
df_iv_ter <- get_iv("sector_tertiary", "tertiary_description",
                    df_bartik_joined_ter, df_y_ter, df_skills_ter)

# Save data --------------------------------------------------------------------
saveRDS(df_iv_01, file = paste0(wd_confidential, "/Data_for_IV/data_for_iv_by_region.rds"))
saveRDS(df_iv_ter, file = paste0(wd_confidential, "/Data_for_IV/data_for_iv_by_region_tertiary.rds"))
saveRDS(df_labels, file = paste0(wd_confidential, "/Data_for_IV/data_with_sector_labels.rds"))
