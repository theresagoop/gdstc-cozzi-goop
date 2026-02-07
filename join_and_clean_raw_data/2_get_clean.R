source("C:/Users/TGoop/thesis/gender-directed-change/data/0_setup.R")

# Function to clean joined data --------------------

clean_joined_data <- function(datf){
  # LSE data filters are based on common practice, see 
  # https://www.buerobass.ch/fileadmin/Files/2017/BFS_2017_LohnanalysenLSE2014.pdf
  
  # Exclude obs with missing FTE ('Filter A')
  datf <- subset(datf, !is.na(IBGR))
  
  # Exclude obs with missing ZAS data (ZAS being used for plausibility checks)
  datf <- subset(datf, monthly_wage_all_employers > 0) 
  
  # Exclude obs with implausible FTE <20% or > 150% ('Filter B')
  # Monthly earners
  datf <- subset(datf, is.na(FS03) | FS03 %in% c(3,5) |
                   (FS03 %in% c(1,2,4) & IBGR >= .1 & IBGR <= 1.5)) 
  # Hourly earners w/missing BEZSTD info
  datf <- subset(datf, is.na(FS03) | FS03 %in% c(1,2,4) |
                   (FS03 %in% c(3,5) & BEZSTD != 0) |
                   (FS03 %in% c(3,5) & BEZSTD == 0 &
                      (IBGR >= .1 & IBGR <= 1.5))) 
  # FS03 == NA earners
  datf <- subset(datf, FS03 %in% c(3,5) | FS03 %in% c(1,2,4) |
                   (is.na(FS03) & IBGR >= .1 & IBGR <= 1.5)) 
  
  # Add wage differences LSE - ZAS
  datf$wage_diff <- (datf$MBLS - datf$monthly_wage_all_employers) / 
    datf$monthly_wage_all_employers
  
  # Exclude obs with more than one employer where LSE wage is more than double the ZAS wage
  datf <- subset(datf, !(n_employers > 1 & wage_diff > 1))
  
  # Interpretation from ChatGPT:
  # Therefore, the remaining rows can have any of the following scenarios:
  #MBLS < monthly_wage_all_employers (when wage_diff < 0).
  #MBLS = monthly_wage_all_employers (when wage_diff = 0).
  #MBLS > monthly_wage_all_employers, but not more than double (when 0 < wage_diff <= 1).
  
  # Exclude obs with standardized gross wage < median wage ('Filter C')
  datf <- subset(datf, MBLS >= lower)
  datf <- subset(datf, !(n_employers == 1 & monthly_wage_all_employers < lower))
  
  # Exclude obs with wages > 15 times median wage ('Filter D')
  datf <- subset(datf, MBLS <= upper)
  datf <- subset(datf, !(n_employers == 1 & monthly_wage_all_employers > upper))
  
  # Add standardized weekly hours
  
  # FS03 == NA
  datf$hours_std[is.na(datf$FS03) & datf$BEZSTD == 0] <- datf$IWAZ[is.na(datf$FS03) & datf$BEZSTD == 0] * 4 / datf$IBGR[is.na(datf$FS03) & datf$BEZSTD == 0]
  datf$hours_std[is.na(datf$FS03) & datf$IWAZ == 0] <- datf$BEZSTD[is.na(datf$FS03) & datf$IWAZ == 0] / datf$IBGR[is.na(datf$FS03) & datf$IWAZ == 0]
  # Monthly earners
  datf$hours_std[datf$FS03 %in% c(1,2,4)] <- datf$IWAZ[datf$FS03 %in% c(1,2,4)]*4 / 
    datf$IBGR[datf$FS03 %in% c(1,2,4)]
  # Hourly earners
  datf$hours_std[datf$FS03 %in% c(3,5)] <- datf$BEZSTD[datf$FS03 %in% c(3,5)] / 
    datf$IBGR[datf$FS03 %in% c(3,5)]
  
  # Exclude obs with missing standardized hours
  datf <- subset(datf, !(hours_std == "Inf" | hours_std == "NaN"))
  
  # Exclude implausible weekly hours (Part 1 'Filter E')
  datf <- subset(datf, hours_std >= 36*4 & hours_std <= 80*4)

  # Add hours worked
  # Monthly earners
  datf$hours[datf$FS03 %in% c(1,2,4)] <- datf$IWAZ[datf$FS03 %in% c(1,2,4)]*4
  # Hourly earners
  datf$hours[datf$FS03 %in% c(3,5)] <- datf$BEZSTD[datf$FS03 %in% c(3,5)]
  # FS03 == NA
  datf$hours[is.na(datf$FS03) & datf$BEZSTD == 0] <- datf$IWAZ[is.na(datf$FS03) & datf$BEZSTD == 0]*4
  datf$hours[is.na(datf$FS03) & datf$IWAZ == 0] <- datf$BEZSTD[is.na(datf$FS03) & datf$IWAZ == 0]

  # Exclude implausible combinations of FTE and hours worked (Part 2 'Filter E')
  datf <- subset(datf, hours <= 80*4)
  
  # Rename columns
  datf <- datf %>% rename(age = AGE,
                          sex = SEX,
                          monthlywage = MBLS,
                          profposition = BERUFST,
                          skillevel = VA_PS07_19,
                          occupation = ISCO19_2,
                          sector = NOG_2_08)
  
  # Convert sex and occupation to factors
  datf$sex <- as.factor(datf$sex)
  datf$occupation <- as.factor(datf$occupation)
  datf$sector <- as.factor(datf$sector)
  
  datf[,]
}

# Load data ---------------------------------------
datf12 <- readRDS(file = paste0(wd_confidential,
                                "/Joined_and_cleaned_raw_data/joined_lse_statpop_zas_2012.rds")) 
datf14 <- readRDS(file = paste0(wd_confidential,
                                "/Joined_and_cleaned_raw_data/joined_lse_statpop_zas_2014.rds"))
datf16 <- readRDS(file = paste0(wd_confidential,
                                "/Joined_and_cleaned_raw_data/joined_lse_statpop_zas_2016.rds"))
datf18 <- readRDS(file = paste0(wd_confidential,
                                "/Joined_and_cleaned_raw_data/joined_lse_statpop_zas_2018.rds"))
datf20 <- readRDS(file = paste0(wd_confidential,
                                "/Joined_and_cleaned_raw_data/joined_lse_statpop_zas_2020.rds"))

# Save cleaned data -------------------------------

# Clean data
datf_cleaned12 <- clean_joined_data(datf12)
datf_cleaned14 <- clean_joined_data(datf14)
datf_cleaned16 <- clean_joined_data(datf16)
datf_cleaned18 <- clean_joined_data(datf18)
datf_cleaned20 <- clean_joined_data(datf20)

# Generate .rds files
saveRDS(datf_cleaned12,
        file = paste0(wd_confidential, 
                      "/Joined_data/cleaned_lse_statpop_zas_2012.rds"))
saveRDS(datf_cleaned14, 
        file = paste0(wd_confidential,
                      "/Joined_data/cleaned_lse_statpop_zas_2014.rds"))
saveRDS(datf_cleaned16, 
        file = paste0(wd_confidential,
                      "/Joined_data/cleaned_lse_statpop_zas_2016.rds"))
saveRDS(datf_cleaned18, 
        file = paste0(wd_confidential,
                      "/Joined_data/cleaned_lse_statpop_zas_2018.rds"))
saveRDS(datf_cleaned20, 
        file = paste0(wd_confidential,
                      "/Joined_data/cleaned_lse_statpop_zas_2020.rds"))
# ! TO DO ! Clear workspace !
