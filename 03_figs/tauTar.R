# library(tidyverse)
# 
# source("params.R")
# 
# correlates <- read_csv("03_results/correlates.csv")

ceiling <- 1.5
correlatesF <- correlates %>% filter(wtar < ceiling)

ggplot(data=correlatesF, aes(x=wtar, y=tau)) +
  geom_point() +
  geom_smooth(method="lm") +
  xlab('Weighted Applied Tariff Rate') +
  ylab('Structural Trade Barriers') +
  ggtitle(paste0('Tariffs and Structural Trade Barriers, ', Y)) +
  theme_classic()
