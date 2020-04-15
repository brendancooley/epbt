library(tidyverse)
library(ggplot2)
library(ggthemes)

source(paste0("../", code_dir, "params.R"))

tauHMYEUD <- read_csv(paste0(resultsdir, "EUD/", "tauY.csv"))

ccodes <- unique(tauHMYEUD$i_iso3)
# ccodesNEU <- setdiff(ccodes, EU27)

eucu <- c(EU27, "TUR") %>% sort()
eucuS <- eucu[eucu %in% ccodes]
nafta <- c("CAN", "MEX", "USA")
asean <- c("IDN", "MYS", "PHL", "SGP", "THA", "VNM")

ftas <- c(eucu, nafta, asean)
other <- setdiff(ccodes, eucu) 

tauHMYEUD$i_iso3 <- factor(tauHMYEUD$i_iso3, levels=c(eucu, other))
tauHMYEUD$j_iso3 <- factor(tauHMYEUD$j_iso3, levels=c(eucu, other))

tauHMYEUD$j_bloc <- ifelse(tauHMYEUD$j_iso3 %in% eucu, "EU", 
                         ifelse(tauHMYEUD$j_iso3 %in% nafta, "NAFTA",
                                ifelse(tauHMYEUD$j_iso3 %in% asean, "ASEAN", "Other")))

hmEU <- tauHMYEUD %>% filter(j_bloc=="EU")

i_iso3 <- unique(hmEU$i_iso3)
j_iso3 <- unique(hmEU$j_iso3)

x <- seq(0, 1, length = 25)
# hmColors <- tableau_seq_gradient_pal("Orange-Gold")(x)
hmColors <- colorRampPalette(c("white", "#BD6121"))(10)

# how does distribution of log barriers look?
# tauHMYEUD$tau_log <- log(tauHMYEUD$tau)
# 
# ggplot(tauHMYEUD, aes(x=tau)) + 
#   geom_density()
# 
# ggplot(tauHMYEUD, aes(x=tau_log)) + 
#   geom_density()
# 
# log transform actually pretty good

strokeSize <- 1

# try with breaks between groups and group labels on the far right/left axes

hmEUPlot <- ggplot(hmEU, aes(x=i_iso3, y=j_iso3, fill=tau)) +
  geom_tile(colour="white", width=.9, height=.9) +
  scale_fill_gradient(low=hmColors[1], high=hmColors[length(hmColors)], trans="log", breaks=c(min(hmEU$tau), max(hmEU$tau)), labels=c("Low", "High"), guide="colorbar") +
  annotate("segment", x=length(eucuS)+.5, xend=length(eucuS)+.5, y=.5, yend=length(eucuS)+.5, size=strokeSize) +
  labs(x='Exporter', y='Importer', title=paste0('EU Country-Level Policy Barriers, ', Y, " (Log Scale)")) +
  labs(fill="Policy Barrier") +
  theme_classic() +
  coord_fixed() +
  theme(axis.text.x=element_text(angle=60, hjust=1, size=6),
        axis.text.y=element_text(size=6),
        axis.ticks.y=element_blank(),
        axis.ticks.x=element_blank(),
        axis.line.y=element_blank(),
        axis.line.x=element_blank())
  

  # annotate("rect", xmin=.5, xmax=length(eucu) - .5, ymin=.5, ymax=length(eucu) - .5, alpha=0, color="black", size=strokeSize) +
  # annotate("rect", xmin=length(eucu)-.5, xmax=length(c(eucu, nafta)) - .5, ymin=length(eucu)-.5, ymax=length(c(eucu, nafta)) - .5, alpha=0, color="black", size=strokeSize) +
  # annotate("rect", xmin=length(c(eucu, nafta))-.5, xmax=length(c(eucu, nafta, asean)) - .5, ymin=length(c(eucu, nafta))-.5, ymax=length(c(eucu, nafta, asean)) - .5, alpha=0, color="black", size=strokeSize) +      
        
  # facet_grid(j_bloc~., scales="free")

  # annotate("segment", y=length(eucu)-.5, yend=length(eucu)-.5, x=.5, xend=length(eucu)+.5) +
  # annotate("segment", y=.5, yend=length(eucu)+.5, x=length(eucu)-.5, xend=length(eucu)-.5) +
  # annotate("segment", y=length(c(eucu, nafta))-.5, yend=length(c(eucu, nafta))-.5, x=.5, xend=length(ccodes)+.5) +
  # annotate("segment", y=.5, yend=length(ccodes)+.5, x=length(c(eucu, nafta))-.5, xend=length(c(eucu, nafta))-.5) +
  # annotate("segment", y=length(c(eucu, nafta, asean))-.5, yend=length(c(eucu, nafta, asean))-.5, x=.5, xend=length(ccodes)+.5) +
  # annotate("segment", y=.5, yend=length(ccodes)+.5, x=length(c(eucu, nafta, asean))-.5, xend=length(c(eucu, nafta, asean))-.5) +