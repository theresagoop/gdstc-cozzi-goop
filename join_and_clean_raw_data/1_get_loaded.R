source("C:/Users/TGoop/thesis/gender-directed-change/data/0_setup.R")

# Function to clean ZAS data  ------------------------

clean_zas_data <- function(datf) {
  
  # Remove implausible values for ddeb and dfin
  datf <- subset(datf, ddeb <= 12 | dfin <= 12)
  
  # Add length of reference period
  datf$periods <- datf$dfin - datf$ddeb + 1 # Include first and last month
  
  # Add monthly wages
  datf$monthly_wage <- datf$mrevcot / datf$periods
  
  # Count and remove duplicates and add the joint wages of all employers
  datf <- datf %>% # This takes long...no solution found yet
    group_by(noavs) %>% 
    summarise(n_employers = n(), 
              monthly_wage_all_employers = sum(monthly_wage))
  
  datf[,]
}

# Function to join data frames -----------------------

join_lse_statpop_zas <- function(lse, statpop, zas_clean) {
  
  # Join raw LSE and STATPOP data
  datf_joined <- inner_join(lse, statpop, by=c("AHV_N" = "PSEUDOVN"))
  
  # Add cleaned ZAS data
  datf <- inner_join(datf_joined, zas_clean, by=c("AHV_N" = "noavs"))
  
  datf[,]
}

# Load data -----------------------------------------

# Statpop
statpop20 <- read.csv(paste0(wd_confidential, "/Raw_data/statpop_2020_230554_pseudo.csv"), sep=";")
statpop19 <- read.csv(paste0(wd_confidential, "/Raw_data/statpop_2019_230554_pseudo.csv"), sep=";")
statpop18 <- read.csv(paste0(wd_confidential, "/Raw_data/statpop_2018_230554_pseudo.csv"), sep=";")
statpop17 <- read.csv(paste0(wd_confidential, "/Raw_data/statpop_2017_230554_pseudo.csv"), sep=";")
statpop16 <- read.csv(paste0(wd_confidential, "/Raw_data/statpop_2016_230554_pseudo.csv"), sep=";")
statpop15 <- read.csv(paste0(wd_confidential, "/Raw_data/statpop_2015_230554_pseudo.csv"), sep=";")
statpop14 <- read.csv(paste0(wd_confidential, "/Raw_data/statpop_2014_230554_pseudo.csv"), sep=";")
statpop13 <- read.csv(paste0(wd_confidential, "/Raw_data/statpop_2013_230554_pseudo.csv"), sep=";")
statpop12 <- read.csv(paste0(wd_confidential, "/Raw_data/statpop_2012_230554_pseudo.csv"), sep=";")

# LSE
lse20 <- read.csv(paste0(wd_confidential, "/Raw_data/LSE2020_230554_pseudo.csv"), sep=";")
lse18 <- read.csv(paste0(wd_confidential, "/Raw_data/LSE2018_230554_pseudo.csv"), sep=";")
lse16 <- read.csv(paste0(wd_confidential, "/Raw_data/LSE2016_230554_pseudo.csv"), sep=";")
lse14 <- read.csv(paste0(wd_confidential, "/Raw_data/LSE2014_230554_pseudo.csv"), sep=";")
lse12 <- read.csv(paste0(wd_confidential, "/Raw_data/LSE2012_230554_pseudo.csv"), sep=";")

# SAKE
sake20 <- read.csv(paste0(wd_confidential, "/Raw_data/SAKE2020_pseudo.csv"), sep=";")
sake19 <- read.csv(paste0(wd_confidential, "/Raw_data/SAKE2019_pseudo.csv"), sep=";")
sake18 <- read.csv(paste0(wd_confidential, "/Raw_data/SAKE2018_pseudo.csv"), sep=";")
sake17 <- read.csv(paste0(wd_confidential, "/Raw_data/SAKE2017_pseudo.csv"), sep=";")
sake16 <- read.csv(paste0(wd_confidential, "/Raw_data/SAKE2016_pseudo.csv"), sep=";")
sake15 <- read.csv(paste0(wd_confidential, "/Raw_data/SAKE2015_pseudo.csv"), sep=";")
sake14 <- read.csv(paste0(wd_confidential, "/Raw_data/SAKE2014_pseudo.csv"), sep=";")
sake13 <- read.csv(paste0(wd_confidential, "/Raw_data/SAKE2013_pseudo.csv"), sep=";")
sake12 <- read.csv(paste0(wd_confidential, "/Raw_data/SAKE2012_pseudo.csv"), sep=";")

# ZAS
zas20 <- read.csv(paste0(wd_confidential, "/Raw_data/cibasecot2020_pseudo.csv"), sep=";")
zas19 <- read.csv(paste0(wd_confidential, "/Raw_data/cibasecot2019_pseudo.csv"), sep=";")
zas18 <- read.csv(paste0(wd_confidential, "/Raw_data/cibasecot2018_pseudo.csv"), sep=";")
zas17 <- read.csv(paste0(wd_confidential, "/Raw_data/cibasecot2017_pseudo.csv"), sep=";")
zas16 <- read.csv(paste0(wd_confidential, "/Raw_data/cibasecot2016_pseudo.csv"), sep=";")
zas15 <- read.csv(paste0(wd_confidential, "/Raw_data/cibasecot2015_pseudo.csv"), sep=";")
zas14 <- read.csv(paste0(wd_confidential, "/Raw_data/cibasecot2014_pseudo.csv"), sep=";")
zas13 <- read.csv(paste0(wd_confidential, "/Raw_data/cibasecot2013_pseudo.csv"), sep=";")
zas12 <- read.csv(paste0(wd_confidential, "/Raw_data/cibasecot2012_pseudo.csv"), sep=";")

# Subset data ---------------------------------------

datf_lse20 <- subset(lse20, select=my_cols_lse_20)
datf_lse18 <- subset(lse18, select=my_cols_lse)
datf_lse16 <- subset(lse16, select=my_cols_lse)
datf_lse14 <- subset(lse14, select=my_cols_lse)
datf_lse12 <- subset(lse12, select=my_cols_lse)

# Rename variable in 2020 file such that it corresponds with other years
datf_lse20 <- datf_lse20 %>% rename(NOG_2_08 = NOG_2_08_PUB)

datf_statpop20 <- subset(statpop20, select=my_cols_statpop)
datf_statpop19 <- subset(statpop19, select=my_cols_statpop)
datf_statpop18 <- subset(statpop18, select=my_cols_statpop) 
datf_statpop17 <- subset(statpop17, select=my_cols_statpop)
datf_statpop16 <- subset(statpop16, select=my_cols_statpop)
datf_statpop15 <- subset(statpop15, select=my_cols_statpop)
datf_statpop14 <- subset(statpop14, select=my_cols_statpop)
datf_statpop13 <- subset(statpop13, select=my_cols_statpop)
datf_statpop12 <- subset(statpop12, select=my_cols_statpop) 

datf_sake20 <- subset(sake20, select=my_cols_sake)
datf_sake19 <- subset(sake19, select=my_cols_sake)
datf_sake18 <- subset(sake18, select=my_cols_sake)
datf_sake17 <- subset(sake17, select=my_cols_sake)
datf_sake16 <- subset(sake16, select=my_cols_sake)
datf_sake15 <- subset(sake15, select=my_cols_sake)
datf_sake14 <- subset(sake14, select=my_cols_sake)
datf_sake13 <- subset(sake13, select=my_cols_sake)
datf_sake12 <- subset(sake12, select=my_cols_sake)

datf_zas20 <- subset(zas20, select=my_cols_zas)
datf_zas19 <- subset(zas19, select=my_cols_zas)
datf_zas18 <- subset(zas18, select=my_cols_zas)
datf_zas17 <- subset(zas17, select=my_cols_zas)
datf_zas16 <- subset(zas16, select=my_cols_zas)
datf_zas15 <- subset(zas15, select=my_cols_zas)
datf_zas14 <- subset(zas14, select=my_cols_zas)
datf_zas13 <- subset(zas13, select=my_cols_zas)
datf_zas12 <- subset(zas12, select=my_cols_zas)

# Clean ZAS data -----------------------------------

datf_zas12_clean <- clean_zas_data(datf_zas12)
datf_zas14_clean <- clean_zas_data(datf_zas14)
datf_zas16_clean <- clean_zas_data(datf_zas16)
datf_zas18_clean <- clean_zas_data(datf_zas18)
datf_zas20_clean <- clean_zas_data(datf_zas20)

# Save data ----------------------------------------

# Join data
datf_joined12 <- join_lse_statpop_zas(datf_lse12, datf_statpop12, datf_zas12_clean)
datf_joined14 <- join_lse_statpop_zas(datf_lse14, datf_statpop14, datf_zas14_clean)
datf_joined16 <- join_lse_statpop_zas(datf_lse16, datf_statpop16, datf_zas16_clean)
datf_joined18 <- join_lse_statpop_zas(datf_lse18, datf_statpop18, datf_zas18_clean)
datf_joined20 <- join_lse_statpop_zas(datf_lse20, datf_statpop20, datf_zas20_clean)

# Generate .rds files
saveRDS(datf_joined12,
        file = paste0(wd_confidential, 
                      "/Joined_data/joined_lse_statpop_zas_2012.rds"))
saveRDS(datf_joined14, 
        file = paste0(wd_confidential,
                      "/Joined_data/joined_lse_statpop_zas_2014.rds"))
saveRDS(datf_joined16, 
        file = paste0(wd_confidential,
                      "/Joined_data/joined_lse_statpop_zas_2016.rds"))
saveRDS(datf_joined18, 
        file = paste0(wd_confidential,
                      "/Joined_data/joined_lse_statpop_zas_2018.rds"))
saveRDS(datf_joined20, 
        file = paste0(wd_confidential,
                      "/Joined_data/joined_lse_statpop_zas_2020.rds"))
# ! TO DO ! Clear workspace !!

