### TODOs ###

# Follow Kono and just use cross-sectional variation?

# - Note: EU data taken from 2012, due to quirk in data in which all ntms start in this year

### SETUP ###

shiny <- FALSE
source("params.R")

libs <- c('tidyverse')
ipak(libs)

# year to use for EU NTMs
EUntmY <- 2012
mkdir(otherdir)

write_csv(EUntmY %>% as.data.frame(), paste0(otherdir, "EUntmY.csv"))

### DATA ###

flowshs6 <- read_csv(paste0(cleandir, "flowshs6.csv"))
colnames(flowshs6)[colnames(flowshs6) == "v"] <- "val"

ccodes <- read_csv(paste0(cleandir, "ccodes.csv")) %>% pull(.)

flowshs6Y <- flowshs6 %>% filter(year==Y)

flowshs6Y$i_iso3 <- mapEU(flowshs6Y$i_iso3, flowshs6Y$year)
flowshs6Y$j_iso3 <- mapEU(flowshs6Y$j_iso3, flowshs6Y$year)
flowshs6Y$i_iso3 <- ifelse(flowshs6Y$i_iso3 %in% ccodes, flowshs6Y$i_iso3, ROWname)
flowshs6Y$j_iso3 <- ifelse(flowshs6Y$j_iso3 %in% ccodes, flowshs6Y$j_iso3, ROWname)

flowshs6join <- flowshs6Y %>% select(one_of(c("i_iso3", "j_iso3", "hs6", "year", "val")))

rm(flowshs6)

fcodes <- read_csv(paste0(datadir, "flows/codes.csv")) %>% select(i, iso3)

# non tariff measures
ntm <- read_csv(paste0(datadir, "ntm/ntm.csv"))
# test <- ntm %>% select(Dataset_id, ntmcode, reporter, partner, ntm_1_digit, hs6, StartDate, EndDate)
# test %>% unique()
colnames(ntm)[colnames(ntm) %in% c("reporter", "partner")] <- c("j_iso3", "i_iso3")

# ntm$EndDate <- ifelse(is.na(ntm$EndDate), 2017, ntm$EndDate)
# ntm$EndDate <- ifelse(ntm$EndDate > 2017, 2017, ntm$EndDate)
# 
# # expand years
# ntmY <- ntm %>%
#   rowwise() %>%
#   do(data.frame(j_iso3=.$j_iso3, i_iso3=.$i_iso3, ntm_1_digit=.$ntm_1_digit, hs6=.$hs6,
#                 year=seq(.$StartDate,.$EndDate)))


# group ntm codes
core <- c("D", "E", "F", "H")
health_safety <- c("A", "B")
export <- c("P")

ntm$class <- ifelse(ntm$ntm_1_digit %in% core, "core",
                    ifelse(ntm$ntm_1_digit %in% health_safety, "health_safety",
                           ifelse(ntm$ntm_1_digit %in% export, "export", "other")))
ntm$one <- 1

ntmW <- ntm %>% spread(class, one)
ntmW[ , c("core", "export", "health_safety", "other")][is.na(ntmW[ , c("core", "export", "health_safety", "other")])] <- 0
# ntmYW %>% filter(j_iso3=="TUR")


ntmY <- ntmW %>% filter(StartDate<=Y & (EndDate>=Y | is.na(EndDate)))

# ntmW %>% filter(j_iso3=="EUN") %>% summary()
ntmEU <- ntmW %>% filter(j_iso3=="EUN" & (is.na(EndDate) | EndDate >= EUntmY))

ntmAll <- bind_rows(ntmY, ntmEU)
ntmAll$year <- Y

### AGGREGATE ###

# map EU/ROW
ntmAll$i_iso3 <- ifelse(ntmAll$i_iso3=="EUN", "EU", ntmAll$i_iso3)
ntmAll$j_iso3 <- ifelse(ntmAll$j_iso3=="EUN", "EU", ntmAll$j_iso3)
ntmAll$i_iso3 <- mapEU(ntmAll$i_iso3, ntmAll$year)

ntmAll$i_iso3 <- ifelse(ntmAll$i_iso3 %in% c(ccodes, "WLD"), ntmAll$i_iso3, ROWname)
ntmAll$j_iso3 <- ifelse(ntmAll$j_iso3 %in% c(ccodes, "WLD"), ntmAll$j_iso3, ROWname)

# one entry for each country...expand NTMs that are directed at "WLD"
codesstr <- paste(ccodes, collapse=", ")

ntmWLD <- ntmAll %>% filter(i_iso3=="WLD")
ntmWLD$expand <- codesstr
ntmWLDexpand <- ntmWLD %>% mutate(expand=strsplit(as.character(expand), ", ")) %>%
  unnest(expand)
ntmWLDexpand$i_iso3 <- rep(ccodes, nrow(ntmWLD))

ntmOther <- ntmAll %>% filter(i_iso3!="WLD")
ntmOther <- ntmOther %>% filter(i_iso3 != j_iso3)

ntmYWbilateral <- bind_rows(ntmWLDexpand, ntmOther)

ntmAgg <- ntmYWbilateral %>% group_by(i_iso3, j_iso3, hs6) %>%
  summarise(
    coreN=sum(core),
    exportN=sum(export),
    health_safetyN=sum(health_safety),
    otherN=sum(other)
  )
ntmAggBin <- ntmAgg
for (i in c("coreN", "exportN", "health_safetyN", "otherN")) {
  ntmAggBin[[i]] <- ifelse(ntmAggBin[[i]] >= 1, 1, 0)
}

ntmAggBinFlows <- left_join(flowshs6join, ntmAggBin, by=c("i_iso3", "j_iso3", "hs6"))
ntmAggBinFlows[is.na(ntmAggBinFlows)] <- 0

ntmCoverage <- ntmAggBinFlows %>% group_by(i_iso3, j_iso3) %>%
  summarise(
    core=sum(coreN*val)/sum(val),
    health_safety=sum(health_safetyN*val)/sum(val),
    other=sum(otherN*val)/sum(val)
  )

ntmCoverage <- ntmCoverage %>% filter(i_iso3!=j_iso3, !(j_iso3 %in% c("KOR", ROWname))) # no NTM data on Korea, ROW aggregates over too many countries
ntmCoverage$year <- Y

### EXPORT ###

write_csv(ntmCoverage, paste0(cleandir, "ntmY.csv"))
