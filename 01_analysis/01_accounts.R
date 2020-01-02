print("-----")
print("Starting 01_accounts.R")
print("-----")

### Get customizable arguments from command line ###

args <- commandArgs(trailingOnly=TRUE)
if (is.null(args) | identical(args, character(0))) {
  EUD <- FALSE
  TPSP <- FALSE
  mini <- FALSE
} else {
  EUD <- ifelse(args[1] == "True", TRUE, FALSE)
  TPSP <- ifelse(args[2] == "True", TRUE, FALSE)
  mini <- ifelse(args[3] == "True", TRUE, FALSE)
}

# EUD <- FALSE
# TPSP <- FALSE

### SETUP ###

source("params.R")

libs <- c('tidyverse', 'R.utils', 'countrycode', 'stargazer')
ipak(libs)

# import OECD IOTS and select which countries to include in analysis
ccodesOECD <- list.dirs(paste0(datadir, "iots/"), full.names=FALSE)
ccodesOECD <- ccodesOECD[nchar(ccodesOECD) > 0]

### GROSS OUTPUT CALCULATIONS ###

wiotL <- list()

tick <- 1
for (i in seq(startY, endY)) {
  year <- i
  wiotpath <- paste0(datadir, 'wiot/', year, '.csv')
  wiotY <- read_csv(wiotpath)
  wiotL[[tick]] <- wiotY
  tick <- tick + 1
}

wiot <- bind_rows(wiotL)

ccodes <- unique(wiot$col_country)
aggs <- setdiff(unique(wiot$row_country), ccodes)

# aggregate European Union (CHE is Switzerland, HRV is Croatia)
if (EUD==FALSE) {
  wiot$col_country <- mapEU(wiot$col_country, wiot$year)
  wiot$row_country <- mapEU(wiot$row_country, wiot$year)
}

# drop HRV CHE due to limited trade observations, Croatia doesn't join EU until 2013, TWN difficult to map to COMTRADE
# Also drop Malta due to inconsistencies between trade and national accounts data
ccodesWIOT <- setdiff(wiot$col_country, c("RoW", "TWN", "HRV", "CHE", "MLT"))
if (EUD==FALSE) {
  ccodesWIOT <- setdiff(ccodesWIOT, EU27)
}

if (TPSP==FALSE) {
  wiot$col_country <- ifelse(wiot$col_country %in% ccodesWIOT, wiot$col_country, "ROW")
  wiot$row_country <- ifelse(wiot$row_country %in% c(ccodesWIOT, aggs), wiot$row_country, "ROW")  # leave aggregates, turn everything else into ROW
} else {
  wiot$col_country <- ifelse(wiot$col_country %in% ccodesTPSP, wiot$col_country, "ROW")
  wiot$row_country <- ifelse(wiot$row_country %in% c(ccodesTPSP, aggs), wiot$row_country, "ROW")
}

# combine Belgium and Luxemborg to match trade data
wiot$col_country <- ifelse(wiot$col_country == "LUX", "BEL", wiot$col_country)
wiot$row_country <- ifelse(wiot$row_country == "LUX", "BEL", wiot$row_country)

# other country groupings (wiot)
if (BNL==TRUE) {
  wiot$col_country <- ifelse(wiot$col_country %in% BNLccodes, "BNL", wiot$col_country)
  wiot$row_country <- ifelse(wiot$row_country %in% BNLccodes, "BNL", wiot$row_country)
}
if (ELL==TRUE) {
  wiot$col_country <- ifelse(wiot$col_country %in% ELLccodes, "ELL", wiot$col_country)
  wiot$row_country <- ifelse(wiot$row_country %in% ELLccodes, "ELL", wiot$row_country)
}

# calculate GDP
gdp <- wiot %>% group_by(col_country, year) %>% filter(row_country=="VA") %>%
  summarise(gdp=sum(value)) %>% ungroup()
colnames(gdp) <- c("iso3", "year", "gdp")
# gdp %>% filter(year==2011)

# drop aggregates
wiotCountries <- wiot$col_country %>% unique()
wiotC <- wiot %>% filter(row_country %in% wiotCountries)
# wiotC$col_country %>% unique()
# wiotC$row_country %>% unique()

# calculate gross output (colSums, collapse rows)
go <- wiotC %>% group_by(row_country, year) %>% # %>% filter(row_country=="GO") %>%
  summarise(go=sum(value)) %>% ungroup()
colnames(go) <- c("iso3", "year", "go")

# calculate gross consumption (rowSums, collapse columns)
gc <- wiotC %>% group_by(col_country, year) %>% # %>% filter(row_country=="TOT") %>%
  summarise(gc=sum(value)) %>% ungroup()
colnames(gc) <- c("iso3", "year", "gc")

# test <- left_join(go, gc) %>% filter(year==2011)
# test$deficit <- test$gc - test$go
# test %>% print(n=50)
# sum(test$deficit)

if (TPSP==FALSE) {
  drop <- ccodesDrop  # all OECD version
  include <- setdiff(ccodesOECD, drop)
} else {
  include <- intersect(ccodesOECD, ccodesTPSP)
}


for (i in seq(startY, endY)) {
  for (j in include) {
    
    iotpath <- paste0(datadir, "iots/", j, "/", i, ".csv")
    
    iot <- read_csv(iotpath)
    
    iotttl <- iot %>% filter(ROW == 'TTL_INT_FNL')  # row includes consumer expenditure and impexp balance
    # iotttl %>% print(n=100)
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
gdpOECD <- gdp %>% filter(iso3 %in% include) %>% group_by(year) %>%
  summarise(gdpOECD = sum(gdp))
gcOECD <- gc %>% filter(iso3 %in% include) %>% group_by(year) %>%
  summarise(gcOECD = sum(gc))
goOECD <- go %>% filter(iso3 %in% include) %>% group_by(year) %>%
  summarise(goOECD = sum(go))

gdp <- left_join(gdp, gdpOECD)
gdp$gdpOECD <- ifelse(is.na(gdp$gdpOECD), 0, gdp$gdpOECD)
gdp$gdp <- ifelse(gdp$iso3=="ROW", gdp$gdp - gdp$gdpOECD, gdp$gdp)
gdp <- gdp %>% select(-one_of(c("gdpOECD")))
# gdp %>% filter(year==2011) %>% print(n=50)

gc <- left_join(gc, gcOECD)
gc$gcOECD <- ifelse(is.na(gc$gcOECD), 0, gc$gcOECD)
gc$gc <- ifelse(gc$iso3=="ROW", gc$gc - gc$gcOECD, gc$gc)
gc <- gc %>% select(-one_of(c("gcOECD")))

go <- left_join(go, goOECD)
go$goOECD <- ifelse(is.na(go$goOECD), 0, go$goOECD)
go$go <- ifelse(go$iso3=="ROW", go$go - go$goOECD, go$go)
go <- go %>% select(-one_of(c("goOECD")))

# other country groupings (OECD)
if (MYSG==TRUE) {
  gc$iso3 <- ifelse(gc$iso3 %in% MYSGccodes, "MYSG", gc$iso3)
  go$iso3 <- ifelse(go$iso3 %in% MYSGccodes, "MYSG", go$iso3)
  gdp$iso3 <- ifelse(gdp$iso3 %in% MYSGccodes, "MYSG", gdp$iso3)
}
# gdp %>% filter(year==2011) %>% print(n=100)

# re-aggregate
gdp <- gdp %>% group_by(iso3, year) %>%
  summarise(gdp=sum(gdp)) %>% ungroup()
colnames(gdp) <- c("iso3", "year", "gdp")
# gdp %>% filter(year==2011) %>% print(n=100)

# calculate gross output
go <- go %>% group_by(iso3, year)%>%
  summarise(go=sum(go)) %>% ungroup()
colnames(go) <- c("iso3", "year", "go")
# go %>% filter(year==2011) %>% print(n=100)

# calculate gross consumption
gc <- gc %>% group_by(iso3, year) %>%
  summarise(gc=sum(gc)) %>% ungroup()
colnames(gc) <- c("iso3", "year", "gc")
# gc %>% filter(year==2011) %>% print(n=100)

# calculate trade deficits
goc <- left_join(go, gc)
goc$deficit <- goc$gc - goc$go
deficit <- goc %>% select(iso3, year, deficit)
# deficit %>% filter(year==2011) %>% print(n=100) # check OECD entries
# sum(goc$deficit)  # check market clearing with deficits

# calculate consumer expenditure
gdp <- left_join(gdp, deficit)
gdp$exp <- gdp$gdp + gdp$deficit

ccodes <- gdp$iso3 %>% unique()

# write to clean dir
if (EUD==FALSE) {
  if (TPSP==FALSE) {
    mkdir(cleandir)
    write_csv(ccodes %>% as.data.frame(), paste0(cleandir, "ccodes.csv"))
    write_csv(gc, paste0(cleandir, "gc.csv"))
    write_csv(go, paste0(cleandir, "go.csv"))
    write_csv(gdp, paste0(cleandir, "gdp.csv"))
  } else {
    mkdir(cleandirTPSP)
    write_csv(ccodes %>% as.data.frame(), paste0(cleandirTPSP, "ccodes.csv"))
    write_csv(gc, paste0(cleandirTPSP, "gc.csv"))
    write_csv(go, paste0(cleandirTPSP, "go.csv"))
    write_csv(gdp, paste0(cleandirTPSP, "gdp.csv"))
  }
} else {
  mkdir(cleandirEU)
  write_csv(ccodes %>% as.data.frame(), paste0(cleandirEU, "ccodes.csv"))
  write_csv(gc, paste0(cleandirEU, "gc.csv"))
  write_csv(go, paste0(cleandirEU, "go.csv"))
  write_csv(gdp, paste0(cleandirEU, "gdp.csv"))
}

print("-----")
print("Concluding 01_accounts.R")
print("-----")
