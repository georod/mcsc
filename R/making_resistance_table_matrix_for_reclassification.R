### code to create resistance csv matching the classes from this table, including descriptions
##TGC
library(dplyr)

df<-  matrix(seq(1,23,1), ncol=1, byrow=TRUE)
df<-data.frame(df)
colnames(df) <- c("class")

df <- df %>% 
  #resistance values define the resistance to movement of each feature
  ##landuse background
  mutate(description = ifelse(class == 1, "industrial", "")) %>%
  mutate(description = ifelse(class == 2, "commercial", description)) %>%
  mutate(description = ifelse(class == 3, "institutional", description))%>%
  mutate(description = ifelse(class == 4, "residential", description))%>%
  ##green background
  mutate(description = ifelse(class == 5, "open_green_area", description))%>%
  mutate(description = ifelse(class == 6, "resourceful_green_area", description))%>%  
  mutate(description = ifelse(class == 7, "hetero_green_area", description))%>%
  mutate(description = ifelse(class == 8, "dense_green_area", description))%>%
  ##built infrastructure
  mutate(description = ifelse(class == 9, "parking_surface", description))%>%
  mutate(description = ifelse(class == 10, "building", description))%>%
  ##roads - highways go below other linear descriptions to allow for over and underpasses
  mutate(description = ifelse(class == 11,"roads_vh_traffic", description))%>%
  mutate(description = ifelse(class == 12, "roads_na_traffic", description))%>%
  mutate(description = ifelse(class == 13, "roads_vl_traffic", description))%>%
  mutate(description = ifelse(class == 14, "roads_l_traffic", description))%>%  
  mutate(description = ifelse(class == 15, "roads_m_traffic", description))%>%
  mutate(description = ifelse(class == 16, "roads_h_traffic_ls", description))%>%
  mutate(description = ifelse(class == 17, "roads_h_traffic_hs", description))%>%
  #trams included here
  mutate(description = ifelse(class == 18, "tram", description))%>%
  ##pedestrian roads #allows for overpasses and underpasses by being set with higher description as roads
  mutate(description = ifelse(class == 19, "trails", description))%>%
  #mutate(description = ifelse(class == 20, "sidewalks", description))%>%
  ##railways
  mutate(description = ifelse(class == 20, "rails", description))%>%
  mutate(description = ifelse(class == 21, "unused_rails", description))%>%
  ##barriers (too thin to appear on 30m resolution layer, useful for other purposes) 
  mutate(description = ifelse(class == 22, "barrier", description))%>%
  ##flooded surface (note includes wetlands, if wetlands want to be separated sql code should be changed)
  mutate(description = ifelse(class == 23, "water", description))

#write.csv(df_unique_res, 'df_unique_res_2.csv') 
##set resistance values across layers -- this step could be bypassed by creating only the landcover layer and reclassifying the classes into the resistance values, I am creating R script for that
df<- df %>% 
  #resistance values define the resistance to movement of each feature
  ##landuse background
  mutate(res_large_mammals = ifelse(class == 1, 70, 0)) %>%
  mutate(res_large_mammals = ifelse(class == 2, 50, res_large_mammals)) %>%
  mutate(res_large_mammals = ifelse(class == 3, 35, res_large_mammals))%>%
  mutate(res_large_mammals = ifelse(class == 4, 40, res_large_mammals))%>%
  ##green background
  mutate(res_large_mammals = ifelse(class == 5, 15, res_large_mammals))%>%
  mutate(res_large_mammals = ifelse(class == 6, 10, res_large_mammals))%>%  
  mutate(res_large_mammals = ifelse(class == 7, 10, res_large_mammals))%>%
  mutate(res_large_mammals = ifelse(class == 8, 5, res_large_mammals))%>%
  ##built infrastructure
  mutate(res_large_mammals = ifelse(class == 9, 20, res_large_mammals))%>%
  mutate(res_large_mammals = ifelse(class == 10, 100, res_large_mammals))%>%
  ##roads - highways go below other linear classs to allow for over and underpasses
  mutate(res_large_mammals = ifelse(class == 11, 80, res_large_mammals))%>%
  mutate(res_large_mammals = ifelse(class == 12, 40, res_large_mammals))%>%
  mutate(res_large_mammals = ifelse(class == 13, 25, res_large_mammals))%>%
  mutate(res_large_mammals = ifelse(class == 14, 35, res_large_mammals))%>%  
  mutate(res_large_mammals = ifelse(class == 15, 40, res_large_mammals))%>%
  mutate(res_large_mammals = ifelse(class == 16, 45, res_large_mammals))%>%
  mutate(res_large_mammals = ifelse(class == 17, 50, res_large_mammals))%>%
  #trams included here
  mutate(res_large_mammals = ifelse(class == 18, 45, res_large_mammals))%>%
  ##pedestrian roads #allows for overpasses and underpasses by being set with higher res_large_mammals as roads
  mutate(res_large_mammals = ifelse(class == 19, 15, res_large_mammals))%>%
  #mutate(res_large_mammals = ifelse(class == 20, 20, res_large_mammals))%>%
  ##railways
  mutate(res_large_mammals = ifelse(class == 20, 15, res_large_mammals))%>%
  mutate(res_large_mammals = ifelse(class == 21, 10, res_large_mammals))%>%
  ##barriers (too thin to appear on 30m resolution layer, useful for other purposes) 
  mutate(res_large_mammals = ifelse(class == 22, 70, res_large_mammals))%>%
  ##flooded surface (note includes wetlands, if wetlands want to be separated sql code should be changed)
  mutate(res_large_mammals = ifelse(class == 23, 100, res_large_mammals)) 



df  <- df %>% 
  mutate(res_small_mammals = ifelse(class == 9, 30, res_large_mammals))%>%
  mutate(res_small_mammals = ifelse(class == 4, 30, res_small_mammals))%>%
  mutate(res_small_mammals = ifelse(class == 3, 30, res_small_mammals))%>%
  mutate(res_small_mammals = ifelse(class == 13,40, res_small_mammals))%>% 
  mutate(res_small_mammals = ifelse(class == 14, 50, res_small_mammals))%>%
  mutate(res_small_mammals = ifelse(class == 15, 65, res_small_mammals))%>%
  mutate(res_small_mammals = ifelse(class == 16, 70, res_small_mammals))%>%
  mutate(res_small_mammals = ifelse(class == 17, 80, res_small_mammals))%>%
  mutate(res_small_mammals = ifelse(class == 11, 95, res_small_mammals))

df  <- df %>% 
  mutate(source_strength = ifelse(class == 5, 5, NA))%>%
  mutate(source_strength = ifelse(class == 6, 15, source_strength))%>%
  mutate(source_strength = ifelse(class == 7, 15, source_strength))%>%
  mutate(source_strength = ifelse(class == 8,20, source_strength))

write.csv(df, "resistance_table.csv", row.names=FALSE)


###reclassifying a landcover raster from this table

df<-read.csv("resistance_table.csv")

res_lm <- df %>% dplyr::select(class, res_large_mammals) %>%
  mutate(class = as.numeric(class)) %>%
  mutate(res_large_mammals = as.numeric(res_large_mammals))%>%
  as.matrix()

res_sm <- df %>% dplyr::select(class, res_small_mammals) %>%
  mutate(class = as.numeric(class)) %>%
  mutate(res_small_mammals = as.numeric(res_small_mammals))%>%
  as.matrix()

source_strength <- df %>% dplyr::select(class, source_strength) %>%
  mutate(class = as.numeric(class)) %>%
  mutate(source_strength = as.numeric(source_strength))%>%
  as.matrix()


library(raster)
all_lcover <- raster("all_lcover.tif")
all_features_lm.tif <- reclassify(all_lcover,
                                  res_lm)

all_features_sm.tif <- reclassify(all_lcover,
                                  res_sm)

sources.tif <- reclassify(all_lcover,
                          source_strength)

#plot(sources.tif)
