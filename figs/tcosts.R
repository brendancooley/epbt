# library(tidyverse)
# library(ggridges)
# correlates <- read_csv("results/correlates.csv")
# 
# source("params.R")

CP <- correlates %>% gather(tau, wtar, avc, key="cost_type", value="cost") %>% select(i_iso3, j_iso3, cost_type, cost)

# convert to dyads
CPij <- CP
colnames(CPij)[colnames(CPij)=="cost"] <- "cost_ji"
CPji <- CP
colnames(CPji)[colnames(CPji) %in% c("i_iso3", "j_iso3", "cost")] <- c("j_iso3", "i_iso3", "cost_ij")

# filter duplicates
CPdyads <- left_join(CPij, CPji)
CPdyads <- CPdyads %>% rowwise() %>% mutate(dyad = paste(sort(c(i_iso3, j_iso3)), collapse = "-"))
CPdyads$id <- paste0(CPdyads$dyad, "-", CPdyads$cost_type)
CPdyads$dups <- duplicated(CPdyads$id)
CPdyads <- CPdyads %>% filter(dups) %>% select(dyad, cost_type, cost_ji, cost_ij)

### DISTRIBUTION PLOT ###

# calculate means
CP <- CP %>% group_by(cost_type) %>% mutate(meanC=mean(cost)) %>% ungroup()

# CPP <- CP %>% filter(cost_type=="tau")
# CPF <- CP %>% filter(cost_type=="avc")
# CPT <- CP %>% filter(cost_type=="wtar")

CP$cost_type <- ifelse(CP$cost_type=="tau", "A: Policy Barriers",
                       ifelse(CP$cost_type=="wtar", "C: Tariffs", "B: Freight Costs"))
CP <- CP %>% mutate(cost_type=reorder(cost_type, -meanC))

tCostsPlot <- ggplot(CP, aes(x=cost)) +
  geom_line(stat="density", size=1) +
  theme_classic() +
  geom_vline(aes(xintercept=meanC), lty=2) +
  facet_wrap(~cost_type, scales="free")

### JOY PLOT ###

tCostsJoy <- ggplot(CP, aes(x=cost, y=cost_type)) +
  geom_density_ridges()

### SCATTER PLOT ###

CPdyads$cost_type <- ifelse(CPdyads$cost_type=="tau", "Policy Barriers",
                            ifelse(CPdyads$cost_type=="wtar", "Tariffs", "Freight Costs"))

# convert to ad valorem
CPdyads$cost_ij <- CPdyads$cost_ij - 1
CPdyads$cost_ji <- CPdyads$cost_ji - 1
# CP %>% filter(cost_type != "tau", cost > 1.5)

# names <- c("Freight Costs", "Tariffs")
# cols <- c("#808080", bcOrange)
CPdyadsFT <- CPdyads %>% filter(cost_type!="Policy Barriers")
maxFT <- max(CPdyadsFT$cost_ij, CPdyadsFT$cost_ji, na.rm=T)

minFTP <- min(CPdyads$cost_ij, CPdyads$cost_ji, na.rm=T)
maxFTP <- max(CPdyads$cost_ij, CPdyads$cost_ji, na.rm=T)

tCostsF <- ggplot(CPdyads %>% filter(cost_type == "Freight Costs"), aes(x=cost_ji, y=cost_ij)) +
  geom_point(size=.75, alpha=.75, color="#808080") +
  geom_vline(xintercept=0, lty=2) +
  geom_hline(yintercept=0, lty=2) +
  xlim(c(0, maxFT)) +
  ylim(c(0, maxFT)) +
  labs(x="Ad Valorem Costs (i to j)", y="Ad Valorem Costs (j to i)", title="Freight Costs") +
  theme_classic()

tCostsFT <- tCostsF +
  geom_point(data=CPdyads %>% filter(cost_type=="Tariffs"), aes(color=names[2]), size=.75, color=bcOrange) +
  labs(title="Freight Costs and Tariffs (Orange)")

tCostsFTPbase <- ggplot(CPdyads %>% filter(cost_type %in% c("Freight Costs", "Tariffs")), aes(x=cost_ji, y=cost_ij)) +
  geom_point(size=.75, alpha=.75, color="#808080") +
  geom_vline(xintercept=0, lty=2) +
  geom_hline(yintercept=0, lty=2) +  
  xlim(c(minFTP, maxFTP)) +
  ylim(c(minFTP, maxFTP)) +
  theme_classic() + 
  labs(x="Ad Valorem Costs (i to j)", y="Ad Valorem Costs (j to i)", title="Trade Costs")
    
tCostsFTP <- tCostsFTPbase +
  geom_point(data=CPdyads %>% filter(cost_type=="Policy Barriers"), size=.75, color=bcOrange) +
  labs(title="Trade Costs (Policy Barriers in Orange)")
