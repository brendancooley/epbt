### TODOs ###

# - weight tariffs by gross expenditure rather than trade

### SETUP ###

shiny <- FALSE
source("params.R")

libs <- c('tidyverse', 'latex2exp', 'readstata13', "patchwork", "countrycode")
ipak(libs)

# Y <- 2004
write_csv(Y %>% as.data.frame(), paste0(otherdir, "tarYval.csv"))

### DATA ###

ccodes <- read_csv(paste0(cleandir, "ccodes.csv")) %>% pull(.)

fcodes <- read_csv(paste0(datadir, "flows/codes.csv")) %>% select(i, iso3)
flowshs2 <- read_csv(paste0(cleandir, "flowshs2all.csv"))

# flows with EU aggregated
flowshs2EU <- read_csv(paste0(cleandir, "flowshs2.csv"))

# macmap
tar2001 <- read_delim(paste0(datadir, "tar/2001.txt"), "\t")
tar2001$year <- 2001

tar2004 <- read_delim(paste0(datadir, "tar/2004.txt"), "\t")
tar2004$year <- 2004
colnames(tar2004)[colnames(tar2004)=="Partner"] <- "partner"

tar2007 <- read_delim(paste0(datadir, "tar/2007.txt"), "\t")
tar2007$year <- 2007

tarL <- list(tar2001, tar2004, tar2007)

tar <- bind_rows(tarL)

colnames(fcodes) <- c("partner", "i_iso3")
tar <- left_join(tar, fcodes)

colnames(fcodes) <- c("reporter", "j_iso3")
tar <- left_join(tar, fcodes)

tar <- tar %>% select(i_iso3, j_iso3, hs2, year, adv)

tar <- left_join(tar, flowshs2) %>% select(i_iso3, j_iso3, hs2, year, adv, val) # append flows

# map EU/ROW
tar$i_iso3 <- mapEU(tar$i_iso3, tar$year)
tar$j_iso3 <- mapEU(tar$j_iso3, tar$year)

tar$i_iso3 <- ifelse(tar$i_iso3 %in% ccodes, tar$i_iso3, ROWname)
tar$j_iso3 <- ifelse(tar$j_iso3 %in% ccodes, tar$j_iso3, ROWname)
# tar %>% filter(j_iso3=="EU", year==2007)

tar$val <- ifelse(is.na(tar$val), 0, tar$val)

tarAgg <- tar %>% group_by(i_iso3, j_iso3, year) %>%
  summarise(wtar=weighted.mean(adv, val, na.rm=T),
            val=sum(val))

# unctad (WB, 2011)
tar2011 <- read_csv(paste0(datadir, "tar/2011.csv"))

tar2011$j_iso3 <- countrycode(tar2011$`Reporter Code`, "iso3n", "iso3c")
tar2011$j_iso3 <- ifelse(tar2011$`Reporter Code` == 918, "EU", tar2011$j_iso3)

tar2011$`Partner Code` <- as.integer(tar2011$`Partner Code`)
tar2011$i_iso3 <- countrycode(tar2011$`Partner Code`, "iso3n", "iso3c")
# tar2011$i_iso3 <- ifelse(tar2011$`Partner Code` == 918, "EU", tar2011$i_iso3)

tar2011$adv <- as.numeric(tar2011$`2011 [2011]`) / 100

tar2011 <- tar2011 %>% select(`Product Code`, i_iso3, j_iso3, adv)
colnames(tar2011) <- c("hs2", "i_iso3", "j_iso3", "adv")
tar2011$year <- 2011

# map EU
tar2011 <- left_join(tar2011, flowshs2) %>% select(i_iso3, j_iso3, hs2, year, adv, val) # join everything except EU trade observations
colnames(flowshs2EU)[colnames(flowshs2EU)=="val"] <- "val2"
tar2011 <- left_join(tar2011, flowshs2EU)
tar2011$val <- ifelse(is.na(tar2011$val), tar2011$val2, tar2011$val)
tar2011 <- tar2011 %>% select(i_iso3, j_iso3, hs2, year, adv, val) # append EU flows
# tar2011 %>% filter(j_iso3=="EU")
# tar2011 %>% filter(i_iso3 %in% EU27, j_iso3!="EU") %>% print(n=1000)

tar2011$i_iso3 <- mapEU(tar2011$i_iso3, tar2011$year)
tar2011 <- tar2011 %>% filter(!(i_iso3=="EU" & j_iso3=="EU")) %>% filter(i_iso3!=j_iso3)

# tar2011 %>% filter(j_iso3=="EU")
# tar2011 %>% filter(i_iso3=="EU")

tar2011$val <- ifelse(is.na(tar2011$val), 0, tar2011$val)

tar2011Agg <- tar2011 %>% group_by(i_iso3, j_iso3, year) %>%
  summarise(wtar=weighted.mean(adv, val, na.rm=T),
            val=sum(val))

# join with other years
tarAgg <- bind_rows(tarAgg, tar2011Agg)



### EXPORT ###

tarAggY <- tarAgg %>% filter(year==Y)
tarAggY <- tarAggY %>% filter(i_iso3!=j_iso3)

tarAggY$year <- Y
# tarAggY %>% summary()
# tarAggY %>% filter(is.na(wtar))
# # Note: no data on Vietnam

write_csv(tarAggY, paste0(cleandir, "tarY.csv"))

### PLOTS ##
