library(tidyverse)
library(ggplot2)
library(ggrepel)
library(ggthemes)

code_dir <- "01_code/"
shiny <- FALSE
EUD <- FALSE
source(paste0("../", code_dir, "params.R"))

freight <- read_csv(paste0(cleandir, "freight.csv"))
freight_proj <- read_csv(paste0(cleandir, "freight_proj.csv"))
delta <- read_csv(paste0(cleandir, "delta.csv"))
Y <- 2011

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

# ggplot(data=freight_proj, aes(x=airshare, airshareP)) +
#   geom_point(size=.1) +
#   geom_abline(slope=1, lty='dashed') +
#   xlim(0, 1) +
#   ylim(0, 1) +
#   coord_fixed() +
#   theme_classic()
# 
# seashareM <- lm(data=freight_proj, seashare~seashareP)
# summary(seashareM)
# landshareM <- lm(data=freight_proj, landshare~landshareP)
# summary(landshareM)
