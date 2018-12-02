### TODOs ###

# - weight tariffs by gross expenditure rather than trade

### SETUP ###

rm(list=ls())
libs <- c('tidyverse', 'latex2exp', 'readstata13', "patchwork")
sapply(libs, require, character.only = TRUE)

sourceFiles <- list.files("source/")
for (i in sourceFiles) {
  source(paste0("source/", i))
}

Y <- 2004
write_csv(Y %>% as.data.frame(), "clean/tarYval.csv")

### DATA ###

ccodes <- read_csv("clean/ccodes.csv") %>% pull(.)

fcodes <- read_csv("data/flows/codes.csv") %>% select(i, iso3)
flowshs2 <- read_csv("clean/flowshs2all.csv")

tar2001 <- read_delim("data/tar/2001.txt", "\t")
tar2001$year <- 2001

tar2004 <- read_delim("data/tar/2004.txt", "\t")
tar2004$year <- 2004
colnames(tar2004)[colnames(tar2004)=="Partner"] <- "partner"

tar2007 <- read_delim("data/tar/2007.txt", "\t")
tar2007$year <- 2007

tarL <- list(tar2001, tar2004, tar2007)

tar <- bind_rows(tarL)

colnames(fcodes) <- c("partner", "i_iso3")
tar <- left_join(tar, fcodes)

colnames(fcodes) <- c("reporter", "j_iso3")
tar <- left_join(tar, fcodes)

tar <- tar %>% select(i_iso3, j_iso3, hs2, year, adv)
tar <- left_join(tar, flowshs2)  # append flows

tar$val <- ifelse(is.na(tar$val), 0, tar$val)

# map EU/ROW
tar$i_iso3 <- mapEU(tar$i_iso3, tar$year)
tar$j_iso3 <- mapEU(tar$j_iso3, tar$year)

tar$i_iso3 <- ifelse(tar$i_iso3 %in% ccodes, tar$i_iso3, "ROW")
tar$j_iso3 <- ifelse(tar$j_iso3 %in% ccodes, tar$j_iso3, "ROW")

tarAgg <- tar %>% group_by(i_iso3, j_iso3, year) %>%
  summarise(wtar=weighted.mean(adv, val),
            val=sum(val))

tarAggY <- tarAgg %>% filter(year==Y)
tarAggY <- tarAggY %>% filter(i_iso3!=j_iso3)

tarAggY$year <- Y

### EXPORT ###

write_csv(tarAggY, "clean/tarY.csv")

### PLOTS ##
