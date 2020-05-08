print("-----")
print("Starting 05_freight.R")
print("-----")

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
if ("05_sections" %in% strsplit(wd, "/")[[1]]) {
  runPreds <- FALSE
} else {
  shiny <- FALSE
  source('params.R')
  runPreds <- TRUE
}

libs <- c('tidyverse', 'earth', "nnet", "olpsR", "glmnet", "plotly", "splines", 'ggsci', 'ggthemes', 'ggrepel', "reader")
ipak(libs) 

if (EUD==FALSE) {
  if (TPSP==FALSE) {
    flowsPath <- paste0(cleandir, "flowshs2.csv")
  } else {
    flowsPath <- paste0(cleandirTPSP, "flowshs2.csv")
  }
} else{
  flowsPath <- paste0(cleandirEU, "flowshs2.csv")
}


flows <- read_csv(flowsPath)

# filter extreme observations
thres <- 2.5
flows$avcsea <- ifelse(flows$avcsea > thres, NA, flows$avcsea)
flows$avcland <- ifelse(flows$avcland > thres, NA, flows$avcland)
flows$avcair <- ifelse(flows$avcair > thres, NA, flows$avcair)

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


### MODEL AD VALOREM COSTS ###

### Sea costs ### 
flowsSea <- flows %>% filter(!is.na(avcsea))
flowsSea$hs2 <- as.factor(flowsSea$hs2)
if (bootstrap==TRUE) {
  flowsSea <- flowsSea %>% group_by(j_iso3) %>% sample_frac(size=1, replace=TRUE)
}

# standardized model for paper, unstandardized for predictions
seaModelOutput <- lm(avcsea ~ hs2 + bs(year, degree = 3) + seadist_log_scaled + contig, data=flowsSea, weights=flowsSea$val)
seaModel <- lm(avcsea ~ hs2 + bs(year, degree = 3) + seadist_log + contig, data=flowsSea, weights=flowsSea$val)

### Land costs ### 
flowsLand <- flows %>% filter(!is.na(avcland))
flowsLand$hs2 <- as.factor(flowsLand$hs2)
if (bootstrap==TRUE) {
  flowsLand <- flowsLand %>% group_by(j_iso3) %>% sample_frac(size=1, replace=TRUE)
}

landModelOutput <- lm(avcland ~ hs2 + bs(year, degree=3) + adist_log_scaled + contig, data=flowsLand, weights=flowsLand$val)
landModel <- lm(avcland ~ hs2 + bs(year, degree=3) + adist_log + contig, data=flowsLand, weights=flowsLand$val)

### Air Costs ###
flowsAir <- flows %>% filter(!is.na(avcair))
flowsAir$hs2 <- as.factor(flowsAir$hs2)
if (bootstrap==TRUE) {
  flowsAir <- flowsAir %>% group_by(j_iso3) %>% sample_frac(size=1, replace=TRUE)
}

airModelOutput <- lm(avcair ~ hs2 + bs(year, degree=3) + adist_log_scaled + contig, data=flowsAir, weights=flowsAir$val)
airModel <- lm(avcair ~ hs2 + bs(year, degree=3) + adist_log + contig, data=flowsAir, weights=flowsAir$val)

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

### LOGIT DEMAND MODEL ###


# project out othershare
flows_proj <- flows %>% select(seashare, airshare, landshare) %>% as.matrix() %>% apply(1, projsplx) %>% t() %>% as_tibble()
flows <- flows %>% select(-seashare, -airshare, -landshare, -othershare) %>% bind_cols(flows_proj) 

flows$seashare_diff <- log(flows$seashare) - log(flows$airshare)
flows$landshare_diff <- log(flows$landshare) - log(flows$airshare)

flows$avcsea_diff <- flows$avcseaP - flows$avcairP
flows$avcland_diff <- flows$avclandP - flows$avcairP

flows$island_max <- apply(flows %>% select(i_island, j_island), 1, max)
flows$landlocked_max <- apply(flows %>% select(i_landlocked, j_landlocked), 1, max)

flowsLogitSea <- flows %>% select(seashare_diff, avcsea_diff) %>% filter(!is.na(seashare_diff), !is.infinite(seashare_diff))
colnames(flowsLogitSea)[1:2] <- c("share_diff", "price_diff")
flowsLogitSea$sea_indicator <- 1
flowsLogitSea$land_indicator <- 0

flowsLogitLand <- flows %>% select(landshare_diff, avcland_diff) %>% filter(!is.na(landshare_diff), !is.infinite(landshare_diff))
colnames(flowsLogitLand)[1:2] <- c("share_diff", "price_diff")
flowsLogitLand$sea_indicator <- 0
flowsLogitLand$land_indicator <- 1

flowsLogit <- bind_rows(flowsLogitSea, flowsLogitLand)

flowsLogitModel <- lm(data=flowsLogit, share_diff~price_diff+sea_indicator+land_indicator-1)
summary(flowsLogitModel)
beta_price <- coef(flowsLogitModel)[1]
u_sea <- coef(flowsLogitModel)[2]
u_land <- coef(flowsLogitModel)[3]

flows$airshare_exp <- 1
flows$seashare_exp <- exp(flows$avcsea_diff * beta_price + u_sea) * (1 - flows$landlocked_max)
flows$landshare_exp <- exp(flows$avcland_diff * beta_price + u_land) * (1 - flows$island_max)
flows$logit_denom <- flows$airshare_exp + flows$seashare_exp + flows$landshare_exp

flows$airshareP <- flows$airshare_exp / flows$logit_denom
flows$seashareP <- flows$seashare_exp / flows$logit_denom
flows$landshareP <- flows$landshare_exp / flows$logit_denom

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


print("-----")
print("Concluding 05_freight.R")
print("-----")