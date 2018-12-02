### TO-DOs ###

# Add Chile adv costs?
# Does BACI contain country groupings? Might be inferring too much openness for ROW
# aggregate Hong Kong and China?

### SETUP ###

rm(list=ls())
libs <- c('tidyverse', 'R.utils', 'countrycode')
sapply(libs, require, character.only = TRUE)

sourceFiles <- list.files("source/")
for (i in sourceFiles) {
  source(paste0("source/", i))
}

startY <- 1995
endY <- 2011

ccodes <- read_csv("clean/ccodes.csv") %>% pull(.)

# modes directory
mdir <- paste0("data/modes/")

### AGGREGATE FLOW DATA ###

flowsL <- list()

fcodes <- read_csv("data/flows/codes.csv") %>% select(i, iso3)

tick <- 1
for (i in seq(startY, endY)) {
  year <- i
  flowspath <- paste0("data/flows/", year, ".csv")
  flows <- read_csv(flowspath)
  flowsL[[tick]] <- flows
  tick <- tick + 1
}

flows <- bind_rows(flowsL)

rm(flowsL)

colnames(flows)[1] <- "year"
flows$hs2 <- substring(as.character(flows$hs6), 1, 2)

# append country iso3 codes
flows <- left_join(flows, fcodes)
colnames(flows)[colnames(flows) == 'iso3'] <- "i_iso3"
flows <- left_join(flows, fcodes, by=c("j"="i"))
colnames(flows)[colnames(flows) == 'iso3'] <- "j_iso3"

write_csv(flows, "clean/flowshs6.csv")

flowshs2 <- flows %>% group_by(year, hs2, i_iso3, j_iso3) %>% 
  summarise(val=sum(v)) %>%
  ungroup()
# summary(flowshs2)

rm(flows)

### GEOGRAPHIC DATA ###

# append distances
seadist <- read_csv('data/dists/CERDI-seadistance.csv')
cepiidist <- read_csv('data/dists/dist_cepii.csv')
cepiigeo <- read_csv('data/dists/geo_cepii.csv')

# drop duplicate entries
cepiigeo <- cepiigeo[!duplicated(cepiigeo$iso3), ]

colnames(seadist)[1:2] <- colnames(cepiidist)[1:2] <- c("i_iso3", "j_iso3")

# convert condordences 
cepiidist$i_iso3 <- ifelse(cepiidist$i_iso3 == "ROM", "ROU", cepiidist$i_iso3)  # Romania
cepiidist$j_iso3 <- ifelse(cepiidist$j_iso3 == "ROM", "ROU", cepiidist$j_iso3)  # Romania
cepiigeo$iso3 <- ifelse(cepiigeo$iso3 == "ROM", "ROU", cepiigeo$iso3)  # Romania

# Serbia and Montenegro
yug_i <- cepiidist %>% filter(i_iso3 == "YUG")
yug_j <- cepiidist %>% filter(j_iso3 == "YUG")
yug_geo <- cepiigeo %>% filter(iso3 == "YUG")

yug_i$i_iso3 <- "SRB"
cepiidist <- bind_rows(cepiidist, yug_i)
yug_i$i_iso3 <- "MNE"
cepiidist <- bind_rows(cepiidist, yug_i)

yug_j$j_iso3 <- "SRB"
cepiidist <- bind_rows(cepiidist, yug_j)
yug_j$j_iso3 <- "MNE"
cepiidist <- bind_rows(cepiidist, yug_j)

yug_geo$iso3 <- "SRB"
cepiigeo <- bind_rows(cepiigeo, yug_geo)
yug_geo$iso3 <- "MNE"
cepiigeo <- bind_rows(cepiigeo, yug_geo)

# Note: seadist can sometimes be shorter than adist because adist is population-weighted while
# seadist is coast-coast

# append to flows
seadist <- seadist %>% select(i_iso3, j_iso3, seadistance)
flowshs2 <- left_join(flowshs2, seadist, by=c("i_iso3", "j_iso3"))

cepiidist <- cepiidist %>% select(i_iso3, j_iso3, contig, distw)
flowshs2 <- left_join(flowshs2, cepiidist, by=c("i_iso3", "j_iso3"))

cepiigeo <- cepiigeo %>% select(iso3, landlocked)
colnames(cepiigeo)[2] <- "i_landlocked"
flowshs2 <- left_join(flowshs2, cepiigeo, by=c("i_iso3"="iso3"))
colnames(cepiigeo)[2] <- "j_landlocked"
flowshs2 <- left_join(flowshs2, cepiigeo, by=c("j_iso3"="iso3"))

# # since there's no aggregation, max/min/weighted mean will just produce constant values
# flowsdist <- flows %>% group_by(i_iso3, j_iso3) %>%
#   summarise(seadist=weighted.mean(seadistance, v, na.rm=T),
#             adist=weighted.mean(distw, v, na.rm=T),
#             contig=max(contig, na.rm=T),
#             i_landlocked = min(i_landlocked, na.rm=T),
#             j_landlocked = min(j_landlocked, na.rm=T)) %>% 
#   ungroup()

# flowshs2 <- left_join(flowshs2, flowsdist)

write_csv(flowshs2, "clean/flowshs2all.csv")




### ALTERNATIVE STARTING POINT ###

flowshs2 <- read_csv("clean/flowshs2all.csv")
ccodes <- read_csv("clean/ccodes.csv") %>% pull(.)




### FULLY OBSERVED CIF/FOB RATIOS ###

### United States

uscodespath <- paste0(mdir, "us/", "codes.csv")
uscodes <- read_csv(uscodespath) %>% select(code, iso2)

fcodes <- read_csv("data/flows/codes.csv") %>% select(iso3, iso2)
fcodes <- fcodes %>% add_row(iso2="TW", iso3="TWN")  # Add Taiwan

usL <- list()
cols <- c("scommodity", "cty_code", "year", "con_val_yr", "con_cha_yr", "air_val_yr", "air_cha_yr", "ves_val_yr", "ves_cha_yr")

tick <- 1
for (i in seq(startY, endY)) {
  year <- i
  uspath <- paste0(mdir, "us/", year, ".csv")
  # specify col types as double to kill integer parsing failures
  usmodes <- read_csv(uspath, col_types = cols(scommodity=col_character(), ves_wgt_yr=col_double(), ves_val_yr=col_double(), gen_qy2_yr=col_double(), con_qy2_yr=col_double(), cnt_val_yr=col_double(), cal_dut_yr=col_double(), cards_yr=col_double()))
  print("scommodity" %in% colnames(usmodes))
  usL[[tick]] <- usmodes %>% select(one_of(cols))
  tick <- tick + 1
}

usmodes <- bind_rows(usL)

usmodes <- left_join(usmodes, uscodes, by=c("cty_code"="code"))
usmodes <- left_join(usmodes, fcodes)

usmodes$hs2 <- substring(usmodes$scommodity, 1, 2)

# data for freight, map straight to EU/ROW categories
usmodesF <- usmodes

usmodesF$iso3 <- mapEU(usmodesF$iso3, usmodesF$year)
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


### New Zealand

nzbase <- "data/nz/"

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

nz$i_iso3 <- mapEU(nz$i_iso3, nz$year)
nz$i_iso3 <- ifelse(nz$i_iso3 %in% ccodes, nz$i_iso3, "ROW")
nz <- nz %>% filter(i_iso3!="NZL")  # filter NZ own trade observations
# nz %>% filter(cname=="Japan") %>% summary()
nz <- nz %>% filter(!(is.na(cif) | is.na(vfd)))  # filter unobserved costs

nzCosts <- nz %>% group_by(year, i_iso3) %>%
  summarise(cif=sum(cif),
            vfd=sum(vfd))
# nzCosts$i_iso3 %>% unique()
nzCosts %>% filter(i_iso3 == "JPN")

nzCosts <- nzCosts %>% filter(vfd > 0)
nzCosts$adv <- nzCosts$cif / nzCosts$vfd - 1

nzCosts$j_iso3 <- "NZL"
nzCosts <- nzCosts %>% select(year, i_iso3, j_iso3, adv)


### Chile

chlbase <- "data/chl/"

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

chl$i_iso3 <- mapEU(chl$i_iso3, chl$year)
chl$i_iso3 <- ifelse(chl$i_iso3 %in% ccodes, chl$i_iso3, "ROW")

chlCosts <- chl %>% group_by(year, i_iso3) %>%
  summarise(fob=sum(fob),
            cif=sum(cif))

chlCosts$adv <- chlCosts$cif / chlCosts$fob - 1
chlCosts$j_iso3 <- "CHL"
chlCosts <- chlCosts %>% select(year, i_iso3, j_iso3, adv)

### Export

freightC <- list(usCosts, nzCosts, chlCosts)

freight <- bind_rows(freightC)

write_csv(freight, "clean/freight.csv")

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
jpnmodes$iso3 %>% unique() %>% sort()

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
eumodeshares$j_iso3 %>% unique() %>% sort()

eumodeshares$airshare <- eumodeshares$air / eumodeshares$tot
eumodeshares$seashare <- eumodeshares$sea / eumodeshares$tot
eumodeshares$landshare <- eumodeshares$land / eumodeshares$tot
eumodeshares$othershare <- eumodeshares$other / eumodeshares$tot

eumodeshares <- eumodeshares %>% select(year, i_iso3, j_iso3, hs2, airshare, seashare, landshare, othershare)
eumodeshares %>% filter(i_iso3=="ARG", year==2011)

# eumodeshares[is.na(eumodeshares)] <- 0 # if share not computed for a specific mode then others sum to 1

flowshs2 <- left_join(flowshs2, eumodeshares, by=c("year", "hs2", "i_iso3", "j_iso3"))
flowshs2$airshare <- ifelse(is.na(flowshs2$airshare.x), flowshs2$airshare.y, flowshs2$airshare.x)
flowshs2$seashare <- ifelse(is.na(flowshs2$seashare.x), flowshs2$seashare.y, flowshs2$seashare.x)
flowshs2$landshare <- ifelse(is.na(flowshs2$landshare.x), flowshs2$landshare.y, flowshs2$landshare.x)
flowshs2$othershare <- ifelse(is.na(flowshs2$othershare.x), flowshs2$othershare.y, flowshs2$othershare.x)
flowshs2 <- flowshs2 %>% select(-one_of(c("airshare.x", "airshare.y", "seashare.x", "seashare.y", "landshare.x", "landshare.y", "othershare.x", "othershare.y")))

flowshs2 %>% filter(!is.na(othershare)) %>% pull(j_iso3) %>% unique()
flowshs2 %>% summary()

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

flowshs2$i_iso3 <- mapEU(flowshs2$i_iso3, flowshs2$year)
flowshs2$j_iso3 <- mapEU(flowshs2$j_iso3, flowshs2$year)

# drop internal EU flows
flowshs2 <- flowshs2 %>% filter(!(i_iso3 == "EU" & j_iso3 == "EU"))
# lowshs2$i_iso3 %>% unique() %>% sort()

# # append maritime transport costs
mtc <- read_csv("data/mtc/mtc.csv")
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
# mtc$i_iso3 <- ifelse(mtc$i_iso3 %in% EU, "EU", mtc$i_iso3)
mtc$j_iso3 %>% unique() %>% sort()
mtc$i_iso3 %>% unique() %>% sort()

mtc$v <- mtc$cif / (1 + mtc$adva) # convert to fob value for weighting

# compute trade-weighted ad valorem cost
mtcagg <- mtc %>% group_by(j_iso3, i_iso3, hs2, year) %>%
  summarise(avcsea=weighted.mean(adva, v)) %>% ungroup()

summary(mtcagg)
mtcagg1995 <- mtcagg %>% filter(year==1995)
mtcagg2007 <- mtcagg %>% filter(year==2007)
mean(mtcagg1995$avcsea) - mean(mtcagg2007$avcsea)  # consistent with ACD data

# mtcagg %>% filter(j_iso3=="IDN", year==1996, hs2==71)

# mtcagg %>% select(year, i_iso3, j_iso3, hs2) %>% nrow()
# mtcagg %>% select(year, i_iso3, j_iso3, hs2) %>% unique() %>% nrow()

rm(mtc)

flowshs2 <- left_join(flowshs2, mtcagg, by=c("year", "i_iso3", "j_iso3", "hs2"))

flowshs2$avcsea <- ifelse(is.na(flowshs2$avcsea.x), flowshs2$avcsea.y, flowshs2$avcsea.x)
flowshs2 <- flowshs2 %>% select(-one_of(c("avcsea.x", "avcsea.y")))

# remaining countries become ROW
flowshs2$i_iso3 <- ifelse(flowshs2$i_iso3 %in% ccodes, flowshs2$i_iso3, 'ROW')
flowshs2$j_iso3 <- ifelse(flowshs2$j_iso3 %in% ccodes, flowshs2$j_iso3, 'ROW')

# filter ROW internal trade
flowshs2 <- flowshs2 %>% filter(!(i_iso3 == "ROW" & j_iso3 == "ROW"))

summary(flowshs2)

# aggregate and export trade matrix
flowsAgg <- flowshs2 %>% group_by(year, i_iso3, j_iso3) %>%
  summarise(val=sum(as.numeric(val)))
flowsAgg$year <- flowsAgg$year %>% as.integer()
write_csv(flowsAgg, "clean/flowsAgg.csv")
# flowsAgg[3764:3775, ]

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

summary(flowshs2export)
flowshs2export$year <- flowshs2export$year %>% as.integer()  # weird things happen when years saved as double

write_csv(flowshs2export, "clean/flowshs2.csv")

