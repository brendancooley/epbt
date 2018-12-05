P <- read_csv("estimation/clean/priceIndex.csv") %>% filter(year==Y)

plotP <- ggplot(P, aes(x=gdppc, y=P, label=iso3)) + 
  geom_point() +
  geom_text_repel(size=3) +
  # geom_hline(yintercept=1, lty=2) +
  ylim(50, 200) +
  xlab('GDP Per Capita') +
  ylab('Price Index') +
  ggtitle(paste0('Price Indices and Per Capita \n National Income, ', Y)) +
  theme_classic()

plotTshare <- ggplot(P, aes(x=gdppc, y=Tshare, label=iso3)) + 
  geom_point() +
  geom_text_repel(size=3) +
  # geom_hline(yintercept=1, lty=2) +
  ylim(0, 1) +
  xlab('GDP Per Capita') +
  ylab('Share of Tradables in Consumer Expenditure') +
  ggtitle(paste0('Tradable Shares and Per Capita \n National Income, ', Y)) +
  theme_classic()