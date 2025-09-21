# Install and load required packages
setwd("~/Dropbox/Segregation/Quantification/ChinaSegregation/tasks/initial_data")

library(sf)
library(geosphere)
library(dplyr)

# Load the shapefile
counties <- st_read("bj_county_2000_epsg4326..shp")

# Ensure the shapefile is in WGS84 (EPSG:4326)
counties <- st_transform(counties, crs = 4326)

# Compute centroids of counties
counties_centroids <- st_centroid(counties)
centroid_coords <- st_coordinates(counties_centroids)

# Compute pairwise distances (in kilometers) using the Haversine formula
distance_matrix_km <- distm(centroid_coords, fun = distHaversine) / 1000

# Convert the distance matrix to a tidy data frame
distance_df <- as.data.frame(as.table(distance_matrix_km))
colnames(distance_df) <- c("Index1", "Index2", "distance_km")

# Add county codes and names to the data frame
distance_df <- distance_df %>%
  mutate(
    county_code1 = counties$countycode[as.numeric(Index1)],
    county_code2 = counties$countycode[as.numeric(Index2)],
    county_name1 = counties$county_200[as.numeric(Index1)],
    county_name2 = counties$county_200[as.numeric(Index2)]
  ) %>%
  select(county_code1, county_name1, county_code2, county_name2, distance_km)  # Keep relevant columns

# Save the bilateral distances to a CSV file
write.csv(distance_df, "bilateral_distances_across_counties.csv", row.names = FALSE)


