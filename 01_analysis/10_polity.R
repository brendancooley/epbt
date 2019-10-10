### SETUP ###

source("params.R")

libs <- c('tidyverse', 'countrycode')
ipak(libs)

### CLEAN DATA ###

# use EU variation
ccodes <- read_csv(paste0(cleandirEU, "ccodes.csv")) %>% pull(.)

polity <- read_csv(paste0(datadir, "polity/polity.csv")) %>% filter(year==Y) %>% select(scode, polity2)
colnames(polity) <- c("cowc", "polity2")
polity$iso3 <- countrycode(polity$cowc, "cowc", "iso3c")
polity <- polity %>% filter(iso3 %in% ccodes) %>% select(-cowc)
write_csv(polity, paste0(cleandirEU, "polity.csv"))

polity %>% print(n=100)
