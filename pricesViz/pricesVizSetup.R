library(tidyverse)

# grab environment
icpBHTAgg <- read_csv("../estimation/clean/icpBHTAgg.csv")
priceIndex <- read_csv("../estimation/clean/priceIndex.csv") %>% select(iso3, priceIndex)
colnames(priceIndex) <- c("ccode", "priceIndex")

icpBHTAgg <- left_join(icpBHTAgg, priceIndex)

write_csv(icpBHTAgg, "data/icpBHTAgg.csv")