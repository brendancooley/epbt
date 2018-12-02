### TODOs ###

# calculate tradable shares and plot versus gdppc

# P is a "sigma"-norm and norms are homogenous functions, 
# so increasing prices by a factor of lambda leads the price index to increase by a factor of lambda

### SETUP ###

# rm(list=ls())
libs <- c('tidyverse', 'R.utils', 'countrycode', 'ggrepel', 'stringr')
sapply(libs, require, character.only = TRUE)

sourceFiles <- list.files("source/")
for (i in sourceFiles) {
  source(paste0("source/", i))
}

### DATA ###

ccodesAll <- read_csv("data/flows/codes.csv") %>% pull(iso3)
ccodes <- read_csv("clean/ccodes.csv") %>% pull(.)
icpCodes <- read_csv("data/prices/icpCodes.csv")

# match classification codes and append tradable indicators
icpCodes2005 <- icpCodes %>% select(`2005`, `2011`, tradable, aggregate)
icpCodes2011 <- icpCodes %>% select(`2011`, tradable, aggregate)

icp2005 <- read_csv("data/prices/prices2005ICP.csv", col_types = list(`Classification Code`=col_character()))
icp2005 <- left_join(icp2005, icpCodes2005, by=c("Classification Code"="2005"))
icp2011 <- read_csv("data/prices/prices2011ICP.csv")
icp2011 <- left_join(icp2011, icpCodes2011, by=c("Classification Code"="2011"))

colnames(icp2005)[colnames(icp2005)=="2005 [YR2005]"] <- "val"
colnames(icp2011)[colnames(icp2011)=="2011 [YR2011]"] <- "val"

icp2005$`Classification Code` <- icp2005$`2011`
icp2005 <- icp2005 %>% select(-one_of(c("2011")))

icp2005$year <- 2005
icp2011$year <- 2011

icp <- bind_rows(icp2005, icp2011)

icpClass <- icp %>% select(`Classification Name`, `Classification Code`) %>% unique()
icpSeries <- icp %>% select(`Series Name`, `Series Code`) %>% unique()

# clean up columns
icp <- icp %>% select(year, `Country Code`, `Classification Code`, `Series Code`, val, tradable, aggregate)
colnames(icp) <- c("year", "iso3", "classification", "series", "val", "tradable", "aggregate")

# fix Russia 2005 (use OECD stats)
icp$iso3 <- ifelse(icp$iso3=="RU1", "RUS", icp$iso3)
icp <- icp %>% filter(!iso3=="RU2")

# filter country aggregates
icp <- icp %>% filter(iso3 %in% ccodesAll)


### Calcualte Price Indices ###

# gdp for EU weights
GDPdata <- icp %>% filter(series %in% c("CD", "S04"), classification=="C01") %>% select(year, iso3, val)
colnames(GDPdata) <- c("year", "iso3", "gdp")
GDPdata$gdp <- ifelse(GDPdata$year==2005, GDPdata$gdp / 1000000000, GDPdata$gdp)

# population data
POPdata <- icp %>% filter(series %in% c("POP", "S12"), classification=="C01") %>% select(year, iso3, val)
colnames(POPdata) <- c("year", "iso3", "pop")
POPdata$pop <- ifelse(POPdata$year==2005, POPdata$pop / 1000000, POPdata$pop)

# get expenditure shares and relative price levels (different series codes for 2005/2011)
Pdata <- icp %>% filter(series %in% c("GD.ZS", "PX.WL", "S02", "S08"), aggregate==0)
Pdata$series <- ifelse(Pdata$series %in% c("GD.ZS", "S02"), "expShare", Pdata$series)
Pdata$series <- ifelse(Pdata$series %in% c("PX.WL", "S08"), "priceLevel", Pdata$series)
Pdata <- Pdata %>% spread(series, val)

# price of tradables
PdataT <- Pdata %>% filter(tradable==1)

Pall <- PdataT %>% group_by(year, iso3) %>%
  summarise(P=weighted.mean(priceLevel, expShare),
            Tshare=sum(expShare))
Pall <- left_join(Pall, GDPdata)
Pall <- left_join(Pall, POPdata)

Pall$iso3 <- mapEU(Pall$iso3, Pall$year)
Pall$iso3 <- ifelse(Pall$iso3 %in% ccodes, Pall$iso3, "ROW")

Pall <- Pall %>% filter(!is.na(gdp) & !is.na(P))

P <- Pall %>% group_by(year, iso3) %>%
  summarise(P=weighted.mean(P, gdp),
            Tshare=weighted.mean(Tshare, gdp)/100,
            pop=sum(pop),
            gdp=sum(gdp))
P$gdppc <- P$gdp / P$pop

### EXPORT ###

# price indices
write_csv(P, "clean/priceIndex.csv")

# population
pop <- P %>% select(year, iso3, pop)
write_csv(pop, "clean/pop.csv")

### PLOTS ###

P %>% filter(year==2005) %>% print(n=50)

Y <- 2011
PY <- P %>% filter(year==Y)
PY %>% print(n=50)


ggplot(P, aes(x=gdppc, y=P, label=iso3)) + 
  geom_point() +
  geom_text_repel(size=2) +
  # geom_hline(yintercept=1, lty=2) +
  ylim(50, 200) +
  xlab('GDP Per Capita') +
  ylab('Price Index') +
  ggtitle(paste0('Price Indices and Per Capita National Income ', Y)) +
  theme_classic() +
  facet_wrap(~year)

ggplot(P, aes(x=gdppc, y=Tshare, label=iso3)) + 
  geom_point() +
  geom_text_repel() +
  # geom_hline(yintercept=1, lty=2) +
  ylim(0, 1) +
  xlab('GDP Per Capita') +
  ylab('Share of Tradables in Consumer Expenditure') +
  ggtitle(paste0('Tradable Shares, ', Y)) +
  theme_classic() +
  facet_wrap(~year)
