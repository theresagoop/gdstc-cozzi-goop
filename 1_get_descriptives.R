# Clear environment
rm(list=ls())

source("D:/PhD Docs/thesisgit/gender-directed-change/data/0_setup.R")

# Load data --------------------------------------------------------------------
datf_final_all <- readRDS(file = paste0(wd_confidential,
                          "/Joined_and_cleaned_raw_data/final_lse_statpop_zas_allyears.rds"))


datf <- datf_final_all %>%
  mutate(sector_tertiary = case_when(
    sector_01 %in% c("B-E", "F") ~ "secondary",
    sector_01 %in% c("G", "H", "I", "J", "K", "L/N", "M", "O", "Q", "R/S") ~ "tertiary",
  )) %>%
  mutate(tertiary_description = case_when(
    sector_tertiary == "secondary" ~ "Manufacturing",
    sector_tertiary == "tertiary" ~ "Services"
  ))

# Plot hours worked by sector --------------------------------------------------
# Labor supply by sector, average over all years
get_descriptives_plot <- function(my_aggregation_level, my_description, my_var) {
  var_name <- deparse(substitute(my_var))
  
  my_plot <- datf %>% 
    group_by({{my_aggregation_level}}, {{my_description}}, sex, year) %>%
    summarise(sum_var = sum({{my_var}})) %>%
    group_by({{my_aggregation_level}}, {{my_description}}, sex) %>%
    summarise(avg_var = mean(sum_var),
              sd_var = sd(sum_var),
              n = n(),
              se_var = sd_var / sqrt(n),
              ci_95 = 1.96 * se_var, .groups = 'drop') %>%
    mutate(sex = case_when(sex == 1 ~ "Men", 
                           sex == 2 ~ "Women", 
                           TRUE ~ as.character(sex))) %>%
    mutate(sector_label = str_replace_all({{my_description}}, 
                                          "((?:\\S+\\s+){3})", "\\1\n")) %>%
    ggplot(aes(y = sector_label, x = avg_var, color = sex, fill = sex)) +
    geom_col(position = position_dodge()) +
    geom_errorbar(aes(xmin = avg_var - ci_95, xmax = avg_var + ci_95),
                  position = position_dodge(width = 0.9),
                  width = 0.2) +
    scale_color_manual(values = c("Women" = hsgdarkgreen, "Men" = hsggreyblue2)) +
    scale_fill_manual(values = c("Women" = hsggreen, "Men" = hsggreyblue)) +
    scale_x_continuous(labels = label_number(scale = 1e-6)) +
    labs(y=NULL, x = if (var_name == "monthlywage") {
      "Monthly wage"
    } else if (var_name == "hours") {
      "Hours worked (millions)"
    } else {
      my_var  # fallback or customize further if needed
    }) +
    theme_minimal() +
    theme(legend.title = element_blank(),
          legend.position = "bottom")
  
  return(my_plot)
}

wages_01 <- get_descriptives_plot(sector_01, noga_01_description, monthlywage)
wages_ter <- get_descriptives_plot(sector_tertiary, tertiary_description, monthlywage)
hours_worked_01 <- get_descriptives_plot(sector_01, noga_01_description, hours)
hours_worked_ter <- get_descriptives_plot(sector_tertiary, tertiary_description, hours)

# Save plots -------------------------------------------------------------------
wages_01
ggsave(filename = paste0(wd, "/gdtc/plots/wages_sector_01.png"),
       width = 5, height = 7, dpi = 300)
wages_ter
ggsave(filename = paste0(wd, "/gdtc/plots/wages_sector_ter.png"),
       width = 5, height = 2, dpi = 300)
hours_worked_01
ggsave(filename = paste0(wd, "/gdtc/plots/hours_worked_sector_01.png"),
       width = 5, height = 7, dpi = 300)
hours_worked_ter
ggsave(filename = paste0(wd, "/gdtc/plots/hours_worked_sector_ter.png"),
       width = 5, height = 2, dpi = 300)


# Plot wage and hours ratios over time -----------------------------------------
# Get wages indexed by 1993 ----------------------------------------------------
# From https://www.bfs.admin.ch/bfs/de/home/statistiken/arbeit-erwerb/loehne-erwerbseinkommen-arbeitskosten/lohnindex/nach-geschlecht.assetdetail.31445513.html
wages <- read_excel(paste0(wd,"/lohnindex.xlsx")) %>%
  filter(WAGE_TYPE == "N",
         SECTION %in% c("C-O", "B-S")) %>%
  dplyr::select(c("YEAR", "SECTION", "SEX", "VALUE")) %>%
  rename(year = YEAR)

wages <- wages %>%
  pivot_wider(id_cols = year, names_from = SEX, values_from = VALUE,
              values_fill = 0) %>% print(n=100) %>%
  mutate(ratio_wages = M/W)

# Get hours --------------------------------------------------------------------
# From https://www.bfs.admin.ch/bfs/de/home/statistiken/arbeit-erwerb/erhebungen/avol.assetdetail.31025788.html
hours_excel <- paste0(wd,"/arbeitsvolumen.xlsx")
sheet_names <- as.character(1991:2023)

hours <- data.frame(
  year = integer(),
  men = numeric(),
  women = numeric()
)

# Extract total values for men and women
for (sheet in sheet_names) {
  # Read cells I6 and J6
  men_value <- read_excel(hours_excel, sheet = sheet, range = "I6", col_names = FALSE)[[1]]
  women_value <- read_excel(hours_excel, sheet = sheet, range = "J6", col_names = FALSE)[[1]]
  
  # Combine into the results data frame
  hours <- rbind(hours, data.frame(
    year = as.integer(sheet),
    men = men_value,
    women = women_value
  ))
}

# Index values and get ratios
hours <- hours %>% 
  mutate(hours_men = men / men[year == 1994] * 100,
         hours_women = women / women[year == 1994] * 100) %>%
  mutate(ratio_hours = hours_men/hours_women)

# Join hours and wages data sets
df <- left_join(wages, hours, by="year")

# Get plot
ratios_by_year <- df %>% ggplot(aes(x=year)) + 
  geom_line(aes(y=ratio_wages, linetype = "Relative wages (M/F)"), color=hsggreyblue2) + 
  geom_line(aes(y=ratio_hours, linetype = "Relative labor supply (M/F)"), color=hsgdarkgreen) +
  scale_linetype_manual(values = c("Relative labor supply (M/F)" = "solid", 
                                   "Relative wages (M/F)" = "longdash")) +
  scale_y_continuous(
    name = "Relative labor supply (M/F)",
    sec.axis = sec_axis(~., name = "Relative wages (M/F)")
  ) +
  scale_x_continuous(breaks = seq(1994, 2023, by=2),
                     labels = seq(1994, 2023, by=2),
                     limits = c(1994, 2023)) +
  xlab("Year") +
  theme_minimal() +
  theme(
    axis.title.y.left = element_text(color = hsgdarkgreen),
    axis.title.y.right = element_text(color = hsggreyblue2),
    legend.title = element_blank(),
    legend.position = "bottom",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# Save plot --------------------------------------------------------------------
ratios_by_year
ggsave(filename = paste0(wd, "/gdtc/plots/ratios_by_year.png"),
       width = 5, height = 4, dpi = 300)


