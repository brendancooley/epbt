### TODOs ###

# unify years by filling in tariff data or extrapolating price data

# Currently, tariffs from 2004, ntm and pta from 2005, taus from 2005 (with the exception of EU, where ntm from 2012)
# trade value weights on regression?

### SETUP ###

rm(list=ls())
libs <- c('tidyverse')
sapply(libs, require, character.only = TRUE)

sourceFiles <- list.files("source/")
for (i in sourceFiles) {
  source(paste0("source/", i))
}

source("params.R")

### DATA ###

ptaY <- read_csv("clean/ptaY.csv") %>% select(-year)
ntmY <- read_csv("clean/ntmY.csv") %>% select(-year)
tarY <- read_csv("clean/tarY.csv") %>% select(-year, -val)

tauY <- read_csv("results/tauY.csv") %>% select(-year) %>% filter(!is.na(tau))

C <- left_join(tauY, ptaY)
C$pta <- ifelse(is.na(C$pta), 0, 1)
  
C <- left_join(C, ntmY)

C <- left_join(C, tarY)
C$wtar <- C$wtar + 1

# filter missing countries
drop <- c("KOR", "ZAF", "ROW")
C <- C %>% filter(!(i_iso3 %in% drop) & !(j_iso3 %in% drop))

C$j_iso3 <- as.factor(C$j_iso3)
C$i_iso3 <- as.factor(C$i_iso3)

### MODEL ###

model <- lm(tau ~ wtar + pta + core + health_safety + other + j_iso3 + i_iso3, data=C)
# model <- lm(tau ~ wtar + pta + core + health_safety + other, data=C)
summary(model)
coef(model)[3] %>% as.numeric() %>% round(2) * 100

### COST COMPARISONS ###

delta <- read_csv("clean/delta.csv") %>% filter(year==Y) %>% select(i_iso3, j_iso3, avc)

C <- left_join(C, delta)

write_csv(C, "results/correlates.csv")

# heterogeneity between and across governments
ggplot(C, aes(x=tau)) +
  geom_line(stat="density", size=1) +
  theme_classic() +
  facet_wrap(~j_iso3)

