library(tidyverse)

source("params.R")

write_csv(mu %>% as.data.frame(), "tpsp_data/mu.csv", col_names = FALSE)

### IMPORT ###

# TODO:
  # problem is with using gdp as empirical analogue to Y and tacking on revenue...need to think this through
  # test condition (gdp$test at bottom) has the same problem, need to figure out how to disentagle these
  # Ossa2016 Eq 8...need to subtract R from expenditures to get income
  # see sheet two on notepad...need to find "missing income"
  # suggests we should use gross consumption and consumer expenditure rather than gdp, gross output

P <- read_csv("clean/priceIndex.csv")
tau <- read_csv("results/tauYTR.csv") %>% select(-tauAlt)
shares <- read_csv("clean/sharesTR.csv")  # in cif value
delta <- read_csv("clean/delta.csv") %>% filter(year==Y)

gc <- read_csv("clean/gc.csv") %>% filter(year==Y)
go <- read_csv("clean/go.csv") %>% filter(year==Y)
gdp <- read_csv("clean/gdp.csv") %>% filter(year==Y)

ccodes <- read_csv("clean/ccodes.csv")

P <- P %>% select(iso3, year, priceIndex, Tshare)
colnames(P)[colnames(P)=="iso3"] <- "j_iso3"
colnames(P)[colnames(P)=="priceIndex"] <- "j_P"


### RECOMPUTE TRADE SHARES WITH REVENUES ###

# delta$Xji <- delta$cif
# delta <- delta %>% left_join(tau)
# 
# # calculate revenues
# 
# delta$r_ji <- mu * (delta$tau - 1) * delta$Xji


### CLEAN ###

sharesH <- shares %>% select(j_iso3, year, Ljj, j_gcT) %>% unique() %>% arrange(j_iso3)
sharesH$i_iso3 <- sharesH$j_iso3
sharesH$tau <- 1
colnames(sharesH) <- c("j_iso3", "year", "Lji", "j_gcT", "i_iso3", "tau")

shares <- shares %>% select(-Ljj)
shares <- bind_rows(shares, sharesH) %>% arrange(j_iso3, i_iso3) %>% select(-i_gcT)

shares$Lji_pc <- shares$Lji * shares$tau
# shares %>% arrange(j_iso3) %>% filter(i_iso3=="AUS")
# shares %>% arrange(i_iso3) %>% filter(j_iso3=="AUS")
# shares <- shares %>% filter(j_iso3 != "ROW")
# shares %>% filter(i_iso3==j_iso3)
shares %>% group_by(j_iso3) %>% summarise(test=sum(Lji_pc))
shares$Xji <- shares$Lji * shares$j_gcT

# calculate revenues
shares$r_ji <- shares$Xji * (shares$tau - 1) * mu
# shares %>% filter(j_iso3=="IND") %>% print(n=100)

r <- shares %>% group_by(j_iso3) %>%
  summarise(r=sum(r_ji))
# r %>% print(n=100)
colnames(r) <- c("j_iso3", "r")

rvec <- r %>% arrange(j_iso3) %>% select(r)

write_csv(rvec, "tpsp_data/r.csv", col_names=FALSE)

# put ones in tau data frame
tauii <- cbind(ccodes, ccodes, rep(1, length(ccodes))) %>% as.data.frame()
colnames(tauii) <- c("i_iso3", "j_iso3", "tau")
tauii <- tauii %>% as_tibble()

tau <- bind_rows(tau, tauii)

gc$gc <- gc$gc * 1000
go$go <- go$go * 1000
gdp$exp <- gdp$exp * 1000
gdp$gdp <- gdp$gdp * 1000
gdp$deficit <- gdp$deficit * 1000

gdp <- left_join(gdp, gc)
gdp <- left_join(gdp, go)
# gdp %>% print(n=50)

# sharesT$j_gcT - sharesT$gc

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
  summarise(xexp=sum(Xji))
colnames(xexp) <- c("iso3", "xexp")  # total sales (inclusive of intermediates)
# note: some mismeasurement here because we impute home share on tradables from price data (see Korea)

test <- left_join(xexp, gdp)
colnames(P)[colnames(P)=="j_iso3"] <- "iso3"
test <- left_join(test, P)
colnames(r)[colnames(r)=="j_iso3"] <- "iso3"
test <- left_join(test, r)

test$Es <- (test$gdp + test$r) * (1 - test$Tshare)
test$goTest <- test$xexp + test$Es
test %>% select(go, goTest, everything())
test$goTest == test$go

gcT <- shares %>% group_by(j_iso3) %>% summarise(gcT=mean(j_gcT))
colnames(gcT)[colnames(gcT)=="j_iso3"] <- "iso3"
test <- left_join(test, gcT)
test$goTest2 <- test$gcT + test$Es - test$deficit  # this one works
test %>% select(go, goTest, goTest2, everything()) %>% print(n=100)
test %>% select(go, goTest, goTest2, everything()) %>% filter(go!=goTest2) %>% print(n=100)
test$goTest2
test$go

# shares %>% filter(i_iso3=="AUS")
# shares %>% filter(j_iso3=="AUS")
XM <- shares %>% 
  select(i_iso3, j_iso3, Xji) %>% 
  group_by(i_iso3) %>%
  mutate(id = row_number()) %>%
  spread(i_iso3, Xji) %>%
  select(-id, -j_iso3) %>%
  as.matrix()

write_csv(XM %>% as.data.frame(), "tpsp_data/X.csv", col_names=FALSE)

# national accounts
y <- gdp %>% filter(year==Y) %>% arrange(iso3) %>% select(gdp)
d <- gdp %>% filter(year==Y) %>% arrange(iso3) %>% select(deficit)

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
gdp$beta <- (gdp$go - gdp$gdp) / gdp$xexp

# consumer expenditure on tradables
colnames(r) <- c("iso3", "r")
gdp <- left_join(gdp, r)

gdp <- left_join(gdp, P, by=c("iso3"="j_iso3", "year"))
gdp$Eq <- (gdp$gdp + gdp$r) * gdp$Tshare
gdp$Ex <- gdp$xexp * gdp$beta
# gdp %>% print(n=50)

Eq <- gdp %>% arrange(iso3) %>% select(Eq)
Ex <- gdp %>% arrange(iso3) %>% select(Ex)

write_csv(Eq, "tpsp_data/Eq.csv", col_names=FALSE)
write_csv(Ex, "tpsp_data/Ex.csv", col_names=FALSE)

# gdp %>% print(n=100)
# gdp %>% select(iso3, xexp) %>% print(n=100)
# gdp %>% filter(iso3=="KOR")

# beta <- weighted.mean(gdp$beta, gdp$gdp)  

write_csv(gdp$beta %>% as.data.frame(), "tpsp_data/beta.csv", col_names=FALSE)

# theta
write_csv(theta %>% as.data.frame(), "tpsp_data/theta.csv", col_names=FALSE)


# TEST BAY

sharesT <- shares %>% left_join(gdp, by=c("j_iso3"="iso3", "year"))

sharesT$j_gcT
test <- sharesT %>% group_by(j_iso3) %>%
  summarise(j_gcT=mean(j_gcT),
            gc=mean(gc),
            r=sum(r_ji),
            gdp=mean(gdp),
            Tshare=mean(Tshare))
test$Es <- (test$gdp + test$deficit) * (1 - test$Tshare)
test$test <- test$gc + test$r - test$Es  # this should equal j_gcT, but j_gcT seems to be much too high atm
test$test == test$j_gcT

gdpKor <- gdp %>% filter(iso3=="KOR") %>% mutate(test=gdp+r)

gdp$test <- ((1 - gdp$beta) * gdp$xexp + (1 - gdp$Tshare) * (gdp$gdp + gdp$r)) / gdp$gdp # this should be one (TODO: problem)

gdp %>% select(test, everything()) %>% arrange(test) %>% print(n=100)

# Everything here was computed assuming that no revenue was collected
# Need to recompute share of revenue spend on tradables, home share of spending, etc, where total income is gdp + r



# colSums(XM) * (1 - gdp$beta) + (1 - nu) * r / (gdp$gdp * nu)



