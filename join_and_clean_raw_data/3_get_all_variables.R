# Clear environment
rm(list=ls())

source("D:/PhD Docs/thesisgit/gender-directed-change/data/0_setup.R")

# Function to add year ------------------------
get_year <- function(datf, year) {
  datf$year <- year
  
  datf[,]
}

# Function to add regions ---------------------

get_regions <- function(datf) {
  
  # Get vectors with canton - region keys
  v_Genf <- c("VD", "VS", "GE") # Genferseeregion
  v_Mittelland <- c("BE", "FR", "SO", "NE", "JU") # Espace Mittelland
  v_Nordwest <- c("BS", "BL", "AG") # Nordwestschweiz
  v_Zuerich <- c("ZH") # Zürich
  v_Ost <- c("GL", "SH", "AR", "AI", "SG", "GR", "TG") # Ostschweiz
  v_Zentral <- c("LU", "UR", "SZ", "OW", "NW", "ZG") # Zentralschweiz
  v_Tessin <- c("TI") # Tessin
  
  # Get list of all regions from canton - region key vectors
  list_all_regions <- list(v_Genf, v_Mittelland, v_Nordwest, 
                           v_Ost, v_Tessin, v_Zentral, v_Zuerich)
  # Add empty column
  datf$region <- "" 
  
  # Map canton to region
  datf <- datf %>% mutate(region = case_when(
    ARBKTO %in% list_all_regions[[1]] ~ my_region[1],
    ARBKTO %in% list_all_regions[[2]] ~ my_region[2],
    ARBKTO %in% list_all_regions[[3]] ~ my_region[3],
    ARBKTO %in% list_all_regions[[4]] ~ my_region[4],
    ARBKTO %in% list_all_regions[[5]] ~ my_region[5],
    ARBKTO %in% list_all_regions[[6]] ~ my_region[6],
    ARBKTO %in% list_all_regions[[7]] ~ my_region[7],
    TRUE ~ "this did not work"
  ))
  
  datf[,]
}

# Function to exclude obs with missing ISCO information
get_rid_of_missing_iscos <- function(datf) {
  datf <- subset(datf, occupation != -9)
}


# Load data --------------------------------------------------------------------
datf_cleaned12 <- readRDS(file = paste0(wd_confidential,
                                "/Joined_and_cleaned_raw_data/cleaned_lse_statpop_zas_2012.rds")) 
datf_cleaned14 <- readRDS(file = paste0(wd_confidential,
                                "/Joined_and_cleaned_raw_data/cleaned_lse_statpop_zas_2014.rds"))
datf_cleaned16 <- readRDS(file = paste0(wd_confidential,
                                "/Joined_and_cleaned_raw_data/cleaned_lse_statpop_zas_2016.rds"))
datf_cleaned18 <- readRDS(file = paste0(wd_confidential,
                                "/Joined_and_cleaned_raw_data/cleaned_lse_statpop_zas_2018.rds"))
datf_cleaned20 <- readRDS(file = paste0(wd_confidential,
                                "/Joined_and_cleaned_raw_data/cleaned_lse_statpop_zas_2020.rds"))

# Save data with year and regions ----------------------------------------------
# Add year
datf_year12 <- get_year(datf_cleaned12, 2012)
datf_year14 <- get_year(datf_cleaned14, 2014)
datf_year16 <- get_year(datf_cleaned16, 2016)
datf_year18 <- get_year(datf_cleaned18, 2018)
datf_year20 <- get_year(datf_cleaned20, 2020)

# Check percentage of obs with missing ISCO information
nrow(datf_year12[datf_year12$occupation == -9,])/nrow(datf_year12)
nrow(datf_year14[datf_year14$occupation == -9,])/nrow(datf_year14)
nrow(datf_year16[datf_year16$occupation == -9,])/nrow(datf_year16)
nrow(datf_year18[datf_year18$occupation == -9,])/nrow(datf_year18)
nrow(datf_year20[datf_year20$occupation == -9,])/nrow(datf_year20)

# Remove obs with missing ISCO information
datf_isco_year12 <- get_rid_of_missing_iscos(datf_year12)
datf_isco_year14 <- get_rid_of_missing_iscos(datf_year14)
datf_isco_year16 <- get_rid_of_missing_iscos(datf_year16)
datf_isco_year18 <- get_rid_of_missing_iscos(datf_year18)
datf_isco_year20 <- get_rid_of_missing_iscos(datf_year20)

# Add regions
datf_final12 <- get_regions(datf_isco_year12)
datf_final14 <- get_regions(datf_isco_year14)
datf_final16 <- get_regions(datf_isco_year16)
datf_final18 <- get_regions(datf_isco_year18)
datf_final20 <- get_regions(datf_isco_year20)

# Generate .rds files ----------------------------------------------------------
saveRDS(datf_final12,
        file = paste0(wd_confidential, 
                      "/Joined_and_cleaned_raw_data/final_lse_statpop_zas_2012.rds"))
saveRDS(datf_final14, 
        file = paste0(wd_confidential,
                      "/Joined_and_cleaned_raw_data/final_lse_statpop_zas_2014.rds"))
saveRDS(datf_final16, 
        file = paste0(wd_confidential,
                      "/Joined_and_cleaned_raw_data/final_lse_statpop_zas_2016.rds"))
saveRDS(datf_final18, 
        file = paste0(wd_confidential,
                      "/Joined_and_cleaned_raw_data/final_lse_statpop_zas_2018.rds"))
saveRDS(datf_final20, 
        file = paste0(wd_confidential,
                      "/Joined_and_cleaned_raw_data/final_lse_statpop_zas_2020.rds"))

# Get joined data set ----------------------------------------------------------
# Join ------------------------------------------
datf_final_all <- rbind(datf_final12, datf_final14, datf_final16, datf_final18,
                        datf_final20)

# Add NOGA 01 codes -----------------------------
noga_mapping <- read_excel(paste0(wd,"/isco_nace_noga.xlsx"), sheet = "NOGA")
noga_mapping <- noga_mapping[1:4]
noga_mapping <- noga_mapping %>% mutate(across(1:2, as.factor))

datf_final_all <- datf_final_all %>%
  left_join(noga_mapping %>% dplyr::select(noga_02, noga_01, noga_01_description), 
            by = c("sector" = "noga_02")) %>%
  rename(sector_01 = noga_01)

# Remove unused levels ---------------------------
datf_final_all$sector_01 <- droplevels(datf_final_all$sector_01)
datf_final_all$occupation <- droplevels(datf_final_all$occupation)

# Group NOGA 01 codes ----------------------------
datf_final_all <- datf_final_all %>%
  # Rename sectors
  mutate(sector_01 = if_else(sector_01 %in% c("B", "C", "D", "E"), 
                             "B-E", sector_01)) %>%
  mutate(sector_01 = if_else(sector_01 %in% c("L", "N"),
                             "L/N", sector_01)) %>%
  mutate(sector_01 = if_else(sector_01 %in% c("R", "S"),
                             "R/S", sector_01)) %>%
  # Update descriptions
  mutate(noga_01_description = ifelse(sector_01 == "B-E", 
                                      "Processing/energy supply",
                                      ifelse(sector_01 == "L/N", 
                                             "Real estate, other economic services",
                                             ifelse(sector_01 == "R/S", 
                                                    "Arts, entertainment, other services", 
                                                    noga_01_description)))) %>%
  # Remove sectors A and P
  # Why? Too few obs in A (n=786) and 
  # no comparable national data on worked hours for P (teachers)
  filter(!sector_01 %in% c("A", "P"))

# Add "0" to one-digit occupations --------------------
levels(datf_final_all$occupation) <- ifelse(nchar(levels(datf_final_all$occupation)) == 1,
                                        paste0("0", levels(datf_final_all$occupation)),
                                        levels(datf_final_all$occupation))

# Add occupation major group
# ???? check from allocation paper code

# Add potential experience -----------------------------------------------------
# Remove observations with missing education 
datf <- datf_final_all %>% filter(!AUSBILD %in% c("-9", NA))

# Transform training category to training years and create years of earnings
tr_yr <- c(17, 15, 14, 15, 13, 12, 11, 7)
datf$training_years <- tr_yr[datf$AUSBILD]
datf$experience <- sapply(datf$age - datf$training_years - 6,
                                 function(x) { max(x, 0) })
datf$AUSBILD <- factor(datf$AUSBILD)

# Save .rds files --------------------------------------------------------------
saveRDS(datf_final_all,
        file = paste0(wd_confidential, 
                      "/Joined_and_cleaned_raw_data/final_lse_statpop_zas_allyears.rds"))
saveRDS(datf,
        file = paste0(wd_confidential, 
                      "/Joined_and_cleaned_raw_data/final_lse_statpop_zas_allyears_educationiscomplete.rds"))
# ! TO DO ! Clear workspace !
