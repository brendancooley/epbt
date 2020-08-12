trimaiPlot <- ggplot(data=trimaiY, aes(x=TRI, y=MAI, label=iso3)) +
  geom_point() +
  geom_text_repel(size=2.5) +
  xlab('Trade Restrictiveness Index') +
  ylab('Market Access Index') +
  ggtitle(paste0('Trade Restrictiveness and Market Access, ', Y)) +
  coord_fixed() +
  theme_classic()