### SETUP ###

rm(list=ls())

sourceFiles <- list.files("source/")
for (i in sourceFiles) {
  source(paste0("source/", i))
}

# devtools::install_github("timelyportfolio/d3treeR")
libs <- c('tidyverse', 'latex2exp', 'ggrepel', 'ggthemes', "scales", "treemap", 
          "data.tree", "jsonlite", "ggraph", "igraph", "viridis")
ipak(libs)

source("params.R")

### DATA ###

# flows and predicted costs
if (EUD==FALSE) {
  if (tpspC==FALSE) {
    X <- read_csv('clean/delta.csv') %>% filter(year==Y)
  } else {
    X <- read_csv('clean/deltaTPSP.csv') %>% filter(year==Y)
  }
} else {
  X <- read_csv('clean/deltaEUD.csv') %>% filter(year==Y)
}
# X %>% pull(j_iso3) %>% unique() %>% sort()

# prices
if (EUD==FALSE) {
  if (tpspC==FALSE) {
    P <- read_csv('clean/priceIndex.csv') %>% select(iso3, year, priceIndex) %>% filter(year==Y)
    Tshare <- read_csv('clean/priceIndex.csv') %>% select(iso3, year, Tshare) %>% filter(year==Y)
  } else {
    P <- read_csv('clean/priceIndexTPSP.csv') %>% select(iso3, year, priceIndex) %>% filter(year==Y)
    Tshare <- read_csv('clean/priceIndexTPSP.csv') %>% select(iso3, year, Tshare) %>% filter(year==Y)
  }
} else {
  P <- read_csv('clean/priceIndexEUD.csv') %>% select(iso3, year, priceIndex) %>% filter(year==Y)
  Tshare <- read_csv('clean/priceIndexEUD.csv') %>% select(iso3, year, Tshare) %>% filter(year==Y)
}

# gross consumption
if (EUD==FALSE) {
  if (tpspC==FALSE) {
    gc <- read_csv("clean/gc.csv") %>% filter(year==Y)
  } else {
    gc <- read_csv("clean/gcTPSP.csv") %>% filter(year==Y)
  }
} else {
  gc <- read_csv("clean/gcEUD.csv") %>% filter(year==Y)
}

gc$gc <- gc$gc * 1000
colnames(gc)[colnames(gc)=="gc"] <- "j_tot_exp"

# gdp
if (EUD==FALSE) {
  if (tpspC==FALSE) {
    gdp <- read_csv("clean/gdp.csv") %>% filter(year==Y)
  } else {
    gdp <- read_csv("clean/gdpTPSP.csv") %>% filter(year==Y)
  }
} else {
  gdp <- read_csv("clean/gdpEUD.csv") %>% filter(year==Y)
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

# calculate taus and lambda_iis jointly
if (tauRev==FALSE) {
  X <- X %>% tauLambda(theta, "tau", "Lii", "Ljj")
  X$LiiAlt <- X$Lii
  X$LjjAlt <- X$Ljj
  X <- X %>% tauLambda(thetaAlt, "tauAlt", "LiiAlt","LjjAlt")
} else {
  if (EUD==FALSE) {
    print('hello')
    colnames(gdpR)[colnames(gdpR)=="iso3"] <- "j_iso3"
    XgdpR <- tauLambdaRev(X, gdpR, theta, mu)
    X <- XgdpR[[1]]
    gdpR <- XgdpR[[2]]
    X$tauAlt <- X$tau
  }
}

# export trade shares (in pc value)
Xshares <- X %>% select(i_iso3, j_iso3, year, tau, Lji, Ljj, j_gcT, i_gcT)
# Xshares %>% group_by(j_iso3) %>% summarise(test1=sum(Lji*tau), test2=mean(Ljj))
# Xshares %>% summary()
# Xshares %>% filter(j_iso3=="VNM") %>% print(n=100)

if (EUD==FALSE) {
  if (tauRev==FALSE) {
    write_csv(Xshares, "clean/shares.csv")
  } else {
    if (tpspC==FALSE) {
      write_csv(Xshares, "clean/sharesTR.csv")
    } else {
      write_csv(Xshares, "clean/sharesTRTPSP.csv")
    }
  }
} else {
  write_csv(Xshares, "clean/sharesEUD.csv")
}

# export deficits
if (tauRev==TRUE) {
  d <- gdpR %>% select(j_iso3, j_deficit)
  colnames(d) <- c("iso3", "deficit")
  if (tpspC==FALSE) {
    write_csv(d, "clean/dTR.csv")
  } else {
    write_csv(d, "clean/dTRTPSP.csv")
  }
}

# export policies
Xtau <- X %>% select(i_iso3, j_iso3, year, tau, tauAlt)

if (EUD==TRUE) {
  XEU <- X %>% filter(j_iso3 %in% EU27 & i_iso3 %in% EU27)
}

# export
if (EUD==FALSE) {
  if (tauRev==FALSE) {
    write_csv(Xtau, "results/tauY.csv")
  } else {
    if (tpspC==FALSE) {
      write_csv(Xtau, "results/tauYTR.csv")
    } else {
      print('hello')
      write_csv(Xtau, "results/tauYTRTPSP.csv")
    }
  }
} else {
  write_csv(Xtau, "results/tauYEUD.csv")
}
Xtau %>% print(n=100)


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
  
}

### PLOTS ###

if (EUD==FALSE) {
  if (tpspC==FALSE) {
    tauHM <- bind_rows(list(Xtau, TRI, MAI))
    tauHMY <- tauHM %>% filter(year==Y)
    write_csv(tauHMY, "results/tauHMY.csv")
  }
} else {
  # different variables
  # tauHM <- bind_rows(list(Xtau, TRIEU, MAIEU))
  # tauHMY <- tauHM %>% filter(year==Y)
  # write_csv(tauHMY, "results/tauHMYEUD.csv")
}

# TRI and MAI

if (EUD==FALSE) {
  if (tpspC==FALSE) {
    trimai <- left_join(TRI %>% select(j_iso3, year, tau), MAI %>% select(i_iso3, year, tau), by=c("j_iso3"="i_iso3", "year")) %>% ungroup()
    colnames(trimai) <- c("iso3", "year", "TRI", "MAI")
    trimaiY <- trimai %>% filter(year==Y)
    write_csv(trimaiY, "results/trimaiY.csv")
  }
} else {
  trimai <- TRIEU %>% ungroup()
  write_csv(trimai, "results/triYEUD.csv")
}

