### TO-DOs ###

# Add Chile adv costs?
# Does BACI contain country groupings? Might be inferring too much openness for ROW
# aggregate Hong Kong and China?

# Note: flows takes up a lot of memory, need > 4GB

### SETUP ###

rm(list=ls())
libs <- c('tidyverse', 'R.utils', 'countrycode')
sapply(libs, require, character.only = TRUE)

sourceFiles <- list.files("source/")
for (i in sourceFiles) {
  source(paste0("source/", i))
}

startY <- 1995
endY <- 2011

# modes directory
mdir <- paste0("data/modes/")

### AGGREGATE FLOW DATA ###

flowsL <- list()

fcodes <- read_csv("data/flows/codes.csv") %>% select(i, iso3)

tick <- 1
for (i in seq(startY, endY)) {
  year <- i
  flowspath <- paste0("data/flows/", year, ".csv")
  flows <- read_csv(flowspath)
  flowsL[[tick]] <- flows
  tick <- tick + 1
}

flows <- bind_rows(flowsL)

rm(flowsL)

colnames(flows)[1] <- "year"
flows$hs2 <- substring(as.character(flows$hs6), 1, 2)

# append country iso3 codes
flows <- left_join(flows, fcodes)
colnames(flows)[colnames(flows) == 'iso3'] <- "i_iso3"
flows <- left_join(flows, fcodes, by=c("j"="i"))
colnames(flows)[colnames(flows) == 'iso3'] <- "j_iso3"

write_csv(flows, "clean/flowshs6.csv")

flowshs2 <- flows %>% group_by(year, hs2, i_iso3, j_iso3) %>% 
  summarise(val=sum(v)) %>%
  ungroup()
# summary(flowshs2)

rm(flows)

### GEOGRAPHIC DATA ###

# append distances
seadist <- read_csv('data/dists/CERDI-seadistance.csv')
cepiidist <- read_csv('data/dists/dist_cepii.csv')
cepiigeo <- read_csv('data/dists/geo_cepii.csv')

# drop duplicate entries
cepiigeo <- cepiigeo[!duplicated(cepiigeo$iso3), ]

colnames(seadist)[1:2] <- colnames(cepiidist)[1:2] <- c("i_iso3", "j_iso3")

# convert condordences 
cepiidist$i_iso3 <- ifelse(cepiidist$i_iso3 == "ROM", "ROU", cepiidist$i_iso3)  # Romania
cepiidist$j_iso3 <- ifelse(cepiidist$j_iso3 == "ROM", "ROU", cepiidist$j_iso3)  # Romania
cepiigeo$iso3 <- ifelse(cepiigeo$iso3 == "ROM", "ROU", cepiigeo$iso3)  # Romania

# Serbia and Montenegro
yug_i <- cepiidist %>% filter(i_iso3 == "YUG")
yug_j <- cepiidist %>% filter(j_iso3 == "YUG")
yug_geo <- cepiigeo %>% filter(iso3 == "YUG")

yug_i$i_iso3 <- "SRB"
cepiidist <- bind_rows(cepiidist, yug_i)
yug_i$i_iso3 <- "MNE"
cepiidist <- bind_rows(cepiidist, yug_i)

yug_j$j_iso3 <- "SRB"
cepiidist <- bind_rows(cepiidist, yug_j)
yug_j$j_iso3 <- "MNE"
cepiidist <- bind_rows(cepiidist, yug_j)

yug_geo$iso3 <- "SRB"
cepiigeo <- bind_rows(cepiigeo, yug_geo)
yug_geo$iso3 <- "MNE"
cepiigeo <- bind_rows(cepiigeo, yug_geo)

# Note: seadist can sometimes be shorter than adist because adist is population-weighted while
# seadist is coast-coast

# append to flows
seadist <- seadist %>% select(i_iso3, j_iso3, seadistance)
flowshs2 <- left_join(flowshs2, seadist, by=c("i_iso3", "j_iso3"))

cepiidist <- cepiidist %>% select(i_iso3, j_iso3, contig, distw)
flowshs2 <- left_join(flowshs2, cepiidist, by=c("i_iso3", "j_iso3"))

cepiigeo <- cepiigeo %>% select(iso3, landlocked)
colnames(cepiigeo)[2] <- "i_landlocked"
flowshs2 <- left_join(flowshs2, cepiigeo, by=c("i_iso3"="iso3"))
colnames(cepiigeo)[2] <- "j_landlocked"
flowshs2 <- left_join(flowshs2, cepiigeo, by=c("j_iso3"="iso3"))

# # since there's no aggregation, max/min/weighted mean will just produce constant values
# flowsdist <- flows %>% group_by(i_iso3, j_iso3) %>%
#   summarise(seadist=weighted.mean(seadistance, v, na.rm=T),
#             adist=weighted.mean(distw, v, na.rm=T),
#             contig=max(contig, na.rm=T),
#             i_landlocked = min(i_landlocked, na.rm=T),
#             j_landlocked = min(j_landlocked, na.rm=T)) %>% 
#   ungroup()

# flowshs2 <- left_join(flowshs2, flowsdist)

write_csv(flowshs2, "clean/flowshs2all.csv")
