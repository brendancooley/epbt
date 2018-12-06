trimaiY <- left_join(trimaiY, gdp)
trimaiY <- left_join(trimaiY, pop)

trimaiY$gdppc <- trimaiY$gdp / trimaiY$pop

# TRI versus GDPPC
triIncome <- ggplot(data=trimaiY, aes(x=gdppc, y=TRI, label=iso3))  +
  geom_smooth(method='lm', lty=2, se=FALSE) +
  geom_point() +
  geom_text_repel(size=3) +
  xlab('GDP Per Capita') +
  ylab('Trade Restrictiveness Index') +
  ggtitle(paste0('National Income and Structural \n Trade Restrictivenesss, ', Y)) +
  theme_classic()

# Tariffs versus GDPPC
tarAggYC <- tar %>% group_by(j_iso3) %>%
  summarise(wtar=weighted.mean(wtar, val))
colnames(tarAggYC) <- c("iso3", "wtar")

trimaiY <- left_join(trimaiY, tarAggYC)
trimaiY$wtar <- trimaiY$wtar + 1

tarIncome <- ggplot(data=trimaiY, aes(x=gdppc, y=wtar, label=iso3))  +
  geom_smooth(method='lm', lty=2, se=FALSE) +
  geom_point() +
  geom_text_repel(size=3) +
  xlab('GDP Per Capita') +
  ylab('Weighted Ad Valorem Tariff Rate') +
  ggtitle(paste0('National Income and Ad Valorem \n Tariff Rates, ', tarYval)) +
  theme_classic()