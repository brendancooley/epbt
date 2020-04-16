print("-----")
print("Starting 05_freight.R")
print("-----")

### TO DOs ###

# problem with mode shares somewhere in cleaning...ROW as j_iso3 has mode share data
  # We actually have this data! Comes from non-EU countries that provide data before ascension
  # drop ROW from delta estimation?
### Get customizable arguments from command line ###

args <- commandArgs(trailingOnly=TRUE)
if (is.null(args) | identical(args, character(0))) {
  EUD <- FALSE
  TPSP <- FALSE
  size <- "all"
  bootstrap <- FALSE
} else {
  EUD <- ifelse(args[1] == "True", TRUE, FALSE)
  TPSP <- ifelse(args[2] == "True", TRUE, FALSE)
  size <- args[3]
  bootstrap <- ifelse(args[4] == "True", TRUE, FALSE)
  bootstrap_id <- args[5]
}

### SETUP ###

wd <- getwd()
if ("sections" %in% strsplit(wd, "/")[[1]]) {
  runPreds <- FALSE
} else {
  shiny <- FALSE
  source('params.R')
  runPreds <- TRUE
}

libs <- c('tidyverse', 'earth', "nnet", "olpsR", "glmnet", "plotly", "splines", 'ggsci', 'ggthemes', 'ggrepel', "reader")
ipak(libs) 

# variable search for calling locally or from Rmd
# wd <- getwd()
# if ("sections" %in% strsplit(wd, "/")[[1]]) {
#   if (EUD==FALSE) {
#     flowsPath <- find.file('flowshs2.csv', dir=cleandir, dirs=paste0("../estimation/", cleandir))
#   } else {
#     flowsPath <- find.file('flowshs2.csv', dir=cleandirEU, dirs=paste0("../estimation/", cleandirEU))
#   }
# } else {
if (EUD==FALSE) {
  if (TPSP==FALSE) {
    flowsPath <- paste0(cleandir, "flowshs2.csv")
  } else {
    flowsPath <- paste0(cleandirTPSP, "flowshs2.csv")
  }
} else{
  flowsPath <- paste0(cleandirEU, "flowshs2.csv")
}
# }


flows <- read_csv(flowsPath)
# summary(flows)
# flows %>% filter(!is.na(avcair) & avcair < 0)

# filter extreme observations
thres <- 2.5
flows$avcsea <- ifelse(flows$avcsea > thres, NA, flows$avcsea)
flows$avcland <- ifelse(flows$avcland > thres, NA, flows$avcland)
flows$avcair <- ifelse(flows$avcair > thres, NA, flows$avcair)

# drop ROW (don't want to do this because we need this as part of output)
# just estimate with weighted average of distances
# flows <- flows %>% filter(i_iso3 != "ROW" & j_iso3 != "ROW")
# flows %>% filter(j_iso3=="AUS") %>% print(n=100)

### island indicator
isl <- data.frame(ccode=unique(flows$i_iso3), island=0)
isl$island <- ifelse(isl$ccode %in% island, 1, 0)

flows <- left_join(flows, isl, by=c("i_iso3"="ccode"))
colnames(flows)[colnames(flows)=="island"] <- "i_island"
flows <- left_join(flows, isl, by=c("j_iso3"="ccode"))
colnames(flows)[colnames(flows)=="island"] <- "j_island"

# log distances (add 1 to deal with zeros)
flows$adist_log <- flows$adist + 1 %>% log()
flows$seadist_log <- flows$seadist + 1 %>% log()

# scaled distances
flows$adist_log_scaled <- scale(flows$adist_log)
flows$seadist_log_scaled <- scale(flows$seadist_log)
# flows %>% filter(!is.na(seadist)) %>% select(seadist, seadist_log, seadist_log_scaled) %>% summary()
# flows %>% filter(seadist==0)


### MODEL AD VALOREM COSTS ###

### Sea costs ### 
flowsSea <- flows %>% filter(!is.na(avcsea))
flowsSea$hs2 <- as.factor(flowsSea$hs2)
# flowsSea$seadist_scaled <- scale(flowsSea$seadist)  # scale for interpretability only
if (bootstrap==TRUE) {
  flowsSea <- flowsSea %>% group_by(j_iso3) %>% sample_frac(size=1, replace=TRUE)
}

# standardized model for paper, unstandardized for predictions
seaModelOutput <- lm(avcsea ~ hs2 + bs(year, degree = 3) + seadist_log_scaled + contig, data=flowsSea, weights=flowsSea$val)
# flowsSea %>% select(avcsea, hs2, year, seadist_log_scaled, contig, everything())

### Land costs ### 
flowsLand <- flows %>% filter(!is.na(avcland))
flowsLand$hs2 <- as.factor(flowsLand$hs2)
# flowsLand$adist_scaled <- scale(flowsLand$adist)
if (bootstrap==TRUE) {
  flowsLand <- flowsLand %>% group_by(j_iso3) %>% sample_frac(size=1, replace=TRUE)
}

landModelOutput <- lm(avcland ~ hs2 + bs(year, degree=3) + adist_log_scaled + contig, data=flowsLand, weights=flowsLand$val)

### Air Costs ###
flowsAir <- flows %>% filter(!is.na(avcair))
flowsAir$hs2 <- as.factor(flowsAir$hs2)
# flowsAir$adist_scaled <- scale(flowsAir$adist)
if (bootstrap==TRUE) {
  flowsAir <- flowsAir %>% group_by(j_iso3) %>% sample_frac(size=1, replace=TRUE)
}

airModelOutput <- lm(avcair ~ hs2 + bs(year, degree=3) + adist_log_scaled + contig, data=flowsAir, weights=flowsAir$val)

### MODEL MODE SHARES ###

flowsModes <- flows %>% filter(!is.na(airshare)) # %>% filter(airshare + seashare + landshare + othershare >= .01)
flowsModes$landshare <- ifelse(is.na(flowsModes$landshare), 0, flowsModes$landshare)
if (bootstrap==TRUE) {
  flowsModes <- flowsModes %>% group_by(j_iso3) %>% sample_frac(size=1, replace=T) %>% ungroup()
}

flowsModes$hs2 <- as.factor(flowsModes$hs2)
# flowsModes$adist_scaled <- scale(flowsModes$adist)
# flowsModes$seadist_scaled <- scale(flowsModes$seadist)

flowsModesX <- flowsModes %>% select(adist_log, seadist_log, contig, year, i_island, j_island, hs2)
flowsModesXOutput <- flowsModes %>% select(adist_log_scaled, seadist_log_scaled, contig, year, i_island, j_island, hs2)
flowsModesY <- flowsModes %>% select(airshare, seashare, landshare, othershare) %>% as.matrix()

d <- 0
modesModelOutput <- multinom(flowsModesY ~ hs2 + bs(year, degree=3) + adist_log_scaled + seadist_log_scaled + contig + i_island + j_island, data=flowsModesXOutput, decay=d, trace=FALSE)

if (runPreds == TRUE) {
  
  seaModel <- lm(avcsea ~ hs2 + bs(year, degree = 3) + seadist_log + contig, data=flowsSea, weights=flowsSea$val)
  # summary(seaModel)
  # flowsSea %>% filter(j_iso3=="AUS")
  landModel <- lm(avcland ~ hs2 + bs(year, degree=3) + adist_log + contig, data=flowsLand, weights=flowsLand$val)
  airModel <- lm(avcair ~ hs2 + bs(year, degree=3) + adist_log + contig, data=flowsAir, weights=flowsAir$val)
  # summary(airModel)
  modesModel <- multinom(flowsModesY ~ hs2 + bs(year, degree=3) + adist_log + seadist_log + contig + i_island + j_island, data=flowsModesX, decay=d, trace=FALSE)
  
  ### MAP AD VALOREM COST PREDICTIONS
  
  flowsSeaX <- flows %>% select(hs2, year, seadist_log, contig, i_island, j_island)
  flows$avcseaP <- predict(seaModel, flowsSeaX)
  
  flowsAirX <- flows %>% select(hs2, year, adist_log, contig)
  flows$avcairP <- predict(airModel, flowsAirX)
  
  flowsLandX <- flows %>% select(hs2, year, adist_log, contig)
  flows$avclandP <- predict(landModel, flowsLandX)
  
  # enforce nonnegativity constraint
  flows$avcairP <- ifelse(flows$avcairP < 0, 0, flows$avcairP)
  flows$avcseaP <- ifelse(flows$avcseaP < 0, 0, flows$avcseaP)
  flows$avclandP <- ifelse(flows$avclandP < 0, 0, flows$avclandP)
  
  ### MAP MODE SHARES ###
  
  flowsModesP <- predict(modesModel, newdata = flows, type="probs") %>% as_tibble()
  colnames(flowsModesP) <- paste0(colnames(flowsModesP), "P")
  
  # project air, land, sea onto 2d simplex because othershare constitutes small proportion in data
  flowsModesPals <- flowsModesP %>% select(-one_of("othershareP")) %>% as.matrix()
  # projsplx_2(flowsModesPals[1, ]) %>% sum()
  flowsModesPals <- apply(flowsModesPals, 1, projsplx_2) %>% t() %>% as_tibble()
  # rowSums(test)
  
  flows <- bind_cols(flows, flowsModesPals)
  
  
  ### CALCULATE PREDICTED DELTAS ###
  
  aggShare <- flows %>% group_by(i_iso3, j_iso3) %>%
    summarise(
      air=sum(val*airshareP),
      sea=sum(val*seashareP),
      land=sum(val*landshareP),
      val=sum(val)
    )
  aggShare$airshare <- aggShare$air / aggShare$val
  aggShare$seashare <- aggShare$sea / aggShare$val
  aggShare$landshare <- aggShare$land / aggShare$val
  
  aggCost <- flows %>% group_by(i_iso3, j_iso3) %>%
    summarise(
      air=weighted.mean(avcairP, val),
      sea=weighted.mean(avcseaP, val),
      land=weighted.mean(avclandP, val)
    )
  
  delta <- flows %>% group_by(i_iso3, j_iso3, year) %>%
    summarise(
      fob=sum(val),
      freight=sum(val * (airshareP * avcairP + seashareP * avcseaP + landshareP * avclandP))
    )
  delta$cif <- delta$fob + delta$freight
  delta$avc <- delta$cif / delta$fob
  
  if (bootstrap==FALSE) {
    if (EUD==FALSE) {
      if (TPSP==FALSE) {
        write_csv(delta, paste0(cleandir, "delta.csv"))
      } else {
        write_csv(delta, paste0(cleandirTPSP, "delta.csv"))
      }
    } else {
      write_csv(delta, paste0(cleandirEU, "delta.csv"))
    }
  } else {
    write_csv(delta, paste0(bootstrap_freight_dir, bootstrap_id, ".csv"))
  }
  print("done")
}

print("-----")
print("Concluding 05_freight.R")
print("-----")