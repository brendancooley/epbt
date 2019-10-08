tauUSi <- tau %>% filter(i_iso3=="USA") %>% select(j_iso3, tau)
colnames(tauUSi) <- c("iso3", "tauExp")
tauUSj <- tau %>% filter(j_iso3=="USA") %>% select(i_iso3, tau)
colnames(tauUSj) <- c("iso3", "tauImp")

tauUS <- left_join(tauUSi, tauUSj)

tauUSPlot <- ggplot(tauUS, aes(x=tauImp, y=tauExp, label=iso3)) +
  geom_point() +
  geom_text_repel() +
  xlim(1,max(tauUS$tauImp)) +
  ylim(1,max(tauUS$tauImp)) +
  xlab('Trade Restrictiveness') +
  ylab('Market Access') +
  geom_abline(slope=1, lty='dashed') +
  annotate("text", x=max(tauUS$tauImp) - 1, y=max(tauUS$tauImp) - .8, label="'fair' trade", angle=45, size=5) +
  ggtitle(paste0('U.S. Trade Restrictiveness and Market Access, ', Y)) +
  coord_fixed() +
  theme_classic()