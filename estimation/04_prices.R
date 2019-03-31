### TODOs ###

# calculate tradable shares and plot versus gdppc

# P is a "sigma"-norm and norms are homogenous functions, 
# so increasing prices by a factor of lambda leads the price index to increase by a factor of lambda

### SETUP ###

# rm(list=ls())
libs <- c('tidyverse', 'R.utils', 'countrycode', 'ggrepel', 'stringr', "readxl")
sapply(libs, require, character.only = TRUE)

sourceFiles <- list.files("source/")
for (i in sourceFiles) {
  source(paste0("source/", i))
}

source("params.R")

# Basic Headings or Analytical Categories?
BH <- TRUE

EUD <- TRUE # disaggregate EU?

if (EUD==FALSE) {
  ccodes <- read_csv("clean/ccodes.csv") %>% pull(.)
} else {
  ccodes <- read_csv("clean/ccodesEUD.csv") %>% pull(.)
}

### DATA ###

if (BH == FALSE) {
  
  # NOTE: Not configured for disaggregated EU
  
  ccodesAll <- read_csv("data/flows/codes.csv") %>% pull(iso3)
  icpCodes <- read_csv("data/prices/icpCodes.csv")
  
  # match classification codes and append tradable indicators
  icpCodes2005 <- icpCodes %>% select(`2005`, `2011`, tradable, aggregate)
  icpCodes2011 <- icpCodes %>% select(`2011`, tradable, aggregate)
  
  icp2005 <- read_csv("data/prices/prices2005ICP.csv", col_types = list(`Classification Code`=col_character()))
  icp2005 <- left_join(icp2005, icpCodes2005, by=c("Classification Code"="2005"))
  icp2011 <- read_csv("data/prices/prices2011ICP.csv")
  icp2011 <- left_join(icp2011, icpCodes2011, by=c("Classification Code"="2011"))
  
  colnames(icp2005)[colnames(icp2005)=="2005 [YR2005]"] <- "val"
  colnames(icp2011)[colnames(icp2011)=="2011 [YR2011]"] <- "val"
  
  icp2005$`Classification Code` <- icp2005$`2011`
  icp2005 <- icp2005 %>% select(-one_of(c("2011")))
  
  icp2005$year <- 2005
  icp2011$year <- 2011
  
  icp <- bind_rows(icp2005, icp2011)
  
  icpClass <- icp %>% select(`Classification Name`, `Classification Code`) %>% unique()
  icpSeries <- icp %>% select(`Series Name`, `Series Code`) %>% unique()
  
  # clean up columns
  icp <- icp %>% select(year, `Country Code`, `Classification Code`, `Series Code`, val, tradable, aggregate)
  colnames(icp) <- c("year", "iso3", "classification", "series", "val", "tradable", "aggregate")
  
  # fix Russia 2005 (use OECD stats)
  icp$iso3 <- ifelse(icp$iso3=="RU1", "RUS", icp$iso3)
  icp <- icp %>% filter(!iso3=="RU2")
  
  # filter country aggregates
  icp <- icp %>% filter(iso3 %in% ccodesAll)
  
  ### Calcualte Price Indices ###
  
  # gdp for EU weights
  GDPdata <- icp %>% filter(series %in% c("CD", "S04"), classification=="C01") %>% select(year, iso3, val)
  colnames(GDPdata) <- c("year", "iso3", "gdp")
  GDPdata$gdp <- ifelse(GDPdata$year==2005, GDPdata$gdp / 1000000000, GDPdata$gdp)
  
  # population data
  POPdata <- icp %>% filter(series %in% c("POP", "S12"), classification=="C01") %>% select(year, iso3, val)
  colnames(POPdata) <- c("year", "iso3", "pop")
  POPdata$pop <- ifelse(POPdata$year==2005, POPdata$pop / 1000000, POPdata$pop)
  
  # get expenditure shares and relative price levels (different series codes for 2005/2011)
  Pdata <- icp %>% filter(series %in% c("GD.ZS", "PX.WL", "S02", "S08"), aggregate==0)
  Pdata$series <- ifelse(Pdata$series %in% c("GD.ZS", "S02"), "expShare", Pdata$series)
  Pdata$series <- ifelse(Pdata$series %in% c("PX.WL", "S08"), "priceLevel", Pdata$series)
  Pdata <- Pdata %>% spread(series, val)
  
  # price of tradables
  PdataT <- Pdata %>% filter(tradable==1)
  
  Pall <- PdataT %>% group_by(year, iso3) %>%
    summarise(P=weighted.mean(priceLevel, expShare),
              Tshare=sum(expShare))
  Pall <- left_join(Pall, GDPdata)
  Pall <- left_join(Pall, POPdata)
  
  Pall$iso3 <- mapEU(Pall$iso3, Pall$year)
  Pall$iso3 <- ifelse(Pall$iso3 %in% ccodes, Pall$iso3, "ROW")
  
  Pall <- Pall %>% filter(!is.na(gdp) & !is.na(P))
  
  P <- Pall %>% group_by(year, iso3) %>%
    summarise(priceIndex=weighted.mean(P, gdp),
              Tshare=weighted.mean(Tshare, gdp)/100,
              pop=sum(pop),
              gdpUSD=sum(gdp))
  P$gdppc <- P$gdp / P$pop
  
} else {

  ### DATA ###
  
  icpPrc <- read_excel("dataProprietary/ICP2011.xlsx", sheet="PPPs (BH)", skip=6)
  icpExp <- read_excel("dataProprietary/ICP2011.xlsx", sheet="EXP (BH)", skip=6)
  icpExc <- read_excel("dataProprietary/ICP2011.xlsx", sheet="Exchange Rate", skip=5)
  icpExpAgg <- read_excel("dataProprietary/ICP2011.xlsx", sheet="EXP (AGG)", skip=6)
  icpPop <- read_excel("dataProprietary/ICP2011.xlsx", sheet="Population", skip=5)
  
  trdbls <- read_excel("dataProprietary/bh.xlsx")
  
  ### CLEAN ###
  
  colnames(icpPrc)[1:2] <- c("Code", "Name")
  icpPrc <- gather(icpPrc, "ccode", "ppp", -c(Code, Name))
  
  colnames(icpExp)[1:2] <- c("Code", "Name")
  icpExp <- gather(icpExp, "ccode", "exp", -c(Code, Name))
  
  icpExc <-icpExc %>% select(`Country Code`, `2011 Exchange Rate Value`)
  colnames(icpExc) <- c("ccode", "exc")
  
  # use my tradable classification
  trdbls <- trdbls %>% select(Code, Name, `Tradeable (BC)`)
  colnames(trdbls) <- c("Code", "Name", "trdbl")
  
  # population
  icpPop <- icpPop %>% select(`Country Code`, `2011 Population`)
  colnames(icpPop) <- c("ccode", "pop")
  
  # map EU
  if(EUD==FALSE) {
    icpPop$ccode <- mapEU(icpPop$ccode, rep(2011, nrow(icpPop)))
  }
  
  icpPop <- icpPop %>% group_by(ccode) %>%
    summarise(pop=sum(pop))
  
  ### COMPUTE ###
  
  icpBH <- left_join(icpPrc, icpExp)
  icpBH$pppNom <- as.numeric(icpBH$ppp)
  icpBH$expNom <- as.numeric(icpBH$exp)
  
  icpBH <- left_join(icpBH, icpExc)
  icpBH <- left_join(icpBH, trdbls)

  icpBH$expNom <- ifelse(is.na(icpBH$expNom), 0, icpBH$expNom)
  
  # base currency (USD)
  icpBH$pppReal <- icpBH$pppNom / icpBH$exc
  icpBH$expReal <- icpBH$expNom / icpBH$exc

  icpBH <- icpBH %>% select(-c(Code, ppp, exp, pppNom, expNom, exc))
  
  # filter out countries outside of analysis
  icpBH <- icpBH %>% filter(ccode %in% c(ccodes, EU27))
  # icpBH %>% pull(ccode) %>% unique() %>% sort()
  
  # real income (EU aggregated, tradables and nontradables)
  icpBHA <- icpBH
  
  if(EUD==FALSE) {
    icpBHA$ccode <- mapEU(icpBHA$ccode, rep(2011, nrow(icpBHeu)))
  }
  
  icpG <- icpBHA %>% group_by(ccode) %>%
    summarise(gdpUSD=sum(expReal))
  
  # filter tradables
  icpBHT <- icpBH %>% filter(trdbl==1)
  
  # get expenditure shares on tradables
  icpGT <- icpBHT %>% group_by(ccode) %>%
    summarise(gdpUSDT=sum(expReal))
  
  icpBHT <- left_join(icpBHT, icpGT)
  
  icpBHT$expShareT <- icpBHT$expReal / icpBHT$gdpUSDT

  ### ESTIMATE PREFERENCE PARAMETERS ###
  
  # Note: estimate using full sample, then aggregate EU
  
  baseProduct <- "Cheese"
  icpBHTbase <- icpBHT %>% filter(Name==baseProduct) %>% select(ccode, pppReal, expShareT)
  colnames(icpBHTbase) <- c("ccode", "pppRealBase", "expShareTBase")

  # filter products with less than or equal to zero expenditure share
  # Cyprus and Malta have negative expenditures on other transport equipment?
  icpBHTEst <- left_join(icpBHT, icpBHTbase) %>% filter(expShareT > 0) %>% select(ccode, Name, pppReal, expShareT, pppRealBase, expShareTBase, gdpUSDT)

  icpBHTEst$DeltaLambda <- log(icpBHTEst$expShareT) - log(icpBHTEst$expShareTBase)
  icpBHTEst$DeltaP <- log(icpBHTEst$pppReal) - log(icpBHTEst$pppRealBase)
  
  icpBHTEst$phi <- icpBHTEst$DeltaLambda - (1 - sigma) * icpBHTEst$DeltaP

  icpBHTHat <- icpBHTEst  %>% group_by(Name) %>%
    summarise(gammaHat=weighted.mean(phi, gdpUSDT))
  
  icpBHTHat$alphaHat <- exp(icpBHTHat$gammaHat) 
  # products with coefficient of one are valued equally to cheese
  
  icpBHTHat <- icpBHTHat %>% select(Name, alphaHat)

  ### CALCULATE PRICE INDICES ###
  
  icpBHT <- left_join(icpBHT, icpBHTHat)
  
  # Aggregate EU
  if (EUD==FALSE) {
    icpBHT$ccode <- mapEU(icpBHT$ccode, rep(2011, nrow(icpBHT)))
  }
  
  icpBHTAgg <- icpBHT %>% group_by(ccode, Name) %>%
    summarise(expReal=sum(expReal),
              pppReal=weighted.mean(pppReal, gdpUSDT),
              alphaHat=mean(alphaHat))
  
  gdpUSDT <- icpBHT %>% group_by(ccode) %>%
    summarise(gdpUSDT=sum(expReal))

  icpBHTAgg <- left_join(icpBHTAgg, gdpUSDT)
  
  # recalculate expenditure shares for EU
  icpBHTAgg$expShareT <- icpBHTAgg$expReal / icpBHTAgg$gdpUSDT
  
  # export
  if(EUD==FALSE) {
    write_csv(icpBHTAgg, "clean/icpBHTAgg.csv")
  } else {
    write_csv(icpBHTAgg, "clean/icpBHTAggEUD.csv")
  }
  
  icpP <- icpBHTAgg %>% group_by(ccode) %>%
    summarise(priceIndex=priceIndex(alphaHat, pppReal, sigma),
              expT=sum(expReal))
  
  us <- icpP %>% filter(ccode=="USA") %>% pull(priceIndex)
  icpP$priceIndexBase <- icpP$priceIndex / us

  icpP <- left_join(icpP, icpG)
  
  icpP$Tshare <- icpP$expT / icpP$gdpUSD
  
  # gdppc
  icpP <- left_join(icpP, icpPop)
  icpP$gdppc <- icpP$gdpUSD / icpP$pop
  
  icpP <- icpP %>% select(-priceIndex)
  colnames(icpP)[colnames(icpP)=="priceIndexBase"] <- "priceIndex"
  colnames(icpP)[colnames(icpP)=="ccode"] <- "iso3"
  
  icpP$year <- 2011
  
  P <- icpP
  
}

### EXPORT ###

# price indices
if(EUD==FALSE) {
  write_csv(P, "clean/priceIndex.csv")
} else {
  write_csv(P, "clean/priceIndexEUD.csv")
}

# population
pop <- P %>% select(year, iso3, pop)

if(EUD==FALSE) {
  write_csv(pop, "clean/pop.csv")
} else {
  write_csv(pop, "clean/popEUD.csv")
}

# P %>% filter(iso3=="IRL")
# P %>% filter(iso3 %in% EU27) %>% print(n=27)
