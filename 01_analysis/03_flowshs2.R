### TODO ###

# - filter extreme trade cost observations?

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

### SETUP ###

source("params.R")

libs <- c('tidyverse', 'R.utils', 'countrycode', "readxl", "gdata", "stringr")
ipak(libs)

if (EUD==FALSE) {
  if (TPSP==FALSE) {
    ccodes <- read_csv(paste0(cleandir, "ccodes.csv")) %>% pull(.)
  }
  else {
    ccodes <- read_csv(paste0(cleandirTPSP, "ccodes.csv")) %>% pull(.)
  }
} else {
  ccodes <- read_csv(paste0(cleandirEU, "ccodes.csv")) %>% pull(.)
}

# modes directory
mdir <- paste0(datadir, "modes/")

### DATA ###

flowshs2 <- read_csv(paste0(cleandir, "flowshs2all.csv"))

### OBSERVED CIF/FOB RATIOS ###

### United States

uscodespath <- paste0(mdir, "us/", "codes.csv")
uscodes <- read_csv(uscodespath) %>% select(code, iso2)

fcodes <- read_csv(paste0(datadir, "flows/codes.csv")) %>% select(iso3, iso2)
fcodes <- fcodes %>% add_row(iso2="TW", iso3="TWN")  # Add Taiwan

usL <- list()
cols <- c("scommodity", "cty_code", "year", "con_val_yr", "con_cha_yr", "air_val_yr", "air_cha_yr", "ves_val_yr", "ves_cha_yr")

tick <- 1
for (i in seq(startY, endY)) {
  year <- i
  uspath <- paste0(mdir, "us/", year, ".csv")
  # specify col types as double to kill integer parsing failures
  usmodes <- read_csv(uspath, col_types = cols(scommodity=col_character(), ves_wgt_yr=col_double(), ves_val_yr=col_double(), gen_qy2_yr=col_double(), con_qy2_yr=col_double(), cnt_val_yr=col_double(), cal_dut_yr=col_double(), cards_yr=col_double()))
  # print("scommodity" %in% colnames(usmodes))
  usL[[tick]] <- usmodes %>% select(one_of(cols))
  tick <- tick + 1
}

usmodes <- bind_rows(usL)

usmodes <- left_join(usmodes, uscodes, by=c("cty_code"="code"))
usmodes <- left_join(usmodes, fcodes)

usmodes$hs2 <- substring(usmodes$scommodity, 1, 2)

# data for freight, map straight to EU/ROW categories
usmodesF <- usmodes

# EU aggregation
if(EUD==FALSE) {
  usmodesF$iso3 <- mapEU(usmodesF$iso3, usmodesF$year)
}

# other aggregations
if (BNL==TRUE) {
  usmodesF$iso3 <- ifelse(usmodesF$iso3 %in% BNLccodes, "BNL", usmodesF$iso3)
}
if (ELL==TRUE) {
  usmodesF$iso3 <- ifelse(usmodesF$iso3 %in% ELLccodes, "ELL", usmodesF$iso3)
}
if (MYSG==TRUE) {
  usmodesF$iso3 <- ifelse(usmodesF$iso3 %in% MYSGccodes, "MYSG", usmodesF$iso3)
}

usmodesF$iso3 <- ifelse(usmodesF$iso3 %in% ccodes, usmodesF$iso3, "ROW")

# select shipments that clear customs, then aggregate
usCosts <- usmodesF %>% filter(con_val_yr > 0) %>% group_by(year, iso3) %>%
  summarise(val=sum(as.numeric(con_val_yr)),
            cha=sum(as.numeric(con_cha_yr)))

usCosts$adv <- usCosts$cha / usCosts$val
# weighted.mean(usCosts$adv, usCosts$val)  # average ad valorem costs to export to US

usCosts$j_iso3 <- "USA"
colnames(usCosts)[colnames(usCosts)=="iso3"] <- "i_iso3"
usCosts <- usCosts %>% select(year, i_iso3, j_iso3, adv)

### Australia

aus <- read_xlsx(paste0(proprietaryDataPath, "abs.xlsx"), sheet="Table 1 ", skip=6)
colnames(aus) <- c("year", "hsCode", "hsLabel", "exporter", "mode", "cif", "fob")

# mapping to ISO codes
saccC <- read.xls(paste0(proprietaryDataPath, "sacc.xls"), sheet="Table 6", skip=5) %>% as_tibble() %>% select(Country.Description, Alpha.3)
colnames(saccC) <- c("exporter", "iso3")
saccC$exporter <- as.character(saccC$exporter)
saccC$exporter <- str_trim(saccC$exporter, "right") 

# filter out "confidential items," which seem to be about balancing accounts
aus <- aus %>% filter(hsCode != 99)
# aus$iso3 <- as.character(aus$iso3)

# map country codes
# China
aus$exporter <- ifelse(aus$exporter=="China (excluding SARs and Taiwan)", "China", aus$exporter)
# Koreas
aus$exporter <- ifelse(aus$exporter=="Korea, Republic of", "Korea", aus$exporter)
aus$exporter <- ifelse(aus$exporter=="Korea, Dem People's Rep", "North Korea", aus$exporter)
# Luxembourg - Belgium
aus$exporter <- ifelse(aus$exporter=="Belgium-Luxembourg", "Belgium", aus$exporter)
# Central African Republic
aus$exporter <- ifelse(aus$exporter=="Central African Repub", "Central African Republic", aus$exporter)
# Ivory Coast
aus$exporter <- ifelse(aus$exporter=="Cote d'Ivoire", "Ivory Coast", aus$exporter)
# Myanmar
aus$exporter <- ifelse(aus$exporter=="Myanmar, Republic of", "Myanmar", aus$exporter)
# Kyrgyzstan
aus$exporter <- ifelse(aus$exporter=="Kyrgyztan", "Kyrgyzstan", aus$exporter)
# Congo
aus$exporter <- ifelse(aus$exporter=="Dem Rep of Congo, Zaire", "Congo, Democratic Republic of", aus$exporter)

# join iso codes
aus <- left_join(aus, saccC)

# filter unmatched observations (~2.5%)
aus <- aus %>% filter(!is.na(iso3))

# year to integer
aus$year <- strsplit(aus$year, " ") %>% sapply(`[`, 3) %>% as.integer()

# filter time window
aus <- aus %>% filter(year %in% seq(startY, endY))

# hs to character
aus$hsCode <- as.character(aus$hsCode)
aus$hsCode <- ifelse(nchar(aus$hsCode)==1, paste0("0", aus$hsCode), aus$hsCode)

# iso to character
aus$iso3 <- as.character(aus$iso3)

# filter internal observations
aus <- aus %>% filter(!(iso3=="AUS"))

# drop negative freight costss
aus <- aus %>% filter(cif >= fob)

# data for freight.csv
ausF <- aus

if(EUD==FALSE) {
  ausF$iso3 <- mapEU(ausF$iso3, ausF$year)
}

# other aggregations
if (BNL==TRUE) {
  ausF$iso3 <- ifelse(ausF$iso3 %in% BNLccodes, "BNL", ausF$iso3)
}
if (ELL==TRUE) {
  ausF$iso3 <- ifelse(ausF$iso3 %in% ELLccodes, "ELL", ausF$iso3)
}
if (MYSG==TRUE) {
  ausF$iso3 <- ifelse(ausF$iso3 %in% MYSGccodes, "MYSG", ausF$iso3)
}

ausF$iso3 <- ifelse(ausF$iso3 %in% ccodes, ausF$iso3, "ROW")
# ausF %>% pull(iso3) %>% unique()

ausCosts <- ausF %>% group_by(year, iso3) %>%
  summarise(cif=sum(cif),
            fob=sum(fob))

ausCosts$adv <- ausCosts$cif / ausCosts$fob - 1

ausCosts$j_iso3 <- "AUS"
colnames(ausCosts)[colnames(ausCosts)=="iso3"] <- "i_iso3"
ausCosts <- ausCosts %>% select(year, i_iso3, j_iso3, adv)
# summary(ausCosts)
# ausCosts %>% filter(adv > 2)

### New Zealand

nzbase <- paste0(datadir, "nz/")

nzL <- list()
tick <- 1
for (i in seq(startY, endY)) {
  year <- i
  nzpath <- paste0(nzbase, year, ".csv")
  nzY <- read_csv(nzpath)
  nzL[[tick]] <- nzY
  tick <- tick + 1
}

nz <- bind_rows(nzL)
nz$cif <- as.numeric(nz$cif)
nz$vfd <- as.numeric(nz$vfd)

nz$i_iso3 <- countrycode(nz$cname, "country.name", "iso3c")
nz <- nz %>% filter(!is.na(i_iso3))

if (EUD==FALSE) {
  nz$i_iso3 <- mapEU(nz$i_iso3, nz$year)
}

# other aggregations
if (BNL==TRUE) {
  nz$i_iso3 <- ifelse(nz$i_iso3 %in% BNLccodes, "BNL", nz$i_iso3)
}
if (ELL==TRUE) {
  nz$i_iso3 <- ifelse(nz$i_iso3 %in% ELLccodes, "ELL", nz$i_iso3)
}
if (MYSG==TRUE) {
  nz$i_iso3 <- ifelse(nz$i_iso3 %in% MYSGccodes, "MYSG", nz$i_iso3)
}

nz$i_iso3 <- ifelse(nz$i_iso3 %in% ccodes, nz$i_iso3, "ROW")
nz <- nz %>% filter(i_iso3!="NZL")  # filter NZ own trade observations
nz <- nz %>% filter(!(is.na(cif) | is.na(vfd)))  # filter unobserved costs

nzCosts <- nz %>% group_by(year, i_iso3) %>%
  summarise(cif=sum(cif),
            vfd=sum(vfd))

nzCosts <- nzCosts %>% filter(vfd > 0)
nzCosts$adv <- nzCosts$cif / nzCosts$vfd - 1

nzCosts$j_iso3 <- "NZL"
nzCosts <- nzCosts %>% select(year, i_iso3, j_iso3, adv)


### Chile

chlbase <- paste0(datadir, "chl/")

chlL <- list()
tick <- 1
for (i in seq(startY, endY)) {
  year <- i
  chlpath <- paste0(chlbase, year, ".csv")
  if (file.exists(chlpath)) {
    chlY <- read_csv(chlpath)
    chlY$year <- year
    chlL[[tick]] <- chlY
    tick <- tick + 1
  }
}

chl <- bind_rows(chlL)
chl$i_iso3 <- countrycode(chl$Importer, "country.name", "iso3c")

if (EUD==FALSE) {
  chl$i_iso3 <- mapEU(chl$i_iso3, chl$year)
}

# other aggregations
if (BNL==TRUE) {
  chl$i_iso3 <- ifelse(chl$i_iso3 %in% BNLccodes, "BNL", chl$i_iso3)
}
if (ELL==TRUE) {
  chl$i_iso3 <- ifelse(chl$i_iso3 %in% ELLccodes, "ELL", chl$i_iso3)
}
if (MYSG==TRUE) {
  chl$i_iso3 <- ifelse(chl$i_iso3 %in% MYSGccodes, "MYSG", chl$i_iso3)
}

chl$i_iso3 <- ifelse(chl$i_iso3 %in% ccodes, chl$i_iso3, "ROW")

chlCosts <- chl %>% group_by(year, i_iso3) %>%
  summarise(fob=sum(fob),
            cif=sum(cif))

chlCosts$adv <- chlCosts$cif / chlCosts$fob - 1
chlCosts$j_iso3 <- "CHL"
chlCosts <- chlCosts %>% select(year, i_iso3, j_iso3, adv)

### Export

freightC <- list(usCosts, ausCosts, nzCosts, chlCosts)

freight <- bind_rows(freightC)
freight$j_iso3 <- ifelse(freight$j_iso3 %in% ccodes, freight$j_iso3, "ROW")
freight <- freight %>% filter(!(i_iso3=="ROW" & j_iso3=="ROW")) # filter ROW internal trade

if (EUD==FALSE) {
  if (TPSP==FALSE) {
    write_csv(freight, paste0(cleandir, "freight.csv"))
  } else {
    write_csv(freight, paste0(cleandirTPSP, "freight.csv"))
  }
} else {
  write_csv(freight, paste0(cleandirEU, "freight.csv"))
}

### TRANSPORT MODES ###

### United States ###

# select shipments that clear customs, then aggregate
usmodeshs2 <- usmodes %>% filter(con_val_yr > 0) %>% group_by(year, hs2, iso3) %>% 
  summarise(val=sum(as.numeric(con_val_yr)),
            cha=sum(as.numeric(con_cha_yr)),
            airval=sum(as.numeric(air_val_yr)),
            aircha=sum(as.numeric(air_cha_yr)),
            seaval=sum(as.numeric(ves_val_yr)),
            seacha=sum(as.numeric(ves_cha_yr)))

# usmodeshs2 %>% arrange(desc(val))

# CHECK LUXEMBOURG
# usmodeshs2$iso3 %>% unique() %>% sort()
# not listed, either zero flows or listed with Belgium

usmodeshs2$landval <- usmodeshs2$val - usmodeshs2$airval - usmodeshs2$seaval
usmodeshs2$landcha <- usmodeshs2$cha - usmodeshs2$aircha - usmodeshs2$seacha
usmodeshs2$avcair <- usmodeshs2$aircha / usmodeshs2$airval
usmodeshs2$avcsea <- usmodeshs2$seacha / usmodeshs2$seaval
usmodeshs2$avcland <- usmodeshs2$landcha / usmodeshs2$landval

usmodeshs2$airshare <- usmodeshs2$airval / usmodeshs2$val
usmodeshs2$seashare <- usmodeshs2$seaval / usmodeshs2$val
usmodeshs2$landshare <- usmodeshs2$landval / usmodeshs2$val
usmodeshs2$othershare <- 0

colnames(usmodeshs2)[3] <- "i_iso3"
usmodeshs2$j_iso3 <- "USA"
usmodeshs2 <- usmodeshs2 %>% select(year, i_iso3, j_iso3, hs2, airshare, seashare, landshare, othershare, avcair, avcsea, avcland)
# summary(usmodeshs2)

# usmodeshs2 %>% filter(i_iso3 == "SGP" & is.na(seashare))

# append to flows
flowshs2 <- left_join(flowshs2, usmodeshs2, by=c("year", "hs2", "i_iso3", "j_iso3"))
# flowshs2 %>% filter(!is.na(othershare)) %>% pull(j_iso3) %>% unique()

rm(usmodes, usmodeshs2)

# reconcile sea costs, use us customs data over OECD
# flowshs2$avcsea <- ifelse(is.na(flowshs2$avcsea.y), flowshs2$avcsea.x, flowshs2$avcsea.y)
# flowshs2 %>% filter(j_iso3 == "USA") %>% select(avcsea.x, avcsea.y, avcsea, everything())
# flowshs2 <- flowshs2 %>% select(-one_of(c("avcsea.x", "avcsea.y")))

# flowshs2 %>% filter(i_iso3 == "FRA", j_iso3=="USA")

### Australia

ausModesFob <- aus %>% group_by(year, iso3, hsCode, mode) %>%
  summarise(fob=sum(fob)) %>% spread(mode, fob)
ausModesFob <- ausModesFob %>% replace(is.na(.), 0)

ausModesCif <- aus %>% group_by(year, iso3, hsCode, mode) %>%
  summarise(cif=sum(cif)) %>% spread(mode, cif)
ausModesCif <- ausModesCif %>% replace(is.na(.), 0)

ausModes <- ausModesFob %>% select(year, iso3, hsCode)
ausModes$avcair <- ausModesCif$AIR / ausModesFob$AIR - 1
ausModes$avcsea <- ausModesCif$SEA / ausModesFob$SEA - 1

ausModesFob <- ausModesFob %>% replace(is.na(.), 0)
ausModesFob$totalFob <- ausModesFob$AIR + ausModesFob$POST + ausModesFob$SEA

ausModesFob$airshare <- ausModesFob$AIR / ausModesFob$totalFob
ausModesFob$seashare <- ausModesFob$SEA / ausModesFob$totalFob
ausModesFob$othershare <- ausModesFob$POST / ausModesFob$totalFob

ausModesFob <- ausModesFob %>% select(year, iso3, hsCode, airshare, seashare, othershare)

ausModes <- left_join(ausModes, ausModesFob)

colnames(ausModes)[colnames(ausModes)=="iso3"] <- "i_iso3"
colnames(ausModes)[colnames(ausModes)=="hsCode"] <- "hs2"
ausModes$j_iso3 <- "AUS"

flowshs2 <- left_join(flowshs2, ausModes, by=c("year", "hs2", "i_iso3", "j_iso3"))

flowshs2$airshare <- ifelse(is.na(flowshs2$airshare.x), flowshs2$airshare.y, flowshs2$airshare.x)
flowshs2$seashare <- ifelse(is.na(flowshs2$seashare.x), flowshs2$seashare.y, flowshs2$seashare.x)
flowshs2$othershare <- ifelse(is.na(flowshs2$othershare.x), flowshs2$othershare.y, flowshs2$othershare.x)

flowshs2$avcair <- ifelse(is.na(flowshs2$avcair.x), flowshs2$avcair.y, flowshs2$avcair.x)
flowshs2$avcsea <- ifelse(is.na(flowshs2$avcsea.x), flowshs2$avcsea.y, flowshs2$avcsea.x)

flowshs2 <- flowshs2 %>% select(-one_of(c("airshare.x", "airshare.y", "seashare.x", "seashare.y", "othershare.x", "othershare.y",
                                          "avcair.x", "avcair.y", "avcsea.x", "avcsea.y")))
# flowshs2 %>% filter(j_iso3=="AUS") %>% select(airshare, seashare, avcair, avcsea, everything())

### Japan

# Note: `Sea` code switches from 2 to 5 in 2009

jpndir <- paste0(mdir, "jpn/")
jpncodes <- read_csv(paste0(jpndir, "codes.csv"))
jpncodes$iso3 <- jpncodes$Country %>% countrycode("country.name", "iso3c")

jpnL <- list()

tick <- 1
for (i in seq(startY, endY)) {
  year <- i
  jpnydir <- paste0(jpndir, year, "/")
  jpnfiles <- list.files(jpnydir)
  
  jpndfs <- list()
  
  subtick <- 1
  for (i in jpnfiles) {
    jpndfs[[subtick]] <- read_csv(paste0(jpnydir, i), col_types = list(`Quantity1-Year`=col_double(), `Quantity2-Year`=col_double()))
    subtick <- subtick + 1
  }
  
  test <- do.call("rbind", jpndfs)
  colnames(test)
  jpnL[[tick]] <- do.call("rbind", jpndfs)
  
  tick <- tick + 1 
}

jpnmodes <- bind_rows(jpnL)
colnames(jpnmodes)[2] <- "year"
jpnmodes$`Air or Sea` <- ifelse(jpnmodes$`Air or Sea` == 5, 2, jpnmodes$`Air or Sea`)
# summary(jpnmodes)
# jpnmodes %>% filter(year==2003) %>% summary()


jpncodes <- jpncodes %>% select(Code, iso3)
jpnmodes <- left_join(jpnmodes, jpncodes, by=c("Country"="Code"))
jpnmodes$`Air or Sea` <- as.factor(jpnmodes$`Air or Sea`)
jpnmodes$hs2 <- substring(jpnmodes$HS, 2, 3)
# unique(jpnmodes$hs2)

# Relabel LUX to BEL
jpnmodes$iso3 <- ifelse(jpnmodes$iso3=="LUX", "BEL", jpnmodes$iso3)
# jpnmodes$iso3 %>% unique() %>% sort()

# aggregate EU/ROW
# jpnmodes$iso3 <- ifelse(jpnmodes$iso3 %in% EU, "EU", jpnmodes$iso3)
# jpnmodes$iso3 <- ifelse(jpnmodes$iso3 %in% ccodes, jpnmodes$iso3, "ROW")

jpnair <- jpnmodes %>% group_by(`Air or Sea`, year, hs2, iso3) %>%
  summarise(val=sum(as.numeric(`Value-Year`))) %>% filter(`Air or Sea` == 1) %>% ungroup() %>% select(year, hs2, iso3, val)
# summary(jpnair)
colnames(jpnair)[4] <- "air"

jpnsea <- jpnmodes %>% group_by(`Air or Sea`, year, hs2, iso3) %>%
  summarise(val=sum(as.numeric(`Value-Year`))) %>% filter(`Air or Sea` == 2) %>% ungroup() %>% select(year, hs2, iso3, val)
# summary(jpnsea)  # no values after 2008
colnames(jpnsea)[4] <- "sea"

jpntot <- jpnmodes %>% group_by(year, hs2, iso3) %>%
  summarise(val=sum(as.numeric(`Value-Year`)))

jpntot <- left_join(jpntot, jpnair, by=c("year", "hs2", "iso3"))
jpntot <- left_join(jpntot, jpnsea, by=c("year", "hs2", "iso3"))

jpntot$airshare <- ifelse(is.na(jpntot$air / jpntot$val), 0, jpntot$air / jpntot$val)
jpntot$seashare <- ifelse(is.na(jpntot$sea / jpntot$val), 0, jpntot$sea / jpntot$val)
jpntot$landshare <- 0
jpntot$othershare <- 0

jpntot <- jpntot %>% select(year, hs2, iso3, airshare, seashare, landshare, othershare)
colnames(jpntot)[3] <- "i_iso3"
jpntot$j_iso3 <- "JPN"

flowshs2 <- left_join(flowshs2, jpntot, by=c("year", "hs2", "i_iso3", "j_iso3"))
flowshs2$airshare <- ifelse(is.na(flowshs2$airshare.x), flowshs2$airshare.y, flowshs2$airshare.x)
flowshs2$seashare <- ifelse(is.na(flowshs2$seashare.x), flowshs2$seashare.y, flowshs2$seashare.x)
flowshs2$landshare <- ifelse(is.na(flowshs2$landshare.x), flowshs2$landshare.y, flowshs2$landshare.x)
flowshs2$othershare <- ifelse(is.na(flowshs2$othershare.x), flowshs2$othershare.y, flowshs2$othershare.x)
flowshs2 <- flowshs2 %>% select(-one_of(c("airshare.x", "airshare.y", "seashare.x", "seashare.y", "landshare.x", "landshare.y", "othershare.x", "othershare.y")))
# flowshs2 %>% filter(j_iso3 == "USA") %>% arrange(desc(val))
# flowshs2 %>% filter(j_iso3=="JPN") %>% select(airshare, seashare) %>% summary()

# flowshs2 %>% filter(!is.na(othershare)) %>% pull(j_iso3) %>% unique()

rm(jpnmodes)

### European Union

euL <- list()

tick <- 1
for (i in seq(startY, endY)) {
  path <- paste0(mdir, "eu/", i, ".csv")
  if (file.exists(path)) {
    eumodes <- read_csv(path, col_types = list(INDICATOR_VALUE = col_double()))
    euL[[tick]] <- eumodes
    tick <- tick + 1
  }
}

eumodes <- bind_rows(euL)
eumodes <- left_join(eumodes, fcodes, by=c("PARTNER"="iso2"))
colnames(eumodes)[colnames(eumodes)=="iso3"] <- "i_iso3"
eumodes <- left_join(eumodes, fcodes, by=c("REPORTER"="iso2"))
colnames(eumodes)[colnames(eumodes)=="iso3"] <- "j_iso3"

# group modes
land <- c("Road", "Fixed Mechanism", "Rail")
air <- c("Air")
sea <- c("Sea", "Inland Waterway")
eumodes$mode <- ifelse(eumodes$TRANSPORT_MODE_LAB %in% land, "land", 
                       ifelse(eumodes$TRANSPORT_MODE_LAB %in% air, "air", 
                              ifelse(eumodes$TRANSPORT_MODE_LAB %in% sea, "sea", "other")))

eumodes <- eumodes %>% select(year, i_iso3, j_iso3, PRODUCT, mode, INDICATOR_VALUE)

colnames(eumodes) <- c("year", "i_iso3", "j_iso3", "hs2", "mode", "val")
# unique(eumodes$hs2)

# check Luxembourg, doesn't appear in data
# eumodes$j_iso3 %>% unique() %>% sort()
# eumodes$j_iso3 <- ifelse(eumodes$j_iso3 == "LUX", "BEL", eumodes$j_iso3)

# aggregate ROW
# eumodes$i_iso3 <- ifelse(eumodes$i_iso3 %in% ccodes, eumodes$i_iso3, "ROW")

eutot <- eumodes %>% group_by(year, i_iso3, j_iso3, hs2) %>%
  summarise(tot=sum(val))

eubymode <- eumodes %>% group_by(year, i_iso3, j_iso3, hs2, mode) %>%
  summarise(val=sum(val))

eumodeshares <- left_join(eubymode, eutot, by=c("year", "i_iso3", "j_iso3", "hs2"))
eumodeshares <- eumodeshares %>% spread(mode, val)
# eumodeshares$j_iso3 %>% unique() %>% sort()

eumodeshares$airshare <- eumodeshares$air / eumodeshares$tot
eumodeshares$seashare <- eumodeshares$sea / eumodeshares$tot
eumodeshares$landshare <- eumodeshares$land / eumodeshares$tot
eumodeshares$othershare <- eumodeshares$other / eumodeshares$tot

eumodeshares <- eumodeshares %>% select(year, i_iso3, j_iso3, hs2, airshare, seashare, landshare, othershare)
# eumodeshares %>% filter(i_iso3=="ARG", year==2011)

# eumodeshares[is.na(eumodeshares)] <- 0 # if share not computed for a specific mode then others sum to 1

flowshs2 <- left_join(flowshs2, eumodeshares, by=c("year", "hs2", "i_iso3", "j_iso3"))
flowshs2$airshare <- ifelse(is.na(flowshs2$airshare.x), flowshs2$airshare.y, flowshs2$airshare.x)
flowshs2$seashare <- ifelse(is.na(flowshs2$seashare.x), flowshs2$seashare.y, flowshs2$seashare.x)
flowshs2$landshare <- ifelse(is.na(flowshs2$landshare.x), flowshs2$landshare.y, flowshs2$landshare.x)
flowshs2$othershare <- ifelse(is.na(flowshs2$othershare.x), flowshs2$othershare.y, flowshs2$othershare.x)
flowshs2 <- flowshs2 %>% select(-one_of(c("airshare.x", "airshare.y", "seashare.x", "seashare.y", "landshare.x", "landshare.y", "othershare.x", "othershare.y")))

# flowshs2 %>% filter(!is.na(othershare)) %>% pull(j_iso3) %>% unique()
# flowshs2 %>% summary()

rm(eumodes)

# flowshs2 %>% filter(j_iso3 == "FRA", year==2000) %>% select(seashare, landshare, othershare, everything())
# flowshs2 %>% filter(j_iso3 == "EU") %>% arrange(desc(val))
# flowshs2 %>% group_by(i_iso3, j_iso3) %>% summarise(val=sum(val)) %>% 
#   filter(j_iso3 == "EU") %>% arrange(desc(val))

### Brazil

braccodes <- read_csv(paste0(mdir, "bra/", "ccodes.csv"))
bratcodes <- read_csv(paste0(mdir, "bra/", "tcodes.csv"))
brancmcodes <- read_csv(paste0(mdir, "bra/", "ncmcodes.csv"), col_types=list(CO_ISIC4=col_character(), CO_CUCI_ITEM=col_character(), CO_NCM=col_character(), CO_SH6=col_character()))

braL <- list()

tick <- 1
for (i in seq(startY, endY)) {
  path <- paste0(mdir, "bra/", i, ".csv")
  if (file.exists(path)) {
    bramodes <- read_csv(path)
    braL[[tick]] <- bramodes
    tick <- tick + 1
  }
}

bramodes <- bind_rows(braL)

bramodes <- left_join(bramodes, braccodes)
bramodes <- left_join(bramodes, bratcodes)
bramodes <- left_join(bramodes, brancmcodes, by="CO_NCM")

# group modes
sea <- c("MARITIMA", "FLUVIAL")  # fluvial = river, lacustre = lake
air <- c("AEREA")
land <- c("FERROVIARIA", "RODOVIARIA")  # rail, road
bramodes$mode <- ifelse(bramodes$NO_VIA %in% land, "land", 
                        ifelse(bramodes$NO_VIA %in% air, "air", 
                               ifelse(bramodes$NO_VIA %in% sea, "sea", "other")))

bramodes$hs2 <- ifelse(nchar(bramodes$CO_SH6) == 6, substring(bramodes$CO_SH6, 1, 2), paste0("0", substring(bramodes$CO_SH6, 1, 1)))
# unique(bramodes$hs2) %>% sort()
# sum(nchar(bramodes$CO_SH6) == 6, na.rm=T)
# length(!is.na(bramodes$CO_SH6))

bramodes <- bramodes %>% select(CO_ANO, CO_MES, hs2, CO_PAIS_ISOA3, mode, VL_FOB)
colnames(bramodes) <- c("year", "month", "hs2", "i_iso3", "mode", "val")

# aggregate EU/ROW
# bramodes$i_iso3 <- ifelse(bramodes$i_iso3 %in% EU, "EU", bramodes$i_iso3)
# bramodes$i_iso3 <- ifelse(bramodes$i_iso3 %in% ccodes, bramodes$i_iso3, "ROW")

bratot <- bramodes %>% group_by(year, i_iso3, hs2) %>%
  summarise(tot=sum(as.numeric(val)))
# bratot %>% arrange(desc(tot))

brabymode <- bramodes %>% group_by(year, i_iso3, hs2, mode) %>%
  summarise(val=sum(as.numeric(val)))

bramodeshares <- left_join(brabymode, bratot, by=c("year", "i_iso3", "hs2"))
bramodeshares <- bramodeshares %>% spread(mode, val)
# bramodeshares %>% arrange(desc(tot))
bramodeshares <- bramodeshares %>% filter(tot > 0)  # filter out zero trade observations

bramodeshares$airshare <- bramodeshares$air / bramodeshares$tot
bramodeshares$seashare <- bramodeshares$sea / bramodeshares$tot
bramodeshares$landshare <- bramodeshares$land / bramodeshares$tot
bramodeshares$othershare <- bramodeshares$other / bramodeshares$tot

bramodeshares <- bramodeshares %>% select(year, i_iso3, hs2, airshare, seashare, landshare, othershare)
bramodeshares$j_iso3 <- "BRA"

bramodeshares[is.na(bramodeshares)] <- 0 
# summary(bramodeshares)


flowshs2 <- left_join(flowshs2, bramodeshares, by=c("year", "hs2", "i_iso3", "j_iso3"))
flowshs2$airshare <- ifelse(is.na(flowshs2$airshare.x), flowshs2$airshare.y, flowshs2$airshare.x)
flowshs2$seashare <- ifelse(is.na(flowshs2$seashare.x), flowshs2$seashare.y, flowshs2$seashare.x)
flowshs2$landshare <- ifelse(is.na(flowshs2$landshare.x), flowshs2$landshare.y, flowshs2$landshare.x)
flowshs2$othershare <- ifelse(is.na(flowshs2$othershare.x), flowshs2$othershare.y, flowshs2$othershare.x)
flowshs2 <- flowshs2 %>% select(-one_of(c("airshare.x", "airshare.y", "seashare.x", "seashare.y", "landshare.x", "landshare.y", "othershare.x", "othershare.y")))
# flowshs2 %>% filter(j_iso3 == "USA")

# summary(flowshs2)

rm(bramodes)

### AGGREGATE EU ###

if(EUD==FALSE) {
  flowshs2$i_iso3 <- mapEU(flowshs2$i_iso3, flowshs2$year)
  flowshs2$j_iso3 <- mapEU(flowshs2$j_iso3, flowshs2$year)
}

# other aggregations
if (BNL==TRUE) {
  flowshs2$i_iso3 <- ifelse(flowshs2$i_iso3 %in% BNLccodes, "BNL", flowshs2$i_iso3)
  flowshs2$j_iso3 <- ifelse(flowshs2$j_iso3 %in% BNLccodes, "BNL", flowshs2$j_iso3)
}
if (ELL==TRUE) {
  flowshs2$i_iso3 <- ifelse(flowshs2$i_iso3 %in% ELLccodes, "ELL", flowshs2$i_iso3)
  flowshs2$j_iso3 <- ifelse(flowshs2$j_iso3 %in% ELLccodes, "ELL", flowshs2$j_iso3)
}
if (MYSG==TRUE) {
  flowshs2$i_iso3 <- ifelse(flowshs2$i_iso3 %in% MYSGccodes, "MYSG", flowshs2$i_iso3)
  flowshs2$j_iso3 <- ifelse(flowshs2$j_iso3 %in% MYSGccodes, "MYSG", flowshs2$j_iso3)
}

# drop internal EU flows
flowshs2 <- flowshs2 %>% filter(!(i_iso3 == "EU" & j_iso3 == "EU"))
# flowshs2$i_iso3 %>% unique() %>% sort()

# # append maritime transport costs
mtc <- read_csv(paste0(datadir, "mtc/mtc.csv"))
mtcadva <- mtc %>% filter(MEAS == "TR_ADVA")  # get only ad valorem data
mtccif <- mtc %>% filter(MEAS == "TR_COST")
mtcadva <- mtcadva %>% select(IMP, EXP, COMH0, Year, Value)
mtccif <- mtccif %>% select(IMP, EXP, COMH0, Year, Value)
colnames(mtcadva) <- c("j_iso3", "i_iso3", "hs2", "year", "adva")
colnames(mtccif) <- c("j_iso3", "i_iso3", "hs2", "year", "cif")

mtc <- left_join(mtcadva, mtccif)

# note: EU reporting seems to be for EU as a whole, presumably evolves over time?
mtc$j_iso3 <- ifelse(mtc$j_iso3 == "EU15", "EU", mtc$j_iso3)
mtc$i_iso3 <- ifelse(mtc$i_iso3 == "EU15", "EU", mtc$i_iso3)

# other aggregations
if (BNL==TRUE) {
  mtc$i_iso3 <- ifelse(mtc$i_iso3 %in% BNLccodes, "BNL", mtc$i_iso3)
  mtc$j_iso3 <- ifelse(mtc$j_iso3 %in% BNLccodes, "BNL", mtc$j_iso3)
}
if (ELL==TRUE) {
  mtc$i_iso3 <- ifelse(mtc$i_iso3 %in% ELLccodes, "ELL", mtc$i_iso3)
  mtc$j_iso3 <- ifelse(mtc$j_iso3 %in% ELLccodes, "ELL", mtc$j_iso3)
}
if (MYSG==TRUE) {
  mtc$i_iso3 <- ifelse(mtc$i_iso3 %in% MYSGccodes, "MYSG", mtc$i_iso3)
  mtc$j_iso3 <- ifelse(mtc$j_iso3 %in% MYSGccodes, "MYSG", mtc$j_iso3)
}

mtc$v <- mtc$cif / (1 + mtc$adva) # convert to fob value for weighting

# compute trade-weighted ad valorem cost
mtcagg <- mtc %>% group_by(j_iso3, i_iso3, hs2, year) %>%
  summarise(avcsea=weighted.mean(adva, v)) %>% ungroup()

# summary(mtcagg)
mtcagg1995 <- mtcagg %>% filter(year==1995)
mtcagg2007 <- mtcagg %>% filter(year==2007)
# mean(mtcagg1995$avcsea) - mean(mtcagg2007$avcsea)  # consistent with ACD data

rm(mtc)

flowshs2 <- left_join(flowshs2, mtcagg, by=c("year", "i_iso3", "j_iso3", "hs2"))

flowshs2$avcsea <- ifelse(is.na(flowshs2$avcsea.x), flowshs2$avcsea.y, flowshs2$avcsea.x)
flowshs2 <- flowshs2 %>% select(-one_of(c("avcsea.x", "avcsea.y")))

# remaining countries become ROW
flowshs2$i_iso3 <- ifelse(flowshs2$i_iso3 %in% ccodes, flowshs2$i_iso3, 'ROW')
flowshs2$j_iso3 <- ifelse(flowshs2$j_iso3 %in% ccodes, flowshs2$j_iso3, 'ROW')

# filter internal trade
flowshs2 <- flowshs2 %>% filter(!(i_iso3 == "ROW" & j_iso3 == "ROW"))
if (ELL==TRUE) {
  flowshs2 <- flowshs2 %>% filter(!(i_iso3 == "ELL" & j_iso3 == "ELL"))
}
if (BNL==TRUE) {
  flowshs2 <- flowshs2 %>% filter(!(i_iso3 == "BNL" & j_iso3 == "BNL"))
}
if (MYSG==TRUE) {
  flowshs2 <- flowshs2 %>% filter(!(i_iso3 == "MYSG" & j_iso3 == "MYSG"))
}

# summary(flowshs2)

# aggregate and export trade matrix
flowsAgg <- flowshs2 %>% group_by(year, i_iso3, j_iso3) %>%
  summarise(val=sum(as.numeric(val)))
flowsAgg$year <- flowsAgg$year %>% as.integer()

if(EUD==FALSE) {
  if (TPSP==FALSE) {
    write_csv(flowsAgg, paste0(cleandir, "flowsAgg.csv"))
  } else {
    write_csv(flowsAgg, paste0(cleandirTPSP, "flowsAgg.csv"))
  }
} else{
  write_csv(flowsAgg, paste0(cleandirEU, "flowsAgg.csv"))
}

# summarize EU and ROW share and cost data
flowshs2econ <- flowshs2 %>% group_by(year, hs2, i_iso3, j_iso3) %>%
  summarise(
    v=sum(val, na.rm=T),
    avcair=weighted.mean(avcair, val, na.rm=T),
    avcsea=weighted.mean(avcsea, val, na.rm=T),
    avcland=weighted.mean(avcland, val, na.rm=T),
    airshare=weighted.mean(airshare, val, na.rm=T),
    seashare=weighted.mean(seashare, val, na.rm=T),
    landshare=weighted.mean(landshare, val, na.rm=T),
    othershare=weighted.mean(othershare, val, na.rm=T)
  )

# summarize EU and ROW geographic data
flowshs2geo <- flowshs2 %>% group_by(i_iso3, j_iso3) %>%
  summarise(
    seadist=weighted.mean(seadistance, val, na.rm=T),
    adist=weighted.mean(distw, val, na.rm=T),
    contig=max(contig, na.rm=T),
    i_landlocked = min(i_landlocked, na.rm=T),
    j_landlocked = min(j_landlocked, na.rm=T)
  )

flowshs2export <- left_join(flowshs2econ, flowshs2geo)
colnames(flowshs2export)[colnames(flowshs2export) == "v"] <- "val"

# flowshs2export %>% filter(!is.na(avcsea)) %>% select(contig, everything())
# flowshs2export %>% filter(!is.na(seashare))
# flowshs2export %>% filter(is.na(j_landlocked))

### CLEAN MERGED DATA AND EXPORT ###

# replace NAs in shares with 0s if other shares defined
# test <- flowshs2 %>% select(airshare, seashare, landshare, othershare) %>% filter(!is.na(airshare)) %>% is.na()
# colSums(test)

# summary(flowshs2export)
flowshs2export$year <- flowshs2export$year %>% as.integer()  # weird things happen when years saved as double
# flowshs2export %>% filter(i_iso3==j_iso3)

if(EUD==FALSE) {
  if (TPSP==FALSE) {
    write_csv(flowshs2export, paste0(cleandir, "flowshs2.csv"))
  } else {
    write_csv(flowshs2export, paste0(cleandirTPSP, "flowshs2.csv"))
  }
} else{
  write_csv(flowshs2export, paste0(cleandirEU, "flowshs2.csv"))
}

# flowshs2export %>% filter(j_iso3=="IRL")

# flowshs2export %>% filter(year==2011)
# flowshs2export$i_iso3 %>% unique()
# flowshs2export$j_iso3 %>% unique()
