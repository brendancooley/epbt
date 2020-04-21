print("-----")
print("Starting 06_tau.R")
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

if (EUD==TRUE) {
  mkdir(resultsdirEU)
} else{
  if (TPSP==FALSE) {
    mkdir(resultsdir)
  } else {
    mkdir(resultsdirTPSP)
  }
}

# devtools::install_github("timelyportfolio/d3treeR")
libs <- c('tidyverse', 'latex2exp', 'ggrepel', 'ggthemes', "scales", "treemap", 
          "data.tree", "jsonlite", "ggraph", "igraph", "viridis")
ipak(libs)


### DATA ###

# flows and predicted costs
if (bootstrap==FALSE) {
  if (EUD==FALSE) {
    if (TPSP==FALSE) {
      X <- read_csv(paste0(cleandir, 'delta.csv')) %>% filter(year==Y)
    } else {
      X <- read_csv(paste0(cleandirTPSP, 'delta.csv')) %>% filter(year==Y)
    }
  } else {
    X <- read_csv(paste0(cleandirEU, 'delta.csv')) %>% filter(year==Y)
  }
} else {
  X <- read_csv(paste0(bootstrap_freight_dir, bootstrap_id, ".csv")) %>% filter(year==Y)
}


# prices
if (bootstrap==FALSE) {
  if (EUD==FALSE) {
    if (TPSP==FALSE) {
      P <- read_csv(paste0(cleandir, 'priceIndex.csv')) %>% select(iso3, year, priceIndex) %>% filter(year==Y)
      Tshare <- read_csv(paste0(cleandir, 'priceIndex.csv')) %>% select(iso3, year, Tshare) %>% filter(year==Y)
    } else {
      P <- read_csv(paste0(cleandirTPSP, 'priceIndex.csv')) %>% select(iso3, year, priceIndex) %>% filter(year==Y)
      Tshare <- read_csv(paste0(cleandirTPSP, 'priceIndex.csv')) %>% select(iso3, year, Tshare) %>% filter(year==Y)
    }
  } else {
    P <- read_csv(paste0(cleandirEU, 'priceIndex.csv')) %>% select(iso3, year, priceIndex) %>% filter(year==Y)
    Tshare <- read_csv(paste0(cleandirEU, 'priceIndex.csv')) %>% select(iso3, year, Tshare) %>% filter(year==Y)
  }
} else {
  P <- read_csv(paste0(bootstrap_P_dir, bootstrap_id, ".csv")) %>% select(iso3, year, priceIndex) %>% filter(year==Y)
  Tshare <- read_csv(paste0(bootstrap_P_dir, bootstrap_id, ".csv")) %>% select(iso3, year, Tshare) %>% filter(year==Y)
}


# gross consumption
if (EUD==FALSE) {
  if (TPSP==FALSE) {
    gc <- read_csv(paste0(cleandir, "gc.csv")) %>% filter(year==Y)
  } else {
    gc <- read_csv(paste0(cleandirTPSP, "gc.csv")) %>% filter(year==Y)
  }
} else {
  gc <- read_csv(paste0(cleandirEU, "gc.csv")) %>% filter(year==Y)
}

gc$gc <- gc$gc * 1000
colnames(gc)[colnames(gc)=="gc"] <- "j_tot_exp"

# gdp
if (EUD==FALSE) {
  if (TPSP==FALSE) {
    gdp <- read_csv(paste0(cleandir, "gdp.csv")) %>% filter(year==Y)
  } else {
    gdp <- read_csv(paste0(cleandirTPSP, "gdp.csv")) %>% filter(year==Y)
  }
} else {
  gdp <- read_csv(paste0(cleandirEU, "gdp.csv")) %>% filter(year==Y)
}
# gdp %>% arrange(desc(gdp))

gdp$exp <- gdp$exp * 1000
gdp$gdp <- gdp$gdp * 1000
gdp <- left_join(gdp, Tshare)
gdp$expS <- gdp$gdp * (1 - gdp$Tshare)

# deficits in cif
ccodes <- X$j_iso3 %>% unique() %>% sort()
cifD <- deficit(X, "cif", ccodes)

gdpR <- left_join(gdp, gc)
gdpR <- gdpR %>% select(iso3, year, j_tot_exp, exp, expS, Tshare)
colnames(gdpR)[colnames(gdpR)=="exp"] <- "j_con_exp"
colnames(gdpR)[colnames(gdpR)=="expS"] <- "j_expS"
colnames(gdpR)[colnames(gdpR)=="Tshare"] <- "j_Tshare"
gdpR$j_gcT <- gdpR$j_tot_exp - gdpR$j_expS
gdpR <- left_join(gdpR, cifD)
colnames(gdpR)[colnames(gdpR)=="deficit"] <- "j_deficit"

gdp <- gdp %>% select(iso3, year, expS)
colnames(gdp)[colnames(gdp)=="expS"] <- "j_expS"

# get home_exp and own share
X <- left_join(X, gc, by=c("year"="year", "j_iso3"="iso3"))
colnames(gc)[colnames(gc)=="j_tot_exp"] <- "i_tot_exp"
X <- left_join(X, gc, by=c("year"="year", "i_iso3"="iso3"))
X$delta <- X$avc
X$val <- X$fob

# correct for tradable shares
X <- left_join(X, gdp, by=c("year"="year", "j_iso3"="iso3"))
colnames(gdp)[colnames(gdp)=="j_expS"] <- "i_expS"
X <- left_join(X, gdp, by=c("year"="year", "i_iso3"="iso3"))
X$j_gcT <- X$j_tot_exp - X$j_expS
X$i_gcT <- X$i_tot_exp - X$i_expS

Ximp <- X %>% group_by(j_iso3, year) %>%
  summarise(j_tot_imp=sum(cif),
            j_gcT=mean(j_gcT))

Ximp$j_home_expT <- Ximp$j_gcT - Ximp$j_tot_imp
Ximp <- Ximp %>% select(j_iso3, year, j_home_expT)

X <- left_join(X, Ximp, by=c("j_iso3", "year"))

colnames(Ximp) <- c("i_iso3", "year", "i_home_expT")

X <- left_join(X, Ximp, by=c("i_iso3", "year"))

# calculate shares of total tradable expenditure
X$Lji <- X$cif / X$j_gcT

# initialize starting values for home expenditure
X$Lii <- X$i_home_expT / X$i_gcT  
X$Ljj <- X$j_home_expT / X$j_gcT

# append price indices
colnames(P) <- c("i_iso3", "year", "Pi")
X <- left_join(X, P)
colnames(P) <- c("j_iso3", "year", "Pj")
X <- left_join(X, P)

X <- X %>% arrange(j_iso3, i_iso3)
X %>% summary()
X %>% filter(is.na(j_expS))

# calculate taus and lambda_iis jointly
if (tauRev==FALSE) {
  X <- X %>% tauLambda(theta, "tau", "Lii", "Ljj")
  X$LiiAlt <- X$Lii
  X$LjjAlt <- X$Ljj
  X <- X %>% tauLambda(thetaAlt, "tauAlt", "LiiAlt","LjjAlt")
} else {
  colnames(gdpR)[colnames(gdpR)=="iso3"] <- "j_iso3"
  XgdpR <- tauLambdaRev(X, gdpR, theta, mu)
  X <- XgdpR[[1]]
  gdpR <- XgdpR[[2]]
  X$tauAlt <- X$tau
  # X %>% filter(j_iso3=="BNL") %>% select(Lji, Ljj)
}

# export trade shares (in pc value)
Xshares <- X %>% select(i_iso3, j_iso3, year, tau, Lji, Ljj, j_gcT, i_gcT)
# Xshares %>% group_by(j_iso3) %>% summarise(test1=sum(Lji*tau), test2=mean(Ljj))
# Xshares %>% summary()
# Xshares %>% filter(j_iso3=="VNM") %>% print(n=100)

if (bootstrap==FALSE) {
  if (EUD==FALSE) {
    if (tauRev==FALSE) {
      write_csv(Xshares, paste0(cleandir, "shares.csv"))
    } else {
      if (TPSP==FALSE) {
        write_csv(Xshares, paste0(cleandir, "sharesTR.csv"))
      } else {
        write_csv(Xshares, paste0(cleandirTPSP, "sharesTR.csv"))
      }
    }
  } else {
    write_csv(Xshares, paste0(cleandirEU, "shares.csv"))
  } 
  # export deficits
  if (tauRev==TRUE) {
    d <- gdpR %>% select(j_iso3, j_deficit)
    colnames(d) <- c("iso3", "deficit")
    if (TPSP==FALSE) {
      write_csv(d, paste0(cleandir, "dTR.csv"))
    } else {
      write_csv(d, paste0(cleandirTPSP, "dTR.csv"))
    }
  }
} else {
  if (TPSP==TRUE) {
    write_csv(Xshares, paste0(bootstrap_sharesTR_dir, bootstrap_id, ".csv"))
    write_csv(d, paste0(bootstrap_dTR_dir, bootstrap_id, ".csv"))
  }
}


# export policies
Xtau <- X %>% select(i_iso3, j_iso3, year, tau, tauAlt)
# Xtau %>% filter(i_iso3=="BNL") %>% print(n=100)

if (EUD==TRUE) {
  XEU <- X %>% filter(j_iso3 %in% EU27 & i_iso3 %in% EU27)
}
# Xtau %>% filter(j_iso3=="VNM") %>% print(n=100)

# export
if (bootstrap==FALSE) {
  if (EUD==FALSE) {
    if (tauRev==FALSE) {
      write_csv(Xtau, paste0(resultsdir, "tauY.csv"))
    } else {
      if (TPSP==FALSE) {
        write_csv(Xtau, paste0(resultsdir, "tauYTR.csv"))
      } else {
        write_csv(Xtau, paste0(resultsdirTPSP, "tauYTR.csv"))
      }
    }
  } else {
    write_csv(Xtau, paste0(resultsdirEU, "tauY.csv"))
    write_csv(Xtau, paste0(shinydir, "tauY.csv"))
  }
} else {
  write_csv(Xtau, paste0(bootstrap_tau_dir, bootstrap_id, ".csv"))
}


# calculate TRI and MAI
# gc weights, reflects value of markets, not value of trade
TRI <- X %>% filter(i_iso3 != j_iso3) %>% group_by(j_iso3, year) %>%
  summarise(
    tau=weighted.mean(tau, i_gcT, na.rm = T)
  )
TRI$i_iso3 <- "TRI"

MAI <- X %>% filter(i_iso3 != j_iso3) %>% group_by(i_iso3, year) %>%
  summarise(
    tau=weighted.mean(tau, j_gcT, na.rm=T)
  )
MAI$j_iso3 <- "MAI"

if (EUD==TRUE) {
  
  # TRI within EU
  TRIEU <- XEU %>% filter(i_iso3 != j_iso3) %>% group_by(j_iso3, year) %>%
    summarise(
      tau=weighted.mean(tau, i_gcT, na.rm = T)
    )
  TRIEU$i_iso3 <- "TRI"
  colnames(TRIEU)[colnames(TRIEU)=="tau"] <- "tauEU"
  
  # TRI within EU compared to overall TRI
  TRIEUOut <- X %>% filter(j_iso3 %in% EU27 & !(i_iso3 %in% EU27)) %>% group_by(j_iso3, year) %>%
    summarise(
      tau=weighted.mean(tau, i_gcT, na.rm = T)
    )
  colnames(TRIEUOut)[colnames(TRIEUOut)=="tau"] <- "tauEUOut"
  TRIEU <- left_join(TRIEU, TRIEUOut)
  TRIEU$tauFrac <- (TRIEU$tauEU - 1) / (TRIEU$tauEUOut - 1)
  
  MAIEU <- XEU %>% filter(i_iso3 != j_iso3) %>% group_by(i_iso3, year) %>%
    summarise(
      tau=weighted.mean(tau, j_gcT, na.rm=T)
    )
  MAIEU$j_iso3 <- "MAI"
  
  TRIEUall <- X %>% filter(i_iso3 != j_iso3) %>% group_by(j_iso3, year) %>%
    summarise(tau=weighted.mean(tau, i_gcT, na.rm=T))
  TRIEU <- left_join(TRIEU, TRIEUall)
    
  MAIEUall <- X %>% filter(i_iso3 != j_iso3) %>% group_by(i_iso3, year) %>%
    summarise(tau=weighted.mean(tau, j_gcT, na.rm=T))
  MAIEU <- left_join(MAIEU, MAIEUall)
  
}

### PLOTS ###

if (bootstrap==FALSE) {
  if (EUD==FALSE) {
    if (TPSP==FALSE) {
      tauHM <- bind_rows(list(Xtau, TRI, MAI))
      tauHMY <- tauHM %>% filter(year==Y)
      write_csv(tauHMY, paste0(resultsdir, "tauHMY.csv"))
      write_csv(tauHMY, paste0(shinydir, "tauHMY.csv"))
    }
  } else {
    # different variables
    # tauHM <- bind_rows(list(Xtau, TRIEU, MAIEU))
    # tauHMY <- tauHM %>% filter(year==Y)
    # write_csv(tauHMY, "results/tauHMYEUD.csv")
  }
  
  # TRI and MAI
  
  if (EUD==FALSE) {
    if (TPSP==FALSE) {
      trimai <- left_join(TRI %>% select(j_iso3, year, tau), MAI %>% select(i_iso3, year, tau), by=c("j_iso3"="i_iso3", "year")) %>% ungroup()
      colnames(trimai) <- c("iso3", "year", "TRI", "MAI")
      trimaiY <- trimai %>% filter(year==Y)
      write_csv(trimaiY, paste0(resultsdir, "trimaiY.csv"))
    }
  } else {
    trimai <- TRIEU %>% ungroup()
    write_csv(trimai, paste0(resultsdirEU, "trimaiY.csv"))
    write_csv(TRIEUall, paste0(resultsdirEU, "trimaiYall.csv"))
  }
}

print("-----")
print("Concluding 06_tau.R")
print("-----")