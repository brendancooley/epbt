freight <- read_csv("estimation/clean/freight.csv")
freight$avc <- freight$adv + 1
freight$cyid <- paste0(freight$j_iso3, "-", freight$year)

delta$cyid <- paste0(delta$j_iso3, "-", delta$year)
delta$dpred <- delta$avc

fcyid <- freight$cyid
deltaVal <- delta %>% filter(cyid %in% fcyid)

freight$dobs <- freight$avc

deltaVal <- left_join(deltaVal, freight, by=c("i_iso3", "j_iso3", "year"))

deltaValY <- deltaVal %>% filter(year==Y, !is.na(dobs))
dvyCHL_NZL <- deltaValY %>% filter(j_iso3 %in% c("NZL", "CHL")) # NZL and CHL observations for out of sample mae

freightCV <- ggplot(deltaValY, aes(x=dobs, y=dpred, label=i_iso3, color=j_iso3)) +
  geom_point(size=1.5) +
  geom_text_repel(size=2) +
  geom_abline(slope=1, lty='dashed') +
  xlim(1,1.2) +
  ylim(1,1.2) +
  scale_colour_tableau("Tableau 20") +
  ggtitle(paste0('Factual and Predicted Freight Costs, ', Y)) +
  ylab("Observed") +
  xlab("Predicted") +
  guides(color=guide_legend(title="Importer")) +
  theme_classic()