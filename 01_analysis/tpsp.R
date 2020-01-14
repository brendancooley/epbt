print("-----")
print("Starting tpsp.R")
print("-----")

library(tidyverse)
library(countrycode)
library(cshapes)
library(reshape2)

args <- commandArgs(trailingOnly=TRUE)
if (is.null(args) | identical(args, character(0))) {
  TPSP <- FALSE
  mini <- FALSE
} else {
  TPSP <- ifelse(args[1] == "True", TRUE, FALSE)
  mini <- ifelse(args[2] == "True", TRUE, FALSE)
}

source("params.R")

mkdir(expdirTPSP)

write_csv(mu %>% as.data.frame(), paste0(expdirTPSP, "mu.csv"), col_names = FALSE)
write_csv(Y %>% as.data.frame(), paste0(expdirTPSP, "year.csv"), col_names = FALSE)

### IMPORT ###

if (TPSP==FALSE) {
  
  sigma <- read_csv(paste0(resultsdir, "sigma.csv"))
  
  P <- read_csv(paste0(cleandir, "priceIndex.csv"))
  tau <- read_csv(paste0(resultsdir, "tauYTR.csv")) %>% select(-tauAlt)
  shares <- read_csv(paste0(cleandir, "sharesTR.csv"))  # in cif value
  delta <- read_csv(paste0(cleandir, "delta.csv")) %>% filter(year==Y)
  
  gc <- read_csv(paste0(cleandir, "gc.csv")) %>% filter(year==Y)
  # go <- read_csv("clean/go.csv") %>% filter(year==Y)
  gdp <- read_csv(paste0(cleandir, "gdp.csv")) %>% filter(year==Y) %>% select(-deficit, -gdp)
  deficits <- read_csv(paste0(cleandir, "dTR.csv"))
  
  ccodes <- read_csv(paste0(cleandir, "ccodes.csv"))
  
} else {
  
  sigma <- read_csv(paste0(resultsdirTPSP, "sigma.csv"))
  
  P <- read_csv(paste0(cleandirTPSP, "priceIndex.csv"))
  tau <- read_csv(paste0(resultsdirTPSP, "tauYTR.csv")) %>% select(-tauAlt)
  shares <- read_csv(paste0(cleandirTPSP, "sharesTR.csv"))  # in cif value
  delta <- read_csv(paste0(cleandirTPSP, "delta.csv")) %>% filter(year==Y)
  
  gc <- read_csv(paste0(cleandirTPSP,"gc.csv")) %>% filter(year==Y)
  # go <- read_csv("clean/go.csv") %>% filter(year==Y)
  gdp <- read_csv(paste0(cleandirTPSP, "gdp.csv")) %>% filter(year==Y) %>% select(-deficit, -gdp)
  deficits <- read_csv(paste0(cleandirTPSP, "dTR.csv"))
  
  ccodes <- read_csv(paste0(cleandirTPSP, "ccodes.csv"))
  
}


gdp <- left_join(gdp, deficits)
gdp$exp <- gdp$exp * 1000


P <- P %>% select(iso3, year, priceIndex, Tshare)
colnames(P)[colnames(P)=="iso3"] <- "j_iso3"
colnames(P)[colnames(P)=="priceIndex"] <- "j_P"

### CLEAN ###

sharesH <- shares %>% select(j_iso3, year, Ljj, j_gcT) %>% unique() %>% arrange(j_iso3)
sharesH$i_iso3 <- sharesH$j_iso3
sharesH$tau <- 1
colnames(sharesH) <- c("j_iso3", "year", "Lji", "j_gcT", "i_iso3", "tau")

shares <- shares %>% select(-Ljj)
shares <- bind_rows(shares, sharesH) %>% arrange(j_iso3, i_iso3) %>% select(-i_gcT)

shares$Lji_pc <- shares$Lji * shares$tau
# shares %>% group_by(j_iso3) %>% dplyr::summarise(test=sum(Lji*tau))
shares$Xji_cif <- shares$Lji * shares$j_gcT

# calculate revenues
shares$r_ji <- shares$Xji_cif * (shares$tau - 1) * mu
shares$Xji_cifmu <- shares$Xji_cif * shares$tau - shares$r_ji  # valuation pre customs (includes (1-mu)-share of revenues returned to producers)

r <- shares %>% group_by(j_iso3) %>%
  dplyr::summarise(r=sum(r_ji))
colnames(r) <- c("j_iso3", "r")

rvec <- r %>% arrange(j_iso3) %>% select(r)

write_csv(rvec, paste0(expdirTPSP, "r.csv"), col_names=FALSE)

# put ones in tau data frame
tauii <- cbind(ccodes, ccodes, rep(1, length(ccodes))) %>% as.data.frame()
colnames(tauii) <- c("i_iso3", "j_iso3", "tau")
tauii <- tauii %>% as_tibble()

tau <- bind_rows(tau, tauii)

gc$gc <- gc$gc * 1000
# go$go <- go$go * 1000
# gdp$gdp <- gdp$gdp * 1000
# gdp$deficit <- gdp$deficit

gdp <- left_join(gdp, gc)
# gdp <- left_join(gdp, go)

# correct gdp
colnames(r) <- c("iso3", "r")
gdp <- left_join(gdp, r)
gdp$gdp <- gdp$exp - gdp$deficit - gdp$r # recalculate deficit, revenue-implied gdp

### CONVERT TO MODEL MATRICES AND VECTORS ###

# country codes
ccodes <- shares$j_iso3 %>% unique() %>% sort() %>% as.data.frame()

write_csv(ccodes, paste0(expdirTPSP, "ccodes.csv"), col_names=FALSE)

# tradable shares (nu)
nu <- P %>% select(j_iso3, Tshare) %>% arrange(j_iso3)
colnames(nu) <- c("j_iso3", "nu")
nu <- nu %>% select(nu)

write_csv(nu, paste0(expdirTPSP, "nu.csv"), col_names=FALSE)

# trade matrix

# ensure order is alphabetical
shares <- shares %>% arrange(j_iso3, i_iso3)

xexp <- shares %>% group_by(i_iso3) %>%
  dplyr::summarise(xexp=sum(Xji_cifmu))
colnames(xexp) <- c("iso3", "xexp")  # total sales (inclusive of intermediates)

XMcif <- shares %>% 
  select(i_iso3, j_iso3, Xji_cif) %>% 
  group_by(i_iso3) %>%
  dplyr::mutate(id = row_number()) %>%
  spread(i_iso3, Xji_cif) %>%
  select(-id, -j_iso3) %>%
  as.matrix()

XMcifmu <- shares %>% 
  select(i_iso3, j_iso3, Xji_cifmu) %>% 
  group_by(i_iso3) %>%
  dplyr::mutate(id = row_number()) %>%
  spread(i_iso3, Xji_cifmu) %>%
  select(-id, -j_iso3) %>%
  as.matrix()

write_csv(XMcif %>% as.data.frame(), paste0(expdirTPSP, "Xcif.csv"), col_names=FALSE)
write_csv(XMcifmu %>% as.data.frame(), paste0(expdirTPSP, "Xcifmu.csv"), col_names=FALSE)

# national accounts
y <- gdp %>% filter(year==Y) %>% arrange(iso3) %>% select(gdp)
d <- gdp %>% filter(year==Y) %>% arrange(iso3) %>% select(deficit)

rowSums(XMcifmu) - colSums(XMcifmu)
rowSums(XMcif) - colSums(XMcif)
# d %>% print(n=50)

write_csv(d, paste0(expdirTPSP, "d.csv"), col_names=FALSE)
write_csv(y, paste0(expdirTPSP, "y.csv"), col_names=FALSE)

# trade policies
tau <- tau %>% arrange(j_iso3, i_iso3) %>% select(-year)

tauM <- tau %>% 
  select(i_iso3, j_iso3, tau) %>% 
  group_by(i_iso3) %>%
  dplyr::mutate(id = row_number()) %>%
  spread(i_iso3, tau) %>%
  select(-id, -j_iso3) %>%
  as.matrix()

write_csv(tauM %>% as.data.frame(), paste0(expdirTPSP, "tau.csv"), col_names=FALSE)

# share of intermediates in production (beta)
gdp <- left_join(gdp, xexp)
gdp$beta <- (gdp$gc - gdp$exp) / gdp$xexp
# gdp %>% print(n=50)

# consumer expenditure on tradables

gdp <- left_join(gdp, P, by=c("iso3"="j_iso3", "year"))

gdp$Eq <- (gdp$gdp + gdp$r) * gdp$Tshare + gdp$deficit
gdp$Ex <- gdp$xexp * gdp$beta
# gdp$gdp + gdp$deficit + gdp$r

# gdp$E <- gdp$Eq + gdp$Ex
# gdp$gcT <- gdp$gc - ((gdp$gdp + gdp$r) * (1 - gdp$Tshare))
gdp %>% print(n=50)

Eq <- gdp %>% arrange(iso3) %>% select(Eq)
Ex <- gdp %>% arrange(iso3) %>% select(Ex)

write_csv(Eq, paste0(expdirTPSP, "Eq.csv"), col_names=FALSE)
write_csv(Ex, paste0(expdirTPSP, "Ex.csv"), col_names=FALSE)

# beta
beta <- gdp$beta %>% mean()
# beta <- gdp$beta
write_csv(beta %>% as.data.frame(), paste0(expdirTPSP, "beta.csv"), col_names=FALSE)

# theta
write_csv(theta %>% as.data.frame(), paste0(expdirTPSP, "theta.csv"), col_names=FALSE)

# sigma
write_csv(sigma %>% as.data.frame(), paste0(expdirTPSP, "sigma.csv"), col_names=FALSE)

### minimum distances ###
ccodes <- ccodes %>% pull(.)

# dmat <- distmatrix(as.Date(paste0(Y, "-1-1")), type="mindist")
dmat <- distmatrix(as.Date(paste0(Y, "-1-1")), type="centdist")
ddf <- dmat %>% melt() %>% as_tibble()

# recode
colnames(ddf) <- c("cow1", "cow2", "centDist")
ddf$iso1 <- countrycode(ddf$cow1, "cown", "iso3c")
ddf$iso2 <- countrycode(ddf$cow2, "cown", "iso3c")

ddf$iso1 <- mapEU(ddf$iso1, Y)
ddf$iso2 <- mapEU(ddf$iso2, Y)

ddf$iso1 <- ifelse(ddf$iso1 %in% ccodes, ddf$iso1, "ROW")
ddf$iso2 <- ifelse(ddf$iso2 %in% ccodes, ddf$iso2, "ROW")

ddf <- ddf %>% select(iso1, iso2, centDist)
ddfOut <- ddf %>% dplyr::group_by(iso1, iso2) %>% dplyr::summarise(minDist=mean(centDist, na.rm=TRUE)) %>% ungroup()

dmatOut <- ddfOut %>% spread(iso2, minDist) %>% select(-iso1) %>% as.matrix()
write_csv(dmatOut %>% as.data.frame(), paste0(expdirTPSP, "cDists.csv"), col_names=FALSE)

### military spending ###
library(WDI)

milex <- WDI(indicator="MS.MIL.XPND.CD", start=Y, end=Y) %>% as_tibble()
milex$iso3 <- countrycode(milex$iso2c, "iso2c", "iso3c")
milex <- milex %>% filter(!is.na(iso3))
milex$milex <- milex$MS.MIL.XPND.CD
milex$milex <- ifelse(is.na(milex$milex), 0, milex$milex)

milex$iso3 <- mapEU(milex$iso3, milex$year)
milex$iso3 <- ifelse(milex$iso3 %in% ccodes, milex$iso3, "ROW")

milexOut <- milex %>% group_by(iso3) %>%
  dplyr::summarise(milex=sum(milex)) %>% arrange(iso3) %>% pull(milex)

write_csv(milexOut %>% as.data.frame(), paste0(expdirTPSP, "milex.csv"), col_names=FALSE)

print("-----")
print("Concluding tpsp.R")
print("-----")
