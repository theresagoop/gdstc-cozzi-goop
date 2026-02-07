# Clear environment
rm(list=ls())

source("D:/PhD Docs/thesisgit/gender-directed-change/data/0_setup.R")

# Load data --------------------------------------------------------------------
datf_01 <- readRDS(file = paste0(wd_confidential, "/Data_for_IV/data_for_iv_by_region.rds"))
datf_ter <- readRDS(file = paste0(wd_confidential, "/Data_for_IV/data_for_iv_by_region_tertiary.rds"))

# Clean data
# Adjust sector descriptions to include line breaks (after three words)
datf_iv_01 <- datf_01 %>% 
  mutate(noga_01_description = str_replace_all(noga_01_description, 
                                               "((?:\\S+\\s+){3})", "\\1\n"))
datf_iv_ter <- datf_ter

# Bartik IV estimation by sector ###############################################
# Define epsilon ---------------------------------------------------------------
epsilon <- 0.1

# Define sectors ---------------------------------------------------------------
sectors_01 <- unique(datf_iv_01$noga_01_description)
sectors_ter <- unique(datf_iv_ter$tertiary_description) 

# Get Bartik IV regression results by sector -----------------------------------
# Function
get_sector_results <- function(df, my_sectors, my_description) {
  # Initialize list of sector results
  sector_results <- list()
  
  # Get unique sectors
  sectors <- my_sectors

  # Loop over sectors
  for (s in sectors) {
    # Filter data for one sector
    sector_data <- df %>% filter({{my_description}} == s)
    
    # Run regression
    iv_model <- fixest::feols(wage_ratio ~ year + frac_skilled_ratio | 0 | hours_ratio ~ bartik, 
                      data = sector_data, vcov = "hc1")

    beta <- iv_model$coefficients[2]
    
    # Calculate sigma
    sigma <- (beta + 2 + epsilon) / (1 - (beta * epsilon))
    
    # Save results
    sector_results[[s]] <- list(
      regression_summary = summary(iv_model),
      beta = beta,
      sigma = sigma
    )
  }
  sector_results
}

# Get results
sector_results_01 <- get_sector_results(datf_iv_01, sectors_01, noga_01_description)
sector_results_ter <- get_sector_results(datf_iv_ter, sectors_ter, tertiary_description)

# Prepare results data frame ---------------------------------------------------
get_results_df <- function(my_sector_results) {
  # Store results in data frame
  results_df <- data.frame(
    sector = names(my_sector_results),
    # Second stage results
    sigma = sapply(my_sector_results, function(x) x$sigma),
    beta = sapply(my_sector_results, function(x) x$beta),
    se = sapply(my_sector_results, function(x) x$regression_summary$se[2]),
    sig = sapply(my_sector_results, function(x) x$regression_summary$coeftable[2,4]),
    # First stage results
    first_coef = sapply(my_sector_results, function(x) x$regression_summary$iv_first_stage$hours_ratio$coeftable[2,1]),
    first_se = sapply(my_sector_results, function(x) x$regression_summary$iv_first_stage$hours_ratio$coeftable[2,2]),
    first_sig = sapply(my_sector_results, function(x) x$regression_summary$iv_first_stage$hours_ratio$coeftable[2,4])) %>%
    mutate(sig_star = 
             ifelse(sig > .1, "   ", 
                    ifelse(sig > .05, "*  ",
                           ifelse(sig > .01, "** ", "***"))),
           first_sig_star = 
             ifelse(first_sig > .1, " ", 
                    ifelse(first_sig > .05, "*  ",
                           ifelse(first_sig > .01, "** ", "***")))) %>%
    mutate(sigma = paste0(round(sigma,3)),
           first_stage = paste0(round(first_coef,3), first_sig_star),
           second_stage = paste0(round(beta,3), sig_star))
  
  rownames(results_df) <- NULL
  
  results_df
}

# Get results data frame
results_df_01 <- get_results_df(sector_results_01)
results_df_ter <- get_results_df(sector_results_ter)

# Results table for manufacturing and services ---------------------------------
# Tibble
results_df_extended <- results_df_ter %>%
  arrange((sector)) %>%
  dplyr::select(sector, sigma, first_stage, first_se, second_stage, se) %>%
  mutate(sector = gsub("\n", "\\\\\\\\ ", sector)) %>%
  # Create a row for SE directly beneath each sector
  rowwise() %>%
  do(bind_rows(
    tibble(sector = .$sector, 
           sigma = .$sigma,
           first_stage = .$first_stage, 
           second_stage = .$second_stage),
    tibble(sector = .$sector, 
           sigma = "", 
           first_stage = paste0("(", round(.$first_se, 3), ")"),
           second_stage = paste0("(", round(.$se, 3), ")"))
  )) %>%
  ungroup()

# Latex format
results_df_extended %>%
  kbl(format = "latex", booktabs = TRUE,
      col.names = c("Sector", "$\\sigma$", "1st Stage", "2nd Stage"),
      align = c("l", "c", "l", "l"),
      caption = "Summary Bartik IV regression (Manufacturing and Services) \\label{tab:reg_results_ter}",
      escape = FALSE) %>%
  kable_styling(latex_options = "hold_position") %>%
  column_spec(1, width = "5cm", latex_valign = "m") %>%
  collapse_rows(columns = 1, valign = "middle", latex_hline = "none")

# Results table for individual sectors -----------------------------------------
# Tibble
results_df_extended_01 <- results_df_01 %>%
  mutate(sector = str_replace_all(sector, "\n", " ")) %>%
  arrange((sector)) %>%
  # Create a row for SE directly beneath each sector
  rowwise() %>%
  do(bind_rows(
    tibble(sector = .$sector, 
           sigma = .$sigma,
           first_stage = .$first_stage, 
           second_stage = .$second_stage),
    tibble(sector = .$sector, 
           sigma = "", 
           first_stage = paste0("(", round(.$first_se, 3), ")"),
           second_stage = paste0("(", round(.$se, 3), ")"))
  )) %>%
  ungroup()

# Latex format
results_df_extended_01 %>%
  kbl(format = "latex", booktabs = TRUE,
      col.names = c("Sector", "$\\sigma$", "1st Stage", "2nd Stage"),
      align = c("l", "c", "l", "l"),
      caption = "Summary Bartik IV regression (Individual sectors) \\label{tab:reg_results_01}",
      escape = FALSE) %>%
  kable_styling(latex_options = "hold_position") %>%
  column_spec(1, width = "8cm", latex_valign = "m") %>%
  collapse_rows(columns = 1, valign = "middle", latex_hline = "none")

# Visualize results ------------------------------------------------------------
# Function to get plot
get_results_plot <- function(my_df, my_sector_results) {
  my_df$beta <- as.numeric(as.character(my_df$beta))
  my_df$sigma <- as.numeric(as.character(my_df$sigma))
  
  my_df$sector <- factor(my_df$sector, levels = rev(sort(unique(my_df$sector))))
  
  # Get plot
  ggplot(my_df, aes(y = sector)) +
    geom_point(aes(x = beta, color = "Beta"), size = 2) + 
    geom_errorbar(aes(xmin = beta - se, xmax = beta + se), 
                  width = 0.2, color = "black") + 
    geom_point(aes(x = sigma, color = "Sigma"), size = 3) + 
    # Add vertical lines
    geom_vline(xintercept = 2+epsilon, linetype = "dashed", color = hsgcoral) +
    geom_vline(xintercept = 0, linetype = "solid", color = "grey80", linewidth = 0.6) +
    # Customize legend and labels
    scale_color_manual(name = "", 
                       values = c("Beta" = hsggreyblue2, "Sigma" = hsgcoral),
                       labels = c(expression(beta), expression(sigma))) +
    scale_x_continuous(breaks = seq(floor(min(c(my_df$beta - my_df$se, my_df$sigma))),
                                    ceiling(max(c(my_df$beta + my_df$se, my_df$sigma))),
                                    by = 1)) +  # Create integer breaks
    ylab("") + xlab("") +
    theme_minimal() +
    theme(legend.text = element_text(size = 12),
          axis.text.y = element_text(angle = 0, hjust = 1),
          legend.position = "bottom" )
}

# Exclude one row because its coefficient is so large it cannot be displayed
results_df_01_no_outliers <- results_df_01 %>% 
  filter(!sector %in% c("Information and communication")) 

results_plot_01 <- get_results_plot(results_df_01_no_outliers, sector_results_01)
results_plot_ter <- get_results_plot(results_df_ter, sector_results_ter)


results_df_01 %>% arrange(sigma)

# Save plots -------------------------------------------------------------------
results_plot_01
ggsave(filename = paste0(wd, "/gdtc/plots/results_region.png"),
       width = 6, height = 6, dpi = 300)
results_plot_ter
ggsave(filename = paste0(wd, "/gdtc/plots/results_region_tertiary.png"),
       width = 6, height = 2, dpi = 300)


# REST NOT USED ################################################################
# Add first stage result to plot
get_results_plot_tests <- function(my_plot) {
  my_plot + 
    geom_text(aes(label = paste0("(1st stage: ", first_stage, 
                                 "\n 2nd stage: ", second_stage, 
                                 "\n", expression(sigma), ": ", round(sigma,3), ")"),
                  x = -1.2),
              size = 3, hjust = 0)
}

plot_results_tests_01 <- get_results_plot_tests(results_plot_01)
plot_results_tests_ter <- get_results_plot_tests(results_plot_ter)
