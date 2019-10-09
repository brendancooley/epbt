### SETUP ###

source("params.R")

libs <- c('tidyverse')
ipak(libs)

### CLEAN DATA ###

# use EU variation
ccodes <- read_csv(paste0(cleandirEU, "ccodes.csv"))

polity <- read_csv(paste0(datadir, "polity/polity.csv")) %>% filter(year==Y, scode %in% ccodes) %>% select(scode, polity2)
write_csv(polity, paste0(cleandirEU, "polity.csv"))
