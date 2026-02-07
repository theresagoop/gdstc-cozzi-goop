# Clear environment
rm(list=ls())

source("D:/PhD Docs/thesisgit/gender-directed-change/data/0_setup.R")

# Load data --------------------------------------------------------------------
datf <- readRDS(file = paste0(wd_confidential, "/Data_for_IV/data_for_iv_by_region.rds"))

# Classify region as factor
datf$region <- as.factor(datf$region)

# Estimation aggregate #########################################################

# OLS ------------------------------------------------------------------------
mod_ols <- lm(wage_ratio ~ hours_ratio, data = datf)

# Basic shift-share IV -------------------------------------------------------
# See https://github.com/kylebutts/ssaggregate
mod_fe <- fixest::feols(wage_ratio ~ year:sector_01 + frac_skilled_ratio | 0 | hours_ratio ~ bartik,
                        data=datf, vcov = "hc1")

# Leave-one-out shift-share IV -----------------------------------------------
mod_fe_loo <- fixest::feols(wage_ratio ~ year:sector_01 + frac_skilled_ratio | 0 | hours_ratio ~ loo_bartik,
                            data=datf, vcov = "hc1")

# National aggregated shifts shift-share IV ----------------------------------
mod_fe_agg <- fixest::feols(wage_ratio ~ year:sector_01 + frac_skilled_ratio | 0 | hours_ratio ~ agg_bartik,
                            data=datf, vcov = "hc1")

# Get results table with all model results -----------------------------------
# Extract first-stage coefficients
beta_fs <- format(round(summary(mod_fe, stage=1)$coefficient[2], 4), scientific = FALSE)
beta_fs_loo <- format(round(summary(mod_fe_loo, stage=1)$coefficient[2], 4), scientific = FALSE)
beta_fs_agg <- format(round(summary(mod_fe_agg, stage=1)$coefficient[2], 4), scientific = FALSE)

# Extract second-stage coefficients
beta_ols <- mod_ols$coefficients[2]
beta <- mod_fe$coefficients[2]
beta_loo <- mod_fe_loo$coefficients[2]
beta_agg <- mod_fe_agg$coefficients[2]

# Compute sigmas -------------------------------------------------------------
sigma_ols_0.1 <- round((beta_ols + 2 + 0.1) / (1 - (beta_ols* 0.1)), 2)
sigma_0.1 <- round((beta + 2 + 0.1) / (1 - (beta * 0.1)), 2)
sigma_loo_0.1 <- round((beta_loo + 2 + 0.1) / (1 - (beta_loo * 0.1)),2)
sigma_agg_0.1 <- round((beta_agg + 2 + 0.1) / (1 - (beta_agg * 0.1)),2)


# Prepare table ----------------------------------------------------------------
# Prepare manually added rows
header <- c(" " = 1, "Dependent Variable: Log Male/Female Wage Ratio" = 3)

# Create additional rows
row_sigma <- data.frame(
  term = "Sigma ($\\varepsilon = 0.1$)",
  OLS = sigma_ols_0.1,
  `Bartik IV` = sigma_0.1,
  `Bartik IV LOO` = sigma_loo_0.1,
  `Bartik IV Agg` = sigma_agg_0.1  
)

row_first <- data.frame(
  term = "1st Stage coefficient", 
  OLS = "",
  `Bartik IV` = beta_fs,
  `Bartik IV LOO` = beta_fs_loo,
  `Bartik IV Agg` = beta_fs_agg  
)

row_fe <- data.frame(
  term = "Year $\\times$ Sector Fixed Effects",
  OLS = "No",
  `Bartik IV` = "Yes",
  `Bartik IV LOO` = "Yes",
  `Bartik IV Agg` = "Yes"
)

extra_rows <- rbind(row_sigma, row_first, row_fe)

# Get table --------------------------------------------------------------------
tab <- modelsummary(
  list(
    "OLS" = mod_ols, 
    "Bartik IV" = mod_fe, 
    "Bartik IV LOO" = mod_fe_loo,
    "Bartik IV Agg" = mod_fe_agg
  ),
  output = "latex",
  title = "Regression Results (Aggregated)",
  coef_map = c("hours_ratio" = "Log m/f Labor Supply Ratio",
               "fit_hours_ratio" = "Log m/f Labor Supply Ratio",
               "frac_skilled_ratio" = "Fraction of Skilled Workers m/f",
               "(Intercept)" = "Intercept"),
  stars = TRUE,
  escape = FALSE,
  add_rows = extra_rows # Add signifiance level (stars) of 1st stage coefficient manually
)

tab

# Sigma robustness test ########################################################
# Calculate sigma for each epsilon (main model LOO) --------------------------------
epsilon_range <- seq(0.001, 0.9999, length.out = 1000)
sigma <- (beta_loo + 2 + epsilon_range) / (1 - (beta_loo * epsilon_range))

df <- data.frame(epsilon = epsilon_range, sigma = sigma) %>%
  mutate(gdtc_cutoff = 2 + epsilon_range)

# Plot sigma as a function of epsilon ------------------------------------------
epsilon_sigma <- df %>% ggplot(aes(x=epsilon_range)) + geom_line(aes(y=sigma)) +
  geom_line(aes(y=gdtc_cutoff), color=hsgcoral, linetype="dashed") +
  xlab(expression(epsilon)) + ylab(expression(sigma)) +
  scale_y_continuous(breaks = c(5, 25, 50)) +
  scale_x_continuous(breaks = c(0,0.5,1)) +
  theme_minimal()

# Save plot --------------------------------------------------------------------
epsilon_sigma
ggsave(filename = paste0(wd, "/gdtc/plots/epsilon_sigma.png"),
       width = 5, height = 1.5, dpi = 300)

# Rest not used in paper currently #############################################

# To be discussed with Guido ###################################################
# Gamma-------------------------------------------------------------------------
beta_loo <- mod_fe_loo$coefficients[2]
sigma_loo_0.1 <- (beta_loo + 2 + 0.1) / (1 - (beta_loo * 0.1))
epsilon <- 0.1

gammas <- datf %>% 
  group_by(sector_01, noga_01_description, year) %>%
  summarise(wage_men = sum(wage_men), wage_women = sum(wage_women),
            hours_men = sum(hours_men), hours_women = sum(hours_women)) %>% 
  mutate(wage_ratio = log(wage_men/wage_women),
         hours_ratio = log(hours_men/hours_women),
         female_share = hours_women/(hours_men + hours_women)) %>%
  dplyr::select("sector_01", "noga_01_description", "year", "wage_ratio",
                "hours_ratio", "female_share") %>%
  mutate(my_x = (wage_ratio - 
                   (sigma_loo_0.1-2-epsilon)/(epsilon*sigma_loo_0.1+1)*hours_ratio)*
                      (epsilon*sigma_loo_0.1+1)/(sigma_loo_0.1*(epsilon+1))) %>%
  mutate(gamma = exp(my_x)/(1+exp(my_x)))

gammas %>%
  dplyr::select("sector_01", "noga_01_description", "year", "female_share", "gamma") %>%
  print(n=48)

# Try-outs
sigma <- 3.370
df_joined %>% 
  dplyr::select("sector_01", "noga_01_description", "year", "wage_ratio",
                "hours_ratio", "productivity") %>%
  mutate(my_x = wage_ratio + 1/sigma * hours_ratio - (sigma-1)/sigma * productivity) %>%
  mutate(gamma = exp(my_x)/(1+exp(my_x))) %>% print(n=100)


# Extract Wu-Hausman test results ----------------------------------------------
# NOT SURE I AM INTERPRETING THIS CORRECTLY ####################################
summary_text_fe <- capture.output(summary(mod_fe))[15]
p_value_fe <- as.numeric(sub(".*p =\\s*([0-9\\.]+)\\s*,.*", "\\1", summary_text_fe))
wu_hausman_passed <- ifelse(p_value_fe >= .1, "$H_0$ rejected", "Passed")

summary_text_fe_loo <- capture.output(summary(mod_fe_loo))[15]
p_value_fe_loo <- as.numeric(sub(".*p =\\s*([0-9\\.]+)\\s*,.*", "\\1", summary_text_fe_loo))
wu_hausman_passed_loo <- ifelse(p_value_fe_loo >= .1, "Not passed", "Passed")
################################################################################


# Rest only used if different data is used #####################################
# Function to get LaTeX table with all results ---------------------------------
get_latex_table <- function(var_wage, var_hours, my_title_addition) {
  # Prepare covariates in data ----------------------------
  datf <- datf %>% mutate(var_wage = {{ var_wage }}, var_hours = {{ var_hours }})
  
  # OLS ---------------------------------------------------
  mod_ols <- lm(var_wage ~ var_hours, data = datf)
  
  # Basic shift-share IV ----------------------------------
  # See https://github.com/kylebutts/ssaggregate
  mod_fe <- fixest::feols(var_wage ~ year | 0 | var_hours ~ bartik,
                          data=datf, vcov = "hc1")
  
  mod_fe_loo <- fixest::feols(var_wage ~ year | 0 | var_hours ~ loo_bartik,
                              data=datf, vcov = "hc1")
  
  
  # Get results table with all model results --------------
  # Compute sigmas
  beta_ols <- mod_ols$coefficients[2]
  sigma_ols_0.1 <- (beta_ols + 2 + 0.1) / (1 - (beta_ols* 0.1))
  
  beta <- mod_fe$coefficients[2]
  sigma_0.1 <- (beta + 2 + 0.1) / (1 - (beta * 0.1))
  
  beta_loo <- mod_fe_loo$coefficients[2]
  sigma_loo_0.1 <- (beta_loo + 2 + 0.1) / (1 - (beta_loo * 0.1))
  
  # Prepare manually added rows
  header <- c(" " = 1, "Dependent Variable: Log Male/Female Wage Ratio" = 3)
  
  # Create the sigma row at the bottom
  extra_row <- data.frame(
    term = "Sigma ($\\varepsilon = 0.1$)",  # LaTeX formatting for epsilon
    OLS = sigma_ols_0.1,
    `Bartik IV` = sigma_0.1,
    `Bartik IV (Leave-one-out)` = sigma_loo_0.1
  )
  
  # Get table --------------------------------------------
  tab <- modelsummary(
    list(
      "OLS" = mod_ols, 
      "Bartik IV" = mod_fe, 
      "\\SetCell{c=1}{} {Bartik IV} \\\\ &&& (Leave-one-out)" = mod_fe_loo
    ),
    output = "latex",
    title = paste0("Regression Results ", my_title_addition, 
                   "\\label{tab:reg_results_", gsub(" ", "", my_title_addition), "}"),
    coef_map = c("var_hours" = "Log m/f Labor Supply Ratio",
                 "fit_var_hours" = "Log m/f Labor Supply Ratio",
                 "year" = "Year Trend",
                 "(Intercept)" = "Intercept"),
    stars = TRUE,
    escape = FALSE,  # Allows LaTeX formatting
    add_header_above = header,  
    add_rows = extra_row
  )
  
  tab
}

#get_latex_table(wage_ratio_adj, hours_ratio_adj, "complete educ composition-adj")
get_latex_table(wage_ratio, hours_ratio, "standard model")


