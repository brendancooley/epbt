### TODO ###

# why can measure show up less than one?
  # controlling the scale on the relative price indices might work
  # simple solution: just choose scale parameter such that tau almost always positive
# Korea and Japan are outliers because they're importing a lot of (presumably) cheap intermediates that don't show up in EIU data
# Producer price indices? Trick is we need to pull out tradeable portion
  # is it possible to just use trade in final goods?
  # problem is that we don't have dyadic intermediates imports for OECD IOTS

# Change sigma to theta

### SETUP ###

rm(list=ls())
libs <- c('tidyverse', 'latex2exp', 'ggrepel', 'ggthemes', "scales")
sapply(libs, require, character.only = TRUE)

sourceFiles <- list.files("source/")
for (i in sourceFiles) {
  source(paste0("source/", i))
}

# Y <- 2011

tau <- function(Lji, Lii, delta, Pj, Pi, sigma) {
  return((Lji / Lii)^(1/(1-sigma)) * Pj / Pi * 1 / delta)
}

sigma <- 6
sigmaAlt <- 11
write_csv(sigma %>% as.data.frame(), "clean/sigma.csv")
write_csv(sigmaAlt %>% as.data.frame(), "clean/sigmaAlt.csv")

Y <- 2005

### DATA ###

# flows and predicted costs
X <- read_csv('clean/delta.csv') %>% filter(year==Y)

# prices
P <- read_csv('clean/priceIndex.csv') %>% select(iso3, year, P) %>% filter(year==Y)
Tshare <- read_csv('clean/priceIndex.csv') %>% select(iso3, year, Tshare) %>% filter(year==Y)

# gross consumption
gc <- read_csv("clean/gc.csv") %>% filter(year==Y)
gc$gc <- gc$gc * 1000
colnames(gc)[colnames(gc)=="gc"] <- "j_tot_exp"

# gdp
gdp <- read_csv("clean/gdp.csv") %>% filter(year==Y)
gdp$gdp <- gdp$gdp * 1000
gdp <- left_join(gdp, Tshare)
gdp$gdpS <- gdp$gdp * (1 - gdp$Tshare)
gdp <- gdp %>% select(iso3, year, gdpS)
colnames(gdp)[colnames(gdp)=="gdpS"] <- "j_gdpS"

# get home_exp and own share
X <- left_join(X, gc, by=c("year"="year", "j_iso3"="iso3"))
colnames(gc)[colnames(gc)=="j_tot_exp"] <- "i_tot_exp"
X <- left_join(X, gc, by=c("year"="year", "i_iso3"="iso3"))
X$delta <- X$avc
X$val <- X$fob

# correct for tradable shares
X <- left_join(X, gdp, by=c("year"="year", "j_iso3"="iso3"))
colnames(gdp)[colnames(gdp)=="j_gdpS"] <- "i_gdpS"
X <- left_join(X, gdp, by=c("year"="year", "i_iso3"="iso3"))
X$j_gcT <- X$j_tot_exp - X$j_gdpS
X$i_gcT <- X$i_tot_exp - X$i_gdpS

Ximp <- X %>% group_by(i_iso3, year) %>%
  summarise(i_tot_imp=sum(fob),
            i_gcT=mean(i_gcT))

# Ximp <- left_join(Ximp, gc, by=c("i_iso3"="iso3", "year"="year"))
# Ximp <- left_join(Ximp, gdp, by=c("i_iso3"="iso3", "year"="year"))
Ximp$i_home_expT <- Ximp$i_gcT - Ximp$i_tot_imp
# Ximp$i_home_expT <- Ximp$i_home_exp - Ximp$gdpS
Ximp <- Ximp %>% select(i_iso3, year, i_home_expT)

X <- left_join(X, Ximp, by=c("i_iso3", "year"))
X %>% filter(j_iso3=="JPN")

# calculate shares of total tradable expenditure
X$Lji <- X$val / X$j_gcT
X$Lii <- X$i_home_expT / X$i_gcT

# append price indices
colnames(P) <- c("i_iso3", "year", "Pi")
X <- left_join(X, P)
colnames(P) <- c("j_iso3", "year", "Pj")
X <- left_join(X, P)

X$tau <- tau(X$Lji, X$Lii, X$delta, X$Pj, X$Pi, sigma)
X$tauAlt <- tau(X$Lji, X$Lii, X$delta, X$Pj, X$Pi, sigmaAlt)

Xtau <- X %>% select(i_iso3, j_iso3, year, tau, tauAlt)

# export
write_csv(Xtau, "results/tauY.csv")


# calculate TRI and MAI
# gc weights, reflects value of markets, not value of trade
TRI <- X %>% filter(i_iso3 != j_iso3) %>% group_by(j_iso3, year) %>%
  summarise(
    tau=weighted.mean(tau, i_gcT, na.rm = T)
  )
TRI$i_iso3 <- "TRI"
TRI %>% filter(year==2011) %>% print(n=30)

# calculate TRI and MAI
MAI <- X %>% filter(i_iso3 != j_iso3) %>% group_by(i_iso3, year) %>%
  summarise(
    tau=weighted.mean(tau, j_gcT, na.rm=T)
  )
MAI$j_iso3 <- "MAI"
MAI %>% filter(year==2011) %>% print(n=30)



### PLOTS ###
tauHM <- bind_rows(list(Xtau, TRI, MAI))
tauHMY <- tauHM %>% filter(year==Y)

write_csv(tauHMY, "results/tauHMY.csv")

# TRI and MAI
trimai <- left_join(TRI %>% select(j_iso3, year, tau), MAI %>% select(i_iso3, year, tau), by=c("j_iso3"="i_iso3", "year")) %>% ungroup()
colnames(trimai) <- c("iso3", "year", "TRI", "MAI")
trimaiY <- trimai %>% filter(year==Y)
trimaiY %>% print(n=40)

write_csv(trimaiY, "results/trimaiY.csv")