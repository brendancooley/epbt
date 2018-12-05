ccodes <- tauHMY$i_iso3 %>% unique() %>% setdiff("TRI")

tauHMY$i_iso3 <- factor(tauHMY$i_iso3, levels=c(sort(ccodes), "TRI"))
tauHMY$j_iso3 <- factor(tauHMY$j_iso3, levels=c(sort(ccodes), "MAI"))

i_iso3 <- unique(tauHMY$i_iso3)
j_iso3 <- unique(tauHMY$j_iso3)

x <- seq(0, 1, length = 25)
hmColors <- tableau_seq_gradient_pal("Orange-Gold")(x)

hm <- ggplot(tauHMY, aes(x=i_iso3, y=j_iso3, fill=tau)) +
  geom_tile(colour="white", width=.9, height=.9) +
  scale_fill_gradient(low=hmColors[1], high=hmColors[length(hmColors)], trans="log", breaks=c(1, max(tauHMY$tau)), labels=c("Low", "High"), guide="colorbar") +
  geom_segment(y=length(i_iso3)-.5, yend=length(j_iso3)-.5, x=.5, xend=length(i_iso3)+.5) +
  geom_segment(y=.5, yend=length(j_iso3)+.5, x=length(i_iso3)-.5, xend=length(i_iso3)-.5) +
  labs(x='Exporter', y='Importer', title=paste0('Policy Barriers to Trade, ', Y, " (Log Scale)")) +
  labs(fill="Policy Barrier") +
  theme_classic() +
  coord_fixed() +
  theme(axis.text.x=element_text(angle=60, hjust=1),
        axis.ticks.y=element_blank(),
        axis.ticks.x=element_blank(),
        axis.line.y=element_blank(),
        axis.line.x=element_blank())