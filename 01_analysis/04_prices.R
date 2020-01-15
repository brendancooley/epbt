print("-----")
print("Starting 04_prices.R")
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

### SETUP ###

source("params.R")

libs <- c('tidyverse', 'R.utils', 'countrycode', 'ggrepel', 'stringr', "readxl")
ipak(libs)

if (EUD==FALSE) {
  if (TPSP==FALSE) {
    ccodes <- read_csv(paste0(cleandir, "ccodes.csv")) %>% pull(.)
  } else {
    ccodes <- read_csv(paste0(cleandirTPSP, "ccodes.csv")) %>% pull(.)
  }
} else {
  ccodes <- read_csv(paste0(cleandirEU, "ccodes.csv")) %>% pull(.)
}

### DATA ###

icpPrc <- read_excel(paste0(proprietaryDataPath, "ICP2011.xlsx"), sheet="PPPs (BH)", skip=6)
icpExp <- read_excel(paste0(proprietaryDataPath, "ICP2011.xlsx"), sheet="EXP (BH)", skip=6)
icpExc <- read_excel(paste0(proprietaryDataPath, "ICP2011.xlsx"), sheet="Exchange Rate", skip=5)
icpExpAgg <- read_excel(paste0(proprietaryDataPath, "ICP2011.xlsx"), sheet="EXP (AGG)", skip=6)
icpPop <- read_excel(paste0(proprietaryDataPath, "ICP2011.xlsx"), sheet="Population", skip=5)

trdbls <- read_excel(paste0(proprietaryDataPath, "bh.xlsx"))

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
} else{
  # otherwise combine belgium and luxemborg
  icpPop$ccode <- ifelse(icpPop$ccode=="LUX", "BEL", icpPop$ccode)
}

# other aggregations
if (BNL==TRUE) {
  icpPop$ccode <- ifelse(icpPop$ccode %in% BNLccodes, "BNL", icpPop$ccode)
}
if (ELL==TRUE) {
  icpPop$ccode <- ifelse(icpPop$ccode %in% ELLccodes, "ELL", icpPop$ccode)
}
if (MYSG==TRUE) {
  icpPop$ccode <- ifelse(icpPop$ccode %in% MYSGccodes, "MYSG", icpPop$ccode)
}

# aggregate ROW
icpPop$ccode <- ifelse(icpPop$ccode %in% c(ccodes, EU27), icpPop$ccode, ROWname)

icpPop <- icpPop %>% group_by(ccode) %>%
  summarise(pop=sum(pop))

### COMPUTE ###

icpBH <- left_join(icpPrc, icpExp)
icpBH$pppNom <- as.numeric(icpBH$ppp)
icpBH$expNom <- as.numeric(icpBH$exp)

icpBH <- left_join(icpBH, icpExc)
icpBH <- left_join(icpBH, trdbls)
# icpBH %>% filter(ccode=="LUX") %>% print(n=200)

icpBH$expNom <- ifelse(is.na(icpBH$expNom), 0, icpBH$expNom)

# base currency (USD)
icpBH$pppReal <- icpBH$pppNom / icpBH$exc
icpBH$expReal <- icpBH$expNom / icpBH$exc

icpBH <- icpBH %>% select(-c(Code, ppp, exp, pppNom, expNom, exc))

# icpBH %>% filter(ccode=="EST") %>% arrange(expReal) %>% print(n=200)

# filter out countries outside of analysis
# icpBH <- icpBH %>% filter(ccode %in% c(ccodes, EU27))
# icpBH %>% pull(ccode) %>% unique() %>% sort()
# classify ROW

# real income (EU, ROW aggregated, tradables and nontradables)
icpBHA <- icpBH

if(EUD==FALSE) {
  icpBHA$ccode <- mapEU(icpBHA$ccode, rep(2011, nrow(icpBHA)))
} else {
  # otherwise combine belgium and luxemborg
  icpBHA$ccode <- ifelse(icpBHA$ccode=="LUX", "BEL", icpBHA$ccode)
}

# other aggregations
if (BNL==TRUE) {
  icpBHA$ccode <- ifelse(icpBHA$ccode %in% BNLccodes, "BNL", icpBHA$ccode)
}
if (ELL==TRUE) {
  icpBHA$ccode <- ifelse(icpBHA$ccode %in% ELLccodes, "ELL", icpBHA$ccode)
}
if (MYSG==TRUE) {
  icpBHA$ccode <- ifelse(icpBHA$ccode %in% MYSGccodes, "MYSG", icpBHA$ccode)
}

icpBHA$ccode <- ifelse(icpBHA$ccode %in% c(ccodes, EU27), icpBHA$ccode, ROWname)

# icpBHA %>% filter(ccode=="USA") %>% print(n=200)
icpBHA$ccode %>% unique() %>% sort()

icpG <- icpBHA %>% group_by(ccode) %>%
  summarise(gdpUSD=sum(expReal, na.rm=T),
            netExports=sum(expReal[Name=="Exports of goods and services"]) + sum(expReal[Name=="Imports of goods and services"]))
icpG$expUSD <- icpG$gdpUSD - icpG$netExports

# filter tradables
icpBHT <- icpBH %>% filter(trdbl==1)

# get expenditure shares on tradables
icpGT <- icpBHT %>% group_by(ccode) %>%
  summarise(gdpUSDT=sum(expReal, na.rm=T))

icpBHT <- left_join(icpBHT, icpGT)

icpBHT$expShareT <- icpBHT$expReal / icpBHT$gdpUSDT
# icpBHT %>% print(n=100)

### ESTIMATE PREFERENCE PARAMETERS ###

# Note: estimate using full sample, then aggregate EU

baseProduct <- "Cheese"
icpBHTbase <- icpBHT %>% filter(Name==baseProduct) %>% select(ccode, pppReal, expShareT)
colnames(icpBHTbase) <- c("ccode", "pppRealBase", "expShareTBase")
# icpBHTbase %>% print(n=200)

# filter products with less than or equal to zero expenditure share
# Cyprus and Malta have negative expenditures on other transport equipment?
icpBHTEst <- left_join(icpBHT, icpBHTbase) %>% filter(expShareT > 0) %>% select(ccode, Name, pppReal, expShareT, pppRealBase, expShareTBase, gdpUSDT)
icpBHTEst <- icpBHTEst %>% filter(!is.na(pppReal) & !is.na(expShareT)) # filter out observations without ppps
# icpBHTEst %>% arrange(ccode) %>% print(n=100)
# icpBHTEst %>% filter(ccode=="ROW", Name=="Rice")

# calculate delta in logs
icpBHTEst$DeltaLambda <- log(icpBHTEst$expShareT) - log(icpBHTEst$expShareTBase)
icpBHTEst$DeltaP <- log(icpBHTEst$pppReal) - log(icpBHTEst$pppRealBase)

if (est_sigma == TRUE) {
  
  sigmaModel <- lm(DeltaLambda ~ DeltaP + Name - 1, data=icpBHTEst)
  # sigmaModel <- lm(DeltaLambda ~ DeltaP + Name - 1, data=icpBHTEst, weights=icpBHTEst$gdpUSDT)  # with gdp weights
  sigma_t <- sigmaModel$coefficients[1] %>% as.numeric()
  sigma <- 1 - sigma_t
  sigmaDF <- as.data.frame(sigma)
  
  if(EUD==FALSE) {
    if (TPSP==FALSE) {
      write_csv(sigmaDF, paste0(resultsdir, "sigma.csv"), col_names=FALSE)
    } else {
      write_csv(sigmaDF, paste0(resultsdirTPSP, "sigma.csv"), col_names=FALSE)
    }
  } else {
    write_csv(sigmaDF, paste0(resultsdirEU, "sigma.csv"), col_names=FALSE)
  }
  
  alpha_t <- sigmaModel$coefficients[-1]
  icpBHTHat <- data.frame(icpBHTEst$Name %>% unique() %>% sort(), as.numeric(alpha_t))
  colnames(icpBHTHat) <- c("Name", "alpha_t")
  icpBHTHat$alpha_t <- exp(icpBHTHat$alpha_t)
  colnames(icpBHTHat) <- c("Name", "alphaHat")
  
} else {
  icpBHTEst$phi <- icpBHTEst$DeltaLambda - (1 - sigma) * icpBHTEst$DeltaP
  icpBHTHat <- icpBHTEst  %>% group_by(Name) %>%
    summarise(gammaHat=weighted.mean(phi, gdpUSDT))
  icpBHTHat$alphaHat <- exp(icpBHTHat$gammaHat) 
  icpBHTHat <- icpBHTHat %>% select(Name, alphaHat)
}
# products with coefficient of one are valued equally to cheese
# will get different alphas if we don't weight observations

icpBHT <- left_join(icpBHT, icpBHTHat)

### BACK OUT U.S. PRICES ###

# icpBHTUSA <- icpBHT %>% filter(ccode=="USA")
# exp_USAbase <- icpBHTUSA %>% filter(Name==baseProduct) %>% pull(expReal)
# icpBHTUSA$p_implied <- (icpBHTUSA$alphaHat^(-1) * icpBHTUSA$expReal / exp_USAbase)^(1/(1-sigma))
# icpBHTUSA %>% arrange(desc(expReal)) %>% print(n=100)

### CALCULATE PRICE INDICES ###

# Aggregate EU, ROW
if (EUD==FALSE) {
  icpBHT$ccode <- mapEU(icpBHT$ccode, rep(2011, nrow(icpBHT)))
} else {
  # otherwise combine belgium and luxemborg
  icpBHT$ccode <- ifelse(icpBHT$ccode=="LUX", "BEL", icpBHT$ccode)
}

# other aggregations
if (BNL==TRUE) {
  icpBHT$ccode <- ifelse(icpBHT$ccode %in% BNLccodes, "BNL", icpBHT$ccode)
}
if (ELL==TRUE) {
  icpBHT$ccode <- ifelse(icpBHT$ccode %in% ELLccodes, "ELL", icpBHT$ccode)
}
if (MYSG==TRUE) {
  icpBHT$ccode <- ifelse(icpBHT$ccode %in% MYSGccodes, "MYSG", icpBHT$ccode)
}

icpBHT$ccode <- ifelse(icpBHT$ccode %in% c(ccodes, EU27), icpBHT$ccode, ROWname)

icpBHTAgg <- icpBHT %>% group_by(ccode, Name) %>%
  summarise(expReal=sum(expReal),
            pppReal=weighted.mean(pppReal, gdpUSDT, na.rm=T),
            alphaHat=mean(alphaHat))
# icpBHTAgg %>% filter(is.na(pppReal))

gdpUSDT <- icpBHT %>% group_by(ccode) %>%
  summarise(gdpUSDT=sum(expReal, na.rm=T))

icpBHTAgg <- left_join(icpBHTAgg, gdpUSDT)

# recalculate expenditure shares for EU
icpBHTAgg$expShareT <- icpBHTAgg$expReal / icpBHTAgg$gdpUSDT

# export
if(EUD==FALSE) {
  if (TPSP==FALSE) {
    write_csv(icpBHTAgg, paste0(cleandir, "icpBHTAgg.csv"))
  } else {
    write_csv(icpBHTAgg, paste0(cleandirTPSP, "icpBHTAgg.csv"))
  }
} else {
  write_csv(icpBHTAgg, paste0(cleandirEU, "icpBHTAgg.csv"))
}
# icpBHTAgg %>% print(n=100)
# testJPN <- icpBHTAgg %>% filter(ccode=="JPN")
# testUSA <- icpBHTAgg %>% filter(ccode=="USA")
# 
# priceIndex(testJPN$alphaHat, testJPN$pppReal, sigma)
# sum(testUSA$alphaHat * testUSA$pppReal^(1-sigma))^(1/(1-sigma))

icpP <- icpBHTAgg %>% group_by(ccode) %>%
  summarise(priceIndex=priceIndex(alphaHat, pppReal, sigma),
            expT=sum(expReal, na.rm = T))
# icpP %>% print(n=50)

us <- icpP %>% filter(ccode=="USA") %>% pull(priceIndex)
icpP$priceIndexBase <- icpP$priceIndex / us


icpP <- left_join(icpP, icpG)
# icpG %>% print(n=50)

icpP$Tshare <- icpP$expT / icpP$expUSD
# icpP %>% print(n=100)

# gdppc
icpP <- left_join(icpP, icpPop)
icpP$gdppc <- icpP$gdpUSD / icpP$pop

icpP <- icpP %>% select(-priceIndex)
colnames(icpP)[colnames(icpP)=="priceIndexBase"] <- "priceIndex"
colnames(icpP)[colnames(icpP)=="ccode"] <- "iso3"

icpP$year <- 2011

P <- icpP

# P %>% print(n=100)
# icpBH %>% filter(ccode=="SGP") %>% arrange(expReal) %>% print(n=200)
# icpBH %>% filter(ccode=="NLD") %>% arrange(expReal) %>% print(n=200)

### EXPORT ###

# price indices
if(EUD==FALSE) {
  if (TPSP==FALSE) {
    write_csv(P, paste0(cleandir, "priceIndex.csv"))
  } else {
    write_csv(P, paste0(cleandirTPSP, "priceIndex.csv"))
  }
} else {
  write_csv(P, paste0(cleandirEU, "priceIndex.csv"))
}

# population
pop <- P %>% select(year, iso3, pop)

if(EUD==FALSE) {
  if (TPSP==FALSE) {
    write_csv(pop, paste0(cleandir, "pop.csv"))
  } else {
    write_csv(pop, paste0(cleandirTPSP, "pop.csv"))
  }
} else {
  write_csv(pop, paste0(cleandirEU, "pop.csv"))
}
# P %>% print(n=50)
# P %>% filter(iso3=="IRL")
# P %>% filter(iso3 %in% EU27) %>% print(n=27)

print("-----")
print("Concluding 04_prices.R")
print("-----")