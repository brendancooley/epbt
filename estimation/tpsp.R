library(tidyverse)

source("params.R")

write_csv(mu %>% as.data.frame(), "tpsp_data/mu.csv", col_names = FALSE)

### IMPORT ###

if (tpspC==FALSE) {
  
  P <- read_csv("clean/priceIndex.csv")
  tau <- read_csv("results/tauYTR.csv") %>% select(-tauAlt)
  shares <- read_csv("clean/sharesTR.csv")  # in cif value
  delta <- read_csv("clean/delta.csv") %>% filter(year==Y)
  
  gc <- read_csv("clean/gc.csv") %>% filter(year==Y)
  # go <- read_csv("clean/go.csv") %>% filter(year==Y)
  gdp <- read_csv("clean/gdp.csv") %>% filter(year==Y) %>% select(-deficit, -gdp)
  deficits <- read_csv("clean/dTR.csv")
  
  ccodes <- read_csv("clean/ccodes.csv")
  
} else {
  
  P <- read_csv("clean/priceIndexTPSP.csv")
  tau <- read_csv("results/tauYTRTPSP.csv") %>% select(-tauAlt)
  shares <- read_csv("clean/sharesTRTPSP.csv")  # in cif value
  delta <- read_csv("clean/deltaTPSP.csv") %>% filter(year==Y)
  
  gc <- read_csv("clean/gcTPSP.csv") %>% filter(year==Y)
  # go <- read_csv("clean/go.csv") %>% filter(year==Y)
  gdp <- read_csv("clean/gdpTPSP.csv") %>% filter(year==Y) %>% select(-deficit, -gdp)
  deficits <- read_csv("clean/dTRTPSP.csv")
  
  ccodes <- read_csv("clean/ccodesTPSP.csv")
  
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
shares %>% group_by(j_iso3) %>% summarise(test=sum(Lji*tau))
shares$Xji_cif <- shares$Lji * shares$j_gcT

# calculate revenues
shares$r_ji <- shares$Xji_cif * (shares$tau - 1) * mu
shares$Xji_cifmu <- shares$Xji_cif * shares$tau - shares$r_ji  # valuation pre customs (includes (1-mu)-share of revenues returned to producers)

r <- shares %>% group_by(j_iso3) %>%
  summarise(r=sum(r_ji))
colnames(r) <- c("j_iso3", "r")

rvec <- r %>% arrange(j_iso3) %>% select(r)

write_csv(rvec, "tpsp_data/r.csv", col_names=FALSE)

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

write_csv(ccodes, "tpsp_data/ccodes.csv", col_names=FALSE)

# tradable shares (nu)
nu <- P %>% select(j_iso3, Tshare) %>% arrange(j_iso3)
colnames(nu) <- c("j_iso3", "nu")
nu <- nu %>% select(nu)

write_csv(nu, "tpsp_data/nu.csv", col_names=FALSE)

# trade matrix

# ensure order is alphabetical
shares <- shares %>% arrange(j_iso3, i_iso3)

xexp <- shares %>% group_by(i_iso3) %>%
  summarise(xexp=sum(Xji_cifmu))
colnames(xexp) <- c("iso3", "xexp")  # total sales (inclusive of intermediates)

XMcif <- shares %>% 
  select(i_iso3, j_iso3, Xji_cif) %>% 
  group_by(i_iso3) %>%
  mutate(id = row_number()) %>%
  spread(i_iso3, Xji_cif) %>%
  select(-id, -j_iso3) %>%
  as.matrix()

XMcifmu <- shares %>% 
  select(i_iso3, j_iso3, Xji_cifmu) %>% 
  group_by(i_iso3) %>%
  mutate(id = row_number()) %>%
  spread(i_iso3, Xji_cifmu) %>%
  select(-id, -j_iso3) %>%
  as.matrix()

write_csv(XMcif %>% as.data.frame(), "tpsp_data/Xcif.csv", col_names=FALSE)
write_csv(XMcifmu %>% as.data.frame(), "tpsp_data/Xcifmu.csv", col_names=FALSE)

# national accounts
y <- gdp %>% filter(year==Y) %>% arrange(iso3) %>% select(gdp)
d <- gdp %>% filter(year==Y) %>% arrange(iso3) %>% select(deficit)

rowSums(XMcifmu) - colSums(XMcifmu)
rowSums(XMcif) - colSums(XMcif)
d %>% print(n=50)

write_csv(d, "tpsp_data/d.csv", col_names=FALSE)
write_csv(y, "tpsp_data/y.csv", col_names=FALSE)

# trade policies
tau <- tau %>% arrange(j_iso3, i_iso3) %>% select(-year)

tauM <- tau %>% 
  select(i_iso3, j_iso3, tau) %>% 
  group_by(i_iso3) %>%
  mutate(id = row_number()) %>%
  spread(i_iso3, tau) %>%
  select(-id, -j_iso3) %>%
  as.matrix()

write_csv(tauM %>% as.data.frame(), "tpsp_data/tau.csv", col_names=FALSE)

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

write_csv(Eq, "tpsp_data/Eq.csv", col_names=FALSE)
write_csv(Ex, "tpsp_data/Ex.csv", col_names=FALSE)

# beta
beta <- gdp$beta %>% mean()
# beta <- gdp$beta
write_csv(beta %>% as.data.frame(), "tpsp_data/beta.csv", col_names=FALSE)

# theta
write_csv(theta %>% as.data.frame(), "tpsp_data/theta.csv", col_names=FALSE)
