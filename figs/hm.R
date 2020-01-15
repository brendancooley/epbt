# library(tidyverse)
# library(skmeans)
# 
# source("../01_analysis/params.R")
# 
# tauHMY <- read_csv(paste0(resultsdir, "tauHMY.csv"))
# tauHMYEUD <- read_csv(paste0(resultsdirEU, "tauY.csv"))
# 
# # tauHMYEUD %>% filter(j_iso3=="AUT") %>% print(n=50)
# # tauHMYEUD %>% filter(i_iso3=="BNL") %>% print(n=50)
# # tauHMYEUD %>% filter(j_iso3=="IRL") %>% print(n=50)
# 
# EUHM <- F
# cluster <- T
# highlight <- NULL


### COMMENT ABOVE FOR PAPER ###

rectTrsp <- 0
rectColor <- "#000000CC"
rectStroke <- 1

if (EUHM == T) {
  HMD <- tauHMYEUD
} else {
  HMD <- tauHMY
}

ccodes <- HMD$j_iso3 %>% unique() %>% setdiff("MAI")

HMD$i_iso3 <- factor(HMD$i_iso3, levels=c(sort(ccodes), "TRI"))
HMD$j_iso3 <- factor(HMD$j_iso3, levels=c(sort(ccodes), "MAI"))

if (cluster==T) {
  # clean for clustering
  tauii <- cbind(ccodes, ccodes, rep(1, length(ccodes))) %>% as.data.frame()
  colnames(tauii) <- c("i_iso3", "j_iso3", "tau")
  tauii <- tauii %>% as_tibble()
  tauii$tau <- as.numeric(tauii$tau)

  tauHMK <- bind_rows(HMD, tauii)
  tauHMK <- tauHMK %>% filter(!(j_iso3 %in% c("TRI", "MAI")) & !(i_iso3 %in% c("TRI", "MAI")))
  tauHMK <- tauHMK %>% arrange(j_iso3, i_iso3) %>% select(-year, -tauAlt)
  # tauHMK %>% print(n=100)

  # convert to matrix
  tauHMKM <- tauHMK %>% group_by(i_iso3) %>%
    mutate(id = row_number()) %>%
    spread(i_iso3, tau) %>%
    select(-id, -j_iso3) %>%
    as.matrix()

  # cluster
  if (EUHM==T) {
    K <- KmeansEUD
  } else {
    K <- Kmeans
  }
  # skOut <- skmeans(tauHMKM, K, method="pclust")
  skOut <- skmeans(tauHMKM, K, method="genetic")
  
  skClusters <- cbind(ccodes, skOut$cluster) %>% as.data.frame() %>% as.tibble()
  colnames(skClusters) <- c("j_iso3", "cluster")
  skClusters$cluster <- as.numeric(skClusters$cluster)
  skClusters <- skClusters %>% arrange(cluster)
  # skClusters %>% print(n=100)

  HMD <- HMD %>% mutate(j_iso3 = fct_relevel(j_iso3, skClusters$j_iso3 %>% as.character))
  HMD <- HMD %>% mutate(i_iso3 = fct_relevel(i_iso3, skClusters$j_iso3 %>% as.character))

  breaks <- rep(0, K)
  for (i in 1:K) {
    breaks[i] <- which.max(skClusters$cluster == i)
  }
}

if (TRIMAI==F) {
  HMD <- HMD %>% filter(i_iso3 %in% ccodes, j_iso3 %in% ccodes)
}

i_iso3 <- unique(HMD$i_iso3)
j_iso3 <- unique(HMD$j_iso3)

x <- seq(0, 1, length = 25)
# hmColors <- tableau_seq_gradient_pal("Orange-Gold")(x)
hmColors <- colorRampPalette(c("white", "#BD6121"))(10)
rectTrsp <- 0
rectColor <- "#000000CC"
rectStroke <- 1

hm <- ggplot(HMD, aes(x=i_iso3, y=j_iso3, fill=tau)) +
  geom_tile(colour="white", width=.9, height=.9) +
  scale_fill_gradient(low=hmColors[1], high=hmColors[length(hmColors)], trans="log", breaks=c(min(HMD$tau), max(HMD$tau)), labels=c("Low", "High"), guide="colorbar") +
  labs(x='Exporter', y='Importer') +
  labs(fill="Policy Barrier") +
  theme_classic() +
  coord_fixed() +
  theme(axis.text.x=element_text(angle=60, hjust=1),
        axis.ticks.y=element_blank(),
        axis.ticks.x=element_blank(),
        axis.line.y=element_blank(),
        axis.line.x=element_blank())
if (cluster==T) {
  for (i in 1:K) {
    if (i!=K) {
      bi <- breaks[i]
      bip1 <- breaks[i+1]
      hm <- hm +
        annotate("rect", ymin=bi-.5, ymax=bip1-.5, xmin=bi-.5, xmax=bip1-.5, alpha=rectTrsp, color=rectColor, size=rectStroke)
    } else {
      bi <- breaks[i]
      hm <- hm +
        annotate("rect", ymin=bi-.5, ymax=length(ccodes)+.5, xmin=bi-.5, xmax=length(ccodes)+.5, alpha=rectTrsp, color=rectColor, size=rectStroke)
    }
  }
  if (EUHM==F) {
    hm <- hm + labs(title=paste0("Economic Blocs, ", Y))
  } else {
    hm <- hm + labs(title=paste0("Economic Blocs (EU Disaggregated), ", Y))
  }
} else {
  hm <- hm + labs(title=paste0('Policy Barriers to Trade, ', Y, " (Log Scale)"))
}
if (TRIMAI==T) {
  hm <- hm +
    annotate("segment", y=length(i_iso3)-.5, yend=length(j_iso3)-.5, x=.5, xend=length(i_iso3)+.5) +
    annotate("segment", y=.5, yend=length(j_iso3)+.5, x=length(i_iso3)-.5, xend=length(i_iso3)-.5)
}
if (!is.null(highlight)) {
  cc <- which(ccodes==highlight) + 1
  hm <- hm + annotate("rect", ymin=cc-.5, ymax=cc+.5, xmin=.5, xmax=length(ccodes)+.5, alpha=rectTrsp, color=rectColor, size=rectStroke)
}
