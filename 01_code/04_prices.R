print("-----")
print("Starting 04_prices.R")
print("-----")

### Get customizable arguments from command line ###

args <- commandArgs(trailingOnly=TRUE)
if (is.null(args) | identical(args, character(0))) {
  EUD <- FALSE
  TPSP <- FALSE
  size <- "all"
  bootstrap <- FALSE
} else {
  EUD <- ifelse(args[1] == "True", TRUE, FALSE)
  TPSP <- ifelse(args[2] == "True", TRUE, FALSE)
  size <- args[3]
  bootstrap <- ifelse(args[4] == "True", TRUE, FALSE)
  bootstrap_id <- args[5]
}

### SETUP ###

shiny <- FALSE
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

icpBH$expNom <- ifelse(is.na(icpBH$expNom), 0, icpBH$expNom)

# base currency (USD)
icpBH$pppReal <- icpBH$pppNom / icpBH$exc
icpBH$expReal <- icpBH$expNom / icpBH$exc

icpBH <- icpBH %>% select(-c(Code, ppp, exp, pppNom, expNom, exc))

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

### AGGREGATION ###

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

icpBHTagg <- icpBHT %>% group_by(Name, ccode) %>%
  summarise(pppReal=weighted.mean(pppReal, gdpUSDT, na.rm=T),
            expReal=sum(expReal, na.rm=T))

icpBHTgdp <- icpBHT %>% group_by(ccode) %>%
  summarise(gdpUSDT=sum(expReal))

icpBHTagg <- left_join(icpBHTagg, icpBHTgdp)

icpBHTagg$expShareT <- icpBHTagg$expReal / icpBHTagg$gdpUSDT

# export
if(EUD==FALSE) {
  if (TPSP==FALSE) {
    write_csv(icpBHTagg, paste0(cleandir, "icpBHTAgg.csv"))
    write_csv(icpBHTagg, paste0(shinydir, "icpBHTAgg.csv"))
  } else {
    write_csv(icpBHTagg, paste0(cleandirTPSP, "icpBHTAgg.csv"))
  }
} else {
  write_csv(icpBHTagg, paste0(cleandirEU, "icpBHTAgg.csv"))
}

# filter products with less than or equal to zero expenditure share
# Cyprus and Malta have negative expenditures on other transport equipment?
icpBHTEst <- icpBHTagg %>% filter(expShareT > 0) %>% select(ccode, Name, pppReal, expShareT, gdpUSDT)
icpBHTEst <- icpBHTEst %>% filter(!is.na(pppReal), !is.na(expShareT)) # filter out observations without ppps

### ESTIMATE SIGMA AND PRICE INDICES ###

icpBHTEstUSA <- icpBHTEst %>% filter(ccode=="USA") %>% select(Name, expShareT)
colnames(icpBHTEstUSA) <- c("Name", "expShareT_USA")

icpBHTEst <- left_join(icpBHTEst, icpBHTEstUSA) %>% filter(ccode != "USA")
icpBHTEst$deltaLambda <- log(icpBHTEst$expShareT / icpBHTEst$expShareT_USA)
icpBHTEst$lnp <- log(icpBHTEst$pppReal)
icpBHTEst <- icpBHTEst %>% filter(!is.na(deltaLambda))

### BOOTSTRAP ###

# if (runBootstrap==TRUE) {
#   
#   P_bstrp_mat <- data.frame(ccodes)
#   colnames(P_bstrp_mat) <- "ccode"
#   
#   for (m in 1:M) {
#     
#     # TODO: should I be sampling from here, or higher up in raw price data?
#     icpBHTEst_m <- icpBHTEst %>% group_by(ccode) %>% sample_frac(size=1, replace=T)
#     # icpBHTEst_m %>% filter(ccode=="AUS") %>% print(n=50)
#     
#     sigmaModel_m <- lm(lnp ~ deltaLambda + ccode - 1, data=icpBHTEst_m)
#     mu_t_m <- sigmaModel_m$coefficients[-1]
#     Phat_m <- data.frame(ccode=icpBHTEst$ccode %>% unique(), P=exp(mu_t_m)) %>% as_tibble()
#     Phat_m <- Phat_m %>% add_row(ccode="USA", P=1) %>% arrange(ccode)
#     colnames(Phat_m) <- c("ccode", paste0("P", m))
#     
#     P_bstrp_mat <- P_bstrp_mat %>% left_join(Phat_m)
# 
#   }
# }
# 
# P_bstrp_mat <- P_bstrp_mat %>% as_tibble()
# write_csv(P_bstrp_mat, paste0(bootstrapdir, "P.csv"))

if (bootstrap == TRUE) {
  icpBHTEst <- icpBHTEst %>% group_by(ccode) %>% sample_frac(size=1, replace=T)
}

### BASE MODEL ###

sigmaModel <- lm(lnp ~ deltaLambda + ccode - 1, data=icpBHTEst)
sigma_t <- sigmaModel$coefficients[1] %>% as.numeric()
sigma <- 1 - 1 / sigma_t
mu_t <- sigmaModel$coefficients[-1]
Phat <- data.frame(ccode=icpBHTEst$ccode %>% unique(), P=exp(mu_t)) %>% as_tibble()
Phat <- Phat %>% add_row(ccode="USA", P=1) %>% arrange(ccode)
# Phat %>% print(n=50)

### EXPORT ###

gdpUSDT <- icpBHTagg %>% group_by(ccode) %>%
  summarise(gdpUSDT=sum(expReal, na.rm=T))

icpBHTagg <- left_join(icpBHTagg, gdpUSDT)

expT <- icpBHTagg %>% group_by(ccode) %>%
  summarise(expT=sum(expReal, na.rm = T))

cleanP <- left_join(Phat, expT)
cleanP <- left_join(cleanP, gdpUSDT)
cleanP <- left_join(cleanP, icpPop)
cleanP <- left_join(cleanP, icpG)

cleanP$gdppc <- cleanP$gdpUSD / cleanP$pop
cleanP$year <- Y
cleanP$Tshare <- cleanP$expT / cleanP$expUSD

colnames(cleanP)[colnames(cleanP)=="P"] <- "priceIndex"
colnames(cleanP)[colnames(cleanP)=="ccode"] <- "iso3"

### EXPORT ###

# price indices
# cleanP %>% print(n=100)
if (bootstrap==FALSE) {
  if(EUD==FALSE) {
    if (TPSP==FALSE) {
      write_csv(cleanP, paste0(cleandir, "priceIndex.csv"))
      write_csv(cleanP, paste0(shinydir, "priceIndex.csv"))
    } else {
      write_csv(cleanP, paste0(cleandirTPSP, "priceIndex.csv"))
    }
  } else {
    write_csv(cleanP, paste0(cleandirEU, "priceIndex.csv"))
  }
} else {
  write_csv(cleanP, paste0(bootstrap_P_dir, bootstrap_id, ".csv"))
}

# population
pop <- cleanP %>% select(year, iso3, pop)

if (bootstrap==FALSE) {
  if(EUD==FALSE) {
    if (TPSP==FALSE) {
      write_csv(pop, paste0(cleandir, "pop.csv"))
    } else {
      write_csv(pop, paste0(cleandirTPSP, "pop.csv"))
    }
  } else {
    write_csv(pop, paste0(cleandirEU, "pop.csv"))
  }
}

print("-----")
print("Concluding 04_prices.R")
print("-----")
