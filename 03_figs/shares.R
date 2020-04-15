# library(tidyverse)
# 
# shares <- read_csv("clean/shares.csv")
# source("params.R")

sharesH <- shares %>% select(j_iso3, year, Ljj, j_gcT) %>% unique()
sharesH$i_iso3 <- sharesH$j_iso3
colnames(sharesH) <- c("j_iso3", "year", "Lji", "j_gcT", "i_iso3")
sharesH$tau <- 1

shares <- shares %>% select(-Ljj)
shares <- bind_rows(shares, sharesH)

shares <- shares %>% filter(j_iso3 != ROWname)
# shares %>% filter(i_iso3=="ROW")
shares$i_gcT <- ifelse(shares$i_iso3 == ROWname, 0, shares$i_gcT)  # position ROW at end of list
shares$i_gcT <- ifelse(is.na(shares$i_gcT), shares$j_gcT, shares$i_gcT)

shares$Lji_pc <- shares$Lji * shares$tau

# shares %>% arrange(j_iso3)

sharesA <- shares
sharesA <- sharesA %>% arrange(j_gcT, i_gcT)
# sharesA %>% filter(i_iso3 == j_iso3) %>% arrange(i_iso3) %>% print(n=50)

# color palette
# https://picular.co/kings%20canyon
highlight <- "#BD6121"
gray <- "#808080"
lightgray <- "#DCDCDC"
whitesmoke <- "#F5F5F5"

sharesA$color <- ifelse(as.numeric(rownames(sharesA)) %% 2 == 0, lightgray, whitesmoke)
sharesA$color <- ifelse(sharesA$i_iso3==sharesA$j_iso3, highlight, sharesA$color)
# shares$i_iso3 <- as.factor(shares$i_iso3)

sharesA$j_iso3 <- fct_reorder(sharesA$j_iso3, sharesA$j_gcT)
sharesA$i_iso3 <- fct_reorder(sharesA$i_iso3, sharesA$i_gcT)

# sharesA %>% group_by(j_iso3) %>% summarise(test=sum(Lji))

subtF <- "Orange bars depict proportion of tradable expenditure spent on goods produced locally."
sharesF <- ggplot(data=sharesA, aes(x=j_iso3, y=Lji_pc, fill=interaction(i_iso3, j_iso3))) +
  geom_bar(stat="identity", width=.75, color="white") +
  scale_fill_manual(values=sharesA$color) +
  coord_flip() +
  labs(y="Market Share", x="Importer", title=paste("Home Bias in Consumption,", Y)) +
  theme_classic() +
  guides(fill=FALSE)

### COUNTERFACTUAL EXPENDITURE SHARES ##

worldGDP <- sharesH$j_gcT %>% sum(na.rm=T)
sharesA$LjiCF <- sharesA$i_gcT / worldGDP

subtCF <- "Orange bars depict proportion of tradable expenditure spent on goods produced locally."
sharesCF <- ggplot(data=sharesA, aes(x=j_iso3, y=LjiCF, fill=interaction(i_iso3, j_iso3))) +
  geom_bar(stat="identity", width=.75, color="white") +
  scale_fill_manual(values=sharesA$color) +
  coord_flip() +
  labs(y="Market Share", x="Importer", title="Counterfactual Baseline") +
  theme_classic() +
  guides(fill=FALSE)


