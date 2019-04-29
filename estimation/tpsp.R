library(tidyverse)

P <- read_csv("clean/priceIndex.csv")
tau <- read_csv("results/tauY.csv") %>% select(-tauAlt)
shares <- read_csv("clean/shares.csv")  # in pc value
delta <- read_csv("clean/delta.csv") %>% filter(year==2011)
# delta %>% arrange(j_iso3, i_iso3)

P <- P %>% select(iso3, year, priceIndex)
colnames(P)[colnames(P)=="iso3"] <- "j_iso3"
colnames(P)[colnames(P)=="priceIndex"] <- "j_P"

# X <- left_join(P, tau)

sharesH <- shares %>% select(j_iso3, year, Ljj, j_gcT) %>% unique()
sharesH$i_iso3 <- sharesH$j_iso3
colnames(sharesH) <- c("j_iso3", "year", "Lji", "j_gcT", "i_iso3")

shares <- shares %>% select(-Ljj)
shares <- bind_rows(shares, sharesH) %>% arrange(j_iso3, i_iso3) %>% select(-i_gcT)

shares <- shares %>% filter(j_iso3 != "ROW")
shares$Xji_pc <- shares$Lji * shares$j_gcT

delta <- delta %>% select(i_iso3, j_iso3, year, avc)

X <- left_join(shares, P)
X <- left_join(X, tau)
X <- left_join(X, delta)

X$tau <- ifelse(is.na(X$tau), 1, X$tau)
X$avc <- ifelse(is.na(X$avc), 1, X$avc)


X <- X %>% arrange(j_iso3, i_iso3) %>% select(i_iso3, j_iso3, year, everything())
X

write_csv(X, "~/Dropbox (Princeton)/2_Projects/tpsp/data/tpsp.csv")
