######## if the priority table changes with every loop this should be on a separate script
### add resistance values and description to the table
priority_table$feature[1] <- c('industrial')
priority_table$feature[2] <- c('commercial')
priority_table$feature[10] <- c('bare_soil')
priority_table$feature[13] <- c('water')
priority_table <- unique(priority_table)

priority_table$feature[16] <- c('linear_feature_sidewalks')
priority_table$feature[23] <- c('linear_feature_trams')
priority_table$feature[24] <- c('linear_feature_trails')  ###CHANGED FROM 23 TO 24!!!!!!!!!!!!
priority_table$feature[26] <- c('linear_feature_unused_rails')

## adding initial resistance values here 
priority_table$res_LM <- c(60,50,40,35,30, #landuse classes
                           15,8,10,15,5,#landcover classes
                           70, #water
                           45,100, #concrete surface
                           80,30,40,25,35,40,45,50,10, #physical infrastructure:roads
                           40,10,15,10, #physical infrastructure:rails
                           70 #physical infrastructure:barriers
) #

priority_table$res_SM <- c(60,50,40,35,30, #landuse classes
                           15,8,10,15,5, #landcover classes
                           100, #water
                           45,100, #concrete surface
                           100,30,40,25,35,40,45,50,10, #physical infrastructure:roads
                           40,10,15,10, #physical infrastructure:rails
                           70 #physical infrastructure:barriers
)
priority_table<-priority_table %>% select(-n)
write.csv(priority_table, 'priority_table.csv')

###reclassification table for CEC
pri <- priority_table %>% select(feature, priority)
colnames(pri)<- c('mcsc', 'mcsc_value')

cec <- read.csv('cec_north_america.csv')
rec_cec <- left_join(cec, pri, by='mcsc')
rec_cec_final <- rec_cec %>% mutate(mcsc_value = ifelse(mcsc == 'developed_na', 28, mcsc_value))
write.csv(rec_cec_final, 'reclass_cec_2_mcsc.csv')

###reclassification table for copernicus
cop <- read.csv('copernicus_reclassification_table.csv') %>% select (copernicus, value, mcsc)
rec_cop <- left_join(cop, pri, by='mcsc')
rec_cop %>% filter(is.na(mcsc_value)) ###FIX THISSSSS
#rec_cop$mcsc[6]<-'linear_feature_na_traffic' 
rec_cop$mcsc[7]<-'linear_feature_na_traffic' 
rec_cop$mcsc[23]<-'linear_feature_vh_traffic'
rec_cop$mcsc[9]<-'linear_feature_rail'   
rec_cop <- rec_cop %>% select(1,2,3)
rec_cop <- left_join(rec_cop, pri, by='mcsc')
rec_cop_final <- rec_cop %>% mutate(mcsc_value= ifelse(mcsc == 'developed_na', 28, mcsc_value))

write.csv(rec_cop_final, 'reclass_copernicus_2_mcsc.csv')
