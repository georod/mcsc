setwd('C:/Users/tizge/Documents/StructuralconnectivityDB) 

####### reference database #######3
#[1] "0190368-230224095556074.csv" "0213643-230224095556074.csv"
#[3] "0213648-230224095556074.csv" "0213657-230224095556074.csv"
#[5] "0213678-230224095556074.csv" "0213692-230224095556074.csv"
#[7] "0213697-230224095556074.csv"
###################################
path_to_downlad = "GBIF_data/"
GBIF_data <- list.files(path_to_downlad) 

mammals_all <- data.frame()
for (i in GBIF_data){
  gbif_download_key = i
  mammals<- data.table::fread(paste0(path_to_downlad,gbif_download_key))
  mammals<- mammals %>% select(order,family,genus,scientificName, decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters, countryCode, stateProvince, eventDate, basisOfRecord, institutionCode)
  mammals<- mammals %>% mutate(y = as.numeric(decimalLatitude), 
                               x = as.numeric(decimalLongitude))
  mammals <- mammals %>% filter(!is.na(x) & !is.na(y)) 
  #paste0('mammals_', as.character(levels(factor(mammals$order))[1])) <- mammals
  mammals_all <- rbind(mammals_all, mammals)
}

##clean GBIF data, leave only relevant genus/orders/families
mammals_all <- mammals_all %>% filter(!(family %in% c("Bovidae" ,"Hippopotamidae","", "Phocidae","Odobenidae","Otariidae","Odobenidae"))) %>%
  filter(!(scientificName %in% c("Canis lupus familiaris Linnaeus, 1758", "Canis familiaris Linnaeus, 1758")))
carn_big <- c("Canidae","Felidae","Ursidae")  
carn_small <- c("Eupleridae","Ailuridae","Hyaenidae","Mephitidae","Mustelidae","Procyonidae","Herpestidae","Viverridae","Nandiniidae")
mammals_all <- mammals_all %>% mutate(order = ifelse(family %in% carn_big, "Carnivora_big", order))
mammals_all <- mammals_all %>% mutate(order = ifelse(family %in% carn_small, "Carnivora_small", order))

write.csv(mammals_all, "GBIF_relevant_mammals_data.csv")
