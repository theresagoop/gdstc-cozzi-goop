# Estimating equation (8) ######################################################

# Clear environment
rm(list=ls())

source("D:/PhD Docs/thesisgit/gender-directed-change/data/0_setup.R")

# Prepare data #################################################################
# Load LSE data ----------------------------------------------------------------
df_raw <- readRDS(file = paste0(wd_confidential,
                                "/Joined_and_cleaned_raw_data/final_lse_statpop_zas_allyears.rds"))

# Replicate productivity data set structure ------------------------------------
df_selected <- df_raw %>%
  # Delete sectors for which we do not have productivity data
  filter(sector_01 != "O") %>%
  # Group according to productivity data groups
  mutate(sector_01 = if_else(sector_01 %in% c("H", "J"), 
                             "H/J", sector_01)) %>%
  mutate(sector_01 = if_else(sector_01 %in% c("L/N", "M"),
                             "L/M/N", sector_01)) %>%
  # Update descriptions
  mutate(noga_01_description = ifelse(sector_01 == "H/J", 
                                      "Transportation/storage, information/communication",
                                      ifelse(sector_01 == "L/M/N", 
                                             "Real estate, other economic services and professional, scientific and technical activities",
                                             noga_01_description))) 

# Get ratios -------------------------------------------------------------------
df_grouped <- df_selected %>% 
    group_by(sex, sector_01, noga_01_description, year) %>%
    summarise(wage = sum(monthlywage),
              hours = sum(hours)) %>% 
    pivot_wider(id_cols = c(sector_01, noga_01_description, year), 
                names_from = sex, values_from = c(wage, hours),
                values_fill = 0) %>%
    rename(wage_men = 'wage_1',
           wage_women = 'wage_2',
           hours_men = 'hours_1',
           hours_women = 'hours_2') %>%
    mutate(wage_ratio = log(wage_men/wage_women),
           hours_ratio = log(hours_men/hours_women)) 

# Add productivity -------------------------------------------------------------
# Load productivity data
df_productivity <- read_excel(paste0(wd,"/productivity.xlsx"), sheet = "Daten")

# Format data
df_productivity_grouped <- df_productivity %>% 
  # Longer format
  pivot_longer(cols = c(`2012.1`, `2014.1`, `2016.1`, `2018.1`, `2020.1`,
                        `2012.2`, `2014.2`, `2016.2`, `2018.2`, `2020.2`,
                        `2012.3`, `2014.3`, `2016.3`, `2018.3`, `2020.3`),
               names_to = "year_spec",
               values_to = "value") %>%
  separate(year_spec, into = c("year", "spec"), sep = "\\.") %>%
  mutate(spec = dplyr::recode(spec, 
                              "1" = "value_added",
                              "2" = "weight",
                              "3" = "productivity")) %>%
  # Delete sectors with too few observations in LSE data
  filter(!sector_01 %in% c("A", "P")) %>%
  # Group by sector_01
  group_by(sector_01, year, spec) %>% summarise(value = sum(value)) %>%
  # Wider format
  ungroup() %>%
  pivot_wider(values_from = "value", names_from = "spec") %>%
  mutate(productivity = log(value_added / weight  * 100)) %>%
  mutate(year = as.numeric(year))

df_joined <- left_join(df_grouped, df_productivity_grouped, by=c("year", "sector_01"))


# OLS --------------------------------------------------------------------------
# Labor supply and wage --------------
mod <- lm(wage_ratio ~ hours_ratio + productivity, data = df_joined)
summary(mod)

-1/mod$coefficients[2]


# Productivity and labor supply -----
mod2 <- lm(hours_ratio ~ productivity, data = df_joined)
summary(mod2)


