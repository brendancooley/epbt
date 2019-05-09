library(tidyverse)

### IMPORT ###

P <- read_csv("clean/priceIndex.csv")
tau <- read_csv("results/tauY.csv") %>% select(-tauAlt)
shares <- read_csv("clean/shares.csv")  # in cif value
delta <- read_csv("clean/delta.csv") %>% filter(year==2011)

gc <- read_csv("clean/gc.csv") %>% filter(year==2011)
gdp <- read_csv("clean/gdp.csv") %>% filter(year==2011)

ccodes <- read_csv("clean/ccodes.csv")

P <- P %>% select(iso3, year, priceIndex)
colnames(P)[colnames(P)=="iso3"] <- "j_iso3"
colnames(P)[colnames(P)=="priceIndex"] <- "j_P"

source("params.R")

### CLEAN ###

sharesH <- shares %>% select(j_iso3, year, Ljj, j_gcT) %>% unique()
sharesH$i_iso3 <- sharesH$j_iso3
colnames(sharesH) <- c("j_iso3", "year", "Lji", "j_gcT", "i_iso3")

shares <- shares %>% select(-Ljj)
shares <- bind_rows(shares, sharesH) %>% arrange(j_iso3, i_iso3) %>% select(-i_gcT)

# shares <- shares %>% filter(j_iso3 != "ROW")
# shares %>% filter(i_iso3==j_iso3)
shares$Xji <- shares$Lji * shares$j_gcT

# put ones in tau data frame
tauii <- cbind(ccodes, ccodes, rep(1, length(ccodes))) %>% as.data.frame()
colnames(tauii) <- c("i_iso3", "j_iso3", "tau")
tauii <- tauii %>% as_tibble()

tau <- bind_rows(tau, tauii)

gc$gc <- gc$gc * 1000
gdp$exp <- gdp$exp * 1000
gdp$gdp <- gdp$gdp * 1000
gdp$deficit <- gdp$deficit * 1000

gdp <- left_join(gdp, gc)
# gdp %>% print(n=50)

### CONVERT TO MODEL MATRICES AND VECTORS ###

# trade matrix

# ensure order is alphabetical
shares <- shares %>% arrange(j_iso3, i_iso3)

XM <- shares %>% 
  select(i_iso3, j_iso3, Xji) %>% 
  group_by(i_iso3) %>%
  mutate(id = row_number()) %>%
  spread(i_iso3, Xji) %>%
  select(-id, -j_iso3) %>%
  as.matrix()

# ensure order is alphabetical
tau <- tau %>% arrange(j_iso3, i_iso3)

tauM <- tau %>%
  select(i_iso3, j_iso3, tau) %>%
  group_by(i_iso3) %>%
  mutate(id = row_number()) %>%
  spread(i_iso3, tau) %>%
  select(-id, -j_iso3) %>%
  as.matrix()

### OLD EXPORT ###

# X <- left_join(P, tau)



delta <- delta %>% select(i_iso3, j_iso3, year, avc)

X <- left_join(shares, P)
X <- left_join(X, tau)
X <- left_join(X, delta)

X$tau <- ifelse(is.na(X$tau), 1, X$tau)
X$avc <- ifelse(is.na(X$avc), 1, X$avc)

X %>% group_by(j_iso3) %>%
  summarise(test=sum(Lji*tau))

X$Xji_pc <- X$Lji * X$tau * X$j_gcT

# X %>% group_by(j_iso3) %>% 
#   summarise(test=sum(Xji_pc),
#             test2=sum(Lji*tau))
# X

X <- X %>% arrange(j_iso3, i_iso3) %>% select(i_iso3, j_iso3, year, everything())
X
X %>% filter(i_iso3==j_iso3) %>% print(n=50)

write_csv(X, "~/Dropbox (Princeton)/2_Projects/tpsp/data/tpsp.csv")
