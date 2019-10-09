# library(tidyverse)
# library(ggplot2)
# library(ggrepel)
# library(ggthemes)
# 
# freight <- read_csv("clean/freight.csv")
# delta <- read_csv("clean/delta.csv")
# Y <- 2011
# freight %>% filter(j_iso3 == "AUS")

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
dvyUSA_AUS <- deltaValY %>% filter(j_iso3 %in% c("USA", "AUS"))

maxLim <- max(c(deltaValY$dobs, deltaValY$dpred))
pointSize <- 1.5

freightCV <- ggplot(data=dvyCHL_NZL, aes(x=dobs, y=dpred)) +
  geom_point(data=dvyUSA_AUS, alpha=.25, size=pointSize) +
  geom_point(size=pointSize) +
  # geom_text_repel(aes(label=i_iso3), size=3) +
  geom_abline(slope=1, lty='dashed') +
  xlim(1, maxLim) +
  ylim(1, maxLim) +
  scale_colour_tableau("Tableau 20") +
  ggtitle(paste0('Factual and Predicted Freight Costs, ', Y)) +
  ylab("Observed") +
  xlab("Predicted") +
  coord_fixed() +
  guides(color=guide_legend(title="Importer")) +
  theme_classic()
