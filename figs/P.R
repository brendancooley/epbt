# library(tidyverse)
# library(ggrepel)
# 
# P <- read_csv("clean/priceIndex.csv")
# P %>% print(n=50)

plotP <- ggplot(P, aes(x=gdppc, y=priceIndex, label=iso3)) + 
  geom_point() +
  geom_text_repel(size=2) +
  geom_hline(yintercept=1, lty=2) +
  # ylim(50, 200) +
  xlab('GDP Per Capita') +
  ylab('Price Index') +
  ggtitle(paste0('Price Indices and Per Capita \n National Income, ', Y)) +
  theme_classic()

plotTshare <- ggplot(P, aes(x=gdppc, y=Tshare, label=iso3)) + 
  geom_point() +
  geom_text_repel(size=2) +
  # geom_hline(yintercept=1, lty=2) +
  # ylim(0, 1) +
  xlab('GDP Per Capita') +
  ylab('Share of Tradables in Consumer Expenditure') +
  ggtitle(paste0('Tradable Shares and Per Capita \n National Income, ', Y)) +
  theme_classic()