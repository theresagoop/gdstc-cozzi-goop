# Descriptive stats for shifts and shares ######################################

# Clear environment
rm(list=ls())

source("D:/PhD Docs/thesisgit/gender-directed-change/data/gdtc/2b_get_data_for_bartik_2012.R")


# Shifts #######################################################################
# Long format shift data
get_shifts_df_long <- function(df) {
  df %>% 
    pivot_longer(
      cols = c(growth_m, growth_w, shift_m, shift_w, 
               regional_m, regional_w, national_m, national_w),
      names_to = c(".value", "sex"),
      names_pattern = "(.+)_(m|w)"
    )
}

df_shifts_01_long <- get_shifts_df_long(df_shifts_01)
df_shifts_ter_long <- get_shifts_df_long(df_shifts_ter)

# Table with growth values, mean, and sd
get_shifts_descriptives <- function(df, my_aggregation_level, my_gender) {
  df %>%
    filter(sex == my_gender) %>%
    group_by({{my_aggregation_level}}, year) %>% 
    summarise(growth = first(growth)) %>% # No need to average bc. growth rates are nation-wide, so they are the same for all regions within a sector-year
    mutate(growth = round(growth, 2)) %>%
    pivot_wider(names_from = year, values_from = c(growth)) %>%
    mutate(mean_growth = mean(c(`2014`, `2016`, `2018`, `2020`)),
           sd_growth = sd(c(`2014`, `2016`, `2018`, `2020`))) %>% 
    #dplyr::select(-sex) %>%
    set_names(c("Sector", "2012-2014", "2012-2016", "2012-2018", 
                "2012-2020", "Mean", "sd"))
}

shifts_descriptives_01_w <- get_shifts_descriptives(df_shifts_01_long, noga_01_description, "w")
shifts_descriptives_01_m <- get_shifts_descriptives(df_shifts_01_long, noga_01_description, "m")
shifts_descriptives_ter_w <- get_shifts_descriptives(df_shifts_ter_long, tertiary_description, "w")
shifts_descriptives_ter_m <- get_shifts_descriptives(df_shifts_ter_long, tertiary_description, "m")

get_latex_table <- function(df, my_gender) {
  df %>%
    kbl(
      format = "latex",
      booktabs = TRUE,
      digits = 2,
      align = c("l", "c", "c", "c", "c", "c", "c"),  # Left-align first column, center others
      caption = paste0("National growth rates by sector, ", my_gender),
      label = paste0("growth_rates_", my_gender)
    ) %>%
    kable_styling(latex_options = "hold_position") %>%  # Keeps table position fixed
    column_spec(5, border_right = TRUE) %>%  # Vertical line before "Mean"
    column_spec(1, width = "4cm", latex_valign = "m") %>% # Cap width of first column
    row_spec(0, extra_latex_after = "\\midrule") %>%  # Fine midrule after header
    row_spec(1:nrow(df), hline_after = TRUE, 
             extra_latex_after = "\\specialrule{0.4pt}{0pt}{0pt}") # Fine lines after each row
}

get_latex_table <- function(df, my_gender) {
  df %>%
    kbl(
      format = "latex",
      booktabs = TRUE,
      digits = 2,
      align = c("l", "c", "c", "c", "c", "c", "c"),
      caption = paste0("National growth rates by sector, ", my_gender),
      label = paste0("growth_rates_", my_gender)
    ) %>%
    kable_styling(latex_options = "hold_position") %>%
    column_spec(5, border_right = TRUE) %>%
    column_spec(1, width = "4cm", latex_valign = "m")
}

get_latex_table(shifts_descriptives_01_w, "women")
get_latex_table(shifts_descriptives_01_m, "men")
get_latex_table(shifts_descriptives_ter_w, "women")
get_latex_table(shifts_descriptives_ter_m, "men")


# Shares #######################################################################
# Get spatial data on Switzerland ----------------------------------------------
# Define the URL for Swiss cantons (GeoJSON)
geojson_url <- "https://data.opendatasoft.com/explore/dataset/georef-switzerland-kanton@public/download/?format=geojson&timezone=Europe/Berlin&lang=en"

# Read the GeoJSON file
swiss_cantons <- st_read(geojson_url)

# Define the mapping of cantons to major regions
canton_to_region <- data.frame(
  KANTONSNAME = c("Vaud", "Valais", "Geneva", "Bern", "Fribourg", "Solothurn", "Neuchâtel", "Jura",
                  "Basel-Stadt", "Basel-Landschaft", "Aargau", "Zürich", "Glarus", "Schaffhausen", "Appenzell Ausserrhoden",
                  "Appenzell Innerrhoden", "St. Gallen", "Graubünden", "Thurgau", "Luzern", "Uri", "Schwyz",
                  "Obwalden", "Nidwalden", "Zug", "Ticino"),
  Major_Region = c("R. Lémanique", "R. Lémanique", "R. Lémanique", "Espace Mittelland", "Espace Mittelland", "Espace Mittelland",
                   "Espace Mittelland", "Espace Mittelland", "Nordwestschweiz", "Nordwestschweiz", "Nordwestschweiz",
                   "Zurich", "Ostschweiz", "Ostschweiz", "Ostschweiz", "Ostschweiz", "Ostschweiz", "Ostschweiz", 
                   "Ostschweiz", "Zentralschweiz", "Zentralschweiz", "Zentralschweiz", "Zentralschweiz", "Zentralschweiz",
                   "Zentralschweiz", "Ticino")
)

# Merge the region data with the spatial data
swiss_cantons <- merge(swiss_cantons, canton_to_region, 
                       by.x = "kan_name", by.y = "KANTONSNAME")

# Aggregate cantons into major regions
major_regions_sf <- swiss_cantons %>%
  group_by(Major_Region) %>%
  summarize(geometry = st_union(geometry), .groups = "drop") %>%
  st_as_sf()

# Compute centroids
major_regions_centroids <- major_regions_sf %>%
  mutate(lon = st_coordinates(st_centroid(geometry))[,1], 
         lat = st_coordinates(st_centroid(geometry))[,2]) %>%
  dplyr::select(Major_Region, lon, lat)

# Get shares data --------------------------------------------------------------
# Disaggregated sectors
df_shares_01 <- df_shares_2012_01 %>%
  group_by(sector_01, noga_01_description, region) %>%
  summarise(share_2012_women = paste0(round(100*mean(share_2012_w),1),"%"),
            share_2012_men = paste0(round(100*mean(share_2012_m),1),"%")) %>%
  mutate(label = paste0("F: ", share_2012_women, "\nM: ", share_2012_men))

# Aggregated sectors
df_shares_ter <- df_shares_2012_ter %>%
  group_by(tertiary_description, region) %>%
  summarise(share_2012_women = paste0(round(100*mean(share_2012_w),1),"%"),
            share_2012_men = paste0(round(100*mean(share_2012_m),1),"%")) %>%
  mutate(label = paste0("F: ", share_2012_women, "\nM: ", share_2012_men))

# Get spatial plots by sector --------------------------------------------------
get_spatial_plot <- function(tertiary = FALSE, my_sector) {
  # Filter data for a specific sector
  ifelse(tertiary == FALSE, 
         df_sector_shares <- df_shares_01 %>% filter(sector_01 == my_sector),
         df_sector_shares <- df_shares_ter %>% filter(tertiary_description == my_sector))
  
  # Get sector description
  sector_description <- ifelse(tertiary == FALSE, 
                               unique(df_sector_shares$noga_01_description),
                               unique(df_sector_shares$tertiary_description))
  
  # Merge the centroids with your original data
  region_data <- left_join(df_sector_shares, major_regions_centroids, 
                           by = c("region" = "Major_Region"))
  
  # Get plot
  ggplot(data = swiss_cantons) +
    geom_sf(aes(fill = Major_Region), color = "white", size = 0.5) +
    geom_text(data = region_data, aes(x = lon, y = lat, label = label), 
              color = "black", size = 3, fontface = "bold") +  # Adjust text size
    scale_fill_brewer(palette = "Set3") +
    #ggtitle(paste0(sector_description, ": 2012 shares by region")) +
    coord_sf(expand = FALSE) + 
    theme_void() +
    theme(legend.title = element_blank(),
          plot.margin = unit(c(-4, 0.1, -4, 0.1), "cm"),
          legend.position = "bottom"
    )
}

# Get aggregated spatial plots
spatial_plot_manufacturing <- get_spatial_plot(TRUE, "Manufacturing")
spatial_plot_services <- get_spatial_plot(TRUE, "Services")

# Get disaggregated spatial plots
my_disaggregated_sectors <- c("B-E", "F", "G", "H", "I", "J", "K", 
                              "L/N", "M", "O", "Q", "R/S")
spatial_plots <- lapply(my_disaggregated_sectors, 
                        function(cat) get_spatial_plot(FALSE, cat))
names(spatial_plots) <- my_disaggregated_sectors

# Save plots -------------------------------------------------------------------
# Define output directory
output_dir <- paste0(wd, "/gdtc/plots/")

# Save aggregated
spatial_plot_manufacturing
ggsave(filename = paste0(output_dir, "spatial_manufacturing.png"),
       width = 5, height = 4, dpi = 300)
spatial_plot_services
ggsave(filename = paste0(output_dir, "spatial_services.png"),
       width = 5, height = 4, dpi = 300)

# Save all disaggregated
for (k in my_disaggregated_sectors) {
  ggsave(
    filename = paste0(output_dir,"spatial_", gsub("[^A-Za-z0-9]", "_", k), ".png"),
    plot = spatial_plots[[k]],  # Retrieve the plot from the list
    width = 5, height = 4, dpi = 300
  )
}
