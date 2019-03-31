### TODOs ###

### SETUP ###

rm(list=ls())
libs <- c('tidyverse', 'R.utils', 'countrycode', 'stargazer')
sapply(libs, require, character.only = TRUE)

sourceFiles <- list.files("source/")
for (i in sourceFiles) {
  source(paste0("source/", i))
}

source("params.R")

EUD <- TRUE # disaggregate EU?
startY <- 1995
endY <- 2011

cleandir <- "clean/"
mkdir(cleandir)

# import OECD IOTS and select which countries to include in analysis
ccodesOECD <- list.dirs("data/iots/", full.names=FALSE)
ccodesOECD <- ccodesOECD[nchar(ccodesOECD) > 0]

### GROSS OUTPUT CALCULATIONS ###

wiotL <- list()

tick <- 1
for (i in seq(startY, endY)) {
  year <- i
  wiotpath <- paste0('data/wiot/', year, '.csv')
  wiotY <- read_csv(wiotpath)
  wiotL[[tick]] <- wiotY
  tick <- tick + 1
}

wiot <- bind_rows(wiotL)
summary(wiot)

ccodes <- unique(wiot$col_country)

# aggregate European Union (CHE is Switzerland, HRV is Croatia)
if (EUD==FALSE) {
  wiot$col_country <- mapEU(wiot$col_country, wiot$year)
}

# drop HRV CHE due to limited trade observations, Croatia doesn't join EU until 2013, TWN difficult to map to COMTRADE
ccodesWIOT <- setdiff(wiot$col_country, c("RoW", "TWN", "HRV", "CHE"))
if (EUD==FALSE) {
  ccodesWIOT <- setdiff(ccodesWIOT, EU27)
}

wiot$col_country <- ifelse(wiot$col_country %in% ccodesWIOT, wiot$col_country, "ROW")

# calculate GDP
gdp <- wiot %>% group_by(col_country, year) %>% filter(row_country=="VA") %>%
  summarise(gdp=sum(value)) %>% ungroup()
colnames(gdp) <- c("iso3", "year", "gdp")
# gdp %>% filter(year==2011)

# calculate gross output
go <- wiot %>% group_by(col_country, year) %>% filter(row_country=="GO") %>%
  summarise(go=sum(value)) %>% ungroup()
colnames(go) <- c("iso3", "year", "go")

# calculate gross consumption
gc <- wiot %>% group_by(col_country, year) %>% filter(row_country=="TOT") %>%
  summarise(gc=sum(value)) %>% ungroup()
colnames(gc) <- c("iso3", "year", "gc")

# drop <- setdiff(ccodesOECD, "SGP")  # just Singapore version
drop <- ccodesDrop  # all OECD version
include <- setdiff(ccodesOECD, drop)

for (i in seq(startY, endY)) {
  for (j in include) {
    
    iotpath <- paste0("data/iots/", j, "/", i, ".csv")
    
    iot <- read_csv(iotpath)
    
    iotttl <- iot %>% filter(ROW == 'TTL_INT_FNL')
    iotoutput <- iot %>% filter(ROW == 'OUTPUT')
    iotva <- iot %>% filter(ROW=="VALU")
    iotgc <- sum(iotttl$obsValue)
    iotgo <- sum(iotoutput$obsValue)
    iotgdp <- sum(iotva$obsValue)
    
    gc <- gc %>% add_row("iso3" = j, "year" = i, 'gc' = iotgc)
    go <- go %>% add_row("iso3" = j, "year" = i, 'go' = iotgo)
    gdp <- gdp %>% add_row("iso3" = j, "year" = i, "gdp" = iotgdp)
    
  }
}

# correct ROW
gdpOECD <- gdp %>% filter(iso3 %in% ccodesOECD) %>% group_by(year) %>%
  summarise(gdpOECD = sum(gdp))
gcOECD <- gc %>% filter(iso3 %in% ccodesOECD) %>% group_by(year) %>%
  summarise(gcOECD = sum(gc))
goOECD <- go %>% filter(iso3 %in% ccodesOECD) %>% group_by(year) %>%
  summarise(goOECD = sum(go))

gdp <- left_join(gdp, gdpOECD)
gdp$gdp <- ifelse(gdp$iso3=="ROW", gdp$gdp - gdp$gdpOECD, gdp$gdp)
gdp <- gdp %>% select(-one_of(c("gdpOECD")))
# gdp %>% filter(year==2011) %>% print(n=50)

gc <- left_join(gc, gcOECD)
gc$gc <- ifelse(gc$iso3=="ROW", gc$gc - gc$gcOECD, gc$gc)
gc <- gc %>% select(-one_of(c("gcOECD")))

go <- left_join(go, goOECD)
go$go <- ifelse(go$iso3=="ROW", go$go - go$goOECD, go$go)
go <- go %>% select(-one_of(c("goOECD")))

# calculate trade deficits
goc <- left_join(go, gc)
goc$deficit <- goc$gc - goc$go
# sum(goc$deficit)  # check market clearing with deficits

ccodes <- c(ccodesWIOT, include)

# write to clean dir
if (EUD==FALSE) {
  write_csv(ccodes %>% as.data.frame(), paste0(cleandir, "ccodes.csv"))
  write_csv(gc, paste0(cleandir, "gc.csv"))
  write_csv(gdp, paste0(cleandir, "gdp.csv"))
} else {
  write_csv(ccodes %>% as.data.frame(), paste0(cleandir, "ccodesEUD.csv"))
  write_csv(gc, paste0(cleandir, "gcEUD.csv"))
  write_csv(gdp, paste0(cleandir, "gdpEUD.csv"))
}

# test <- read_csv("clean/ccodesEUD.csv")
# test <- read_csv("clean/gcEUD.csv") %>% filter(year==2011)
