### TODOs ###

### SETUP ###

shiny <- FALSE
source("params.R")

libs <- c('tidyverse', "countrycode")
ipak(libs)

### DATA ###

ccodes <- read_csv(paste0(cleandir, "ccodes.csv")) %>% pull(.)

pta <- read_csv(paste0(datadir, "pta/pta.csv"), col_types=list(number=col_character())) %>% select(iso1, iso2, entryforceyear) %>% filter(!is.na(entryforceyear))
colnames(pta) <- c("i_iso3n", "j_iso3n", "sYear")

pta$i_iso3 <- countrycode(pta$i_iso3n, "iso3n", "iso3c")
pta$j_iso3 <- countrycode(pta$j_iso3n, "iso3n", "iso3c")

pta <- pta %>% select(i_iso3, j_iso3, sYear)

# select PTAs in data
pta1 <- pta %>% filter(i_iso3 %in% ccodes & j_iso3 %in% ccodes)

# directed dyads
pta2 <- pta1
colnames(pta2) <- c("j_iso3", "i_iso3", "sYear")
ptaC <- bind_rows(pta1, pta2)

ptaC <- ptaC %>% unique()

# dyad-year observations
ptaCY <- ptaC %>%
  rowwise() %>%
  do(data.frame(i_iso3=.$i_iso3, j_iso3=.$j_iso3,
                year=seq(.$sYear,2017)))

ptaCY$pta <- 1

ptaY <- ptaCY %>% filter(year==Y)
ptaY <- ptaY %>% unique()

write_csv(ptaY, paste0(cleandir, "ptaY.csv"))
