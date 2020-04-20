if (!exists("TPSP")) {
  TPSP <- FALSE
}
if (!exists("mini")) {
  mini <- FALSE
}

library(tidyverse)

M <- 100 # number of bootstrap iterations

### DIRECTORIES ###

analysis_dirname <- "01_code"
code_dir <- "01_code/"

basedir <- "~/Dropbox (Princeton)/1_Papers/epbt/01_data/"

datadir <- paste0(basedir, "01_raw/")
cleandir <- paste0(basedir, "02_clean/")
resultsdir <- paste0(basedir, "03_results/")
otherdir <- paste0(basedir, "04_other/")
results_local_dir <- paste0("../02_results/")
shinydir <- paste0("../04_viz/")

ccodes_mini <- c("CHN", "EU", "JPN", "USA")
ccodes_mid <- c("AUS", "BRA", "CAN", "CHN", "EU", "JPN", "KOR", "USA")
ccodes_large <- c("AUS", "BRA", "CAN", "CHN", "EU", "IDN", "JPN", "KOR", "MEX", "ROW", "RUS", "TUR", "USA")

if (TPSP==TRUE) {
  if (size=="mid/") {
    ccodesTPSP <- ccodes_mid
  }
  if (size=="large/") {
    ccodesTPSP <- ccodes_large
  }
  if (size=="mini/") {
    ccodesTPSP <- ccodes_mini
  }
  cleandirTPSP <- paste0(basedir, "tpsp_clean_", size)
  resultsdirTPSP <- paste0(basedir, "tpsp_results_", size)
}
  
cleandirEU <- paste0(cleandir, "EUD/")
resultsdirEU <- paste0(resultsdir, "EUD/")

proprietaryDataPath <- "~/Dropbox (Princeton)/1_Papers/epbt/estimation/dataProprietary/"

### BOOTSTRAP ###

if (EUD == FALSE) {
  bootstrap_dir <- paste0(basedir, "05_bootstrap/")
} else {
  bootstrap_dir <- paste0(basedir, "05_bootstrap/EUD/")
}

bootstrap_P_dir <- paste0(bootstrap_dir, "P/")
bootstrap_freight_dir <- paste0(bootstrap_dir, "delta/")
bootstrap_tau_dir <- paste0(bootstrap_dir, "tau/")

# bstrp_prices <- paste0(bootstrapdir, "prices/")
# bstrp_freight <- paste0(bootstrapdir, "freight/")

### PATHS ###

tau_quantiles_path <- paste0(results_local_dir, "tau_quantiles.csv")
tau_quantiles_shiny_path <- paste0(shinydir, "tau_quantiles.csv")

### SOURCE HELPERS ###

ccodesAll <- c()

wd <- getwd()

if (shiny==FALSE) {
  ccodesPath <- paste0(cleandir, "ccodes.csv")
  if (file.exists(ccodesPath)) {
    ccodesAll <- read_csv(ccodesPath) %>% pull(.)  # all
  }
  sourceDir <- paste0("../source/R/")
  sourceFiles <- list.files(sourceDir)
  for (i in sourceFiles) {
    source(paste0(sourceDir, i))
  }
}


# helperPath <- "~/Dropbox (Princeton)/14_Software/R/"
# helperFiles <- list.files(helperPath)
# for (i in helperFiles) {
#   source(paste0(helperPath, i))
# }

### MAKE DIRECTORIES ###

if (analysis_dirname %in% strsplit(wd, "/")[[1]]) {
  mkdir(bootstrap_dir)
  mkdir(bootstrap_P_dir)
  mkdir(bootstrap_freight_dir)
  mkdir(bootstrap_tau_dir)
  if (TPSP==TRUE) {
    mkdir(cleandirTPSP)
    mkdir(resultsdirTPSP)
  }
}
# mkdir(bstrp_prices)
# mkdir(bstrp_freight)

### PARAMETERS ###

startY <- 1995
endY <- 2011
Y <- 2011

est_sigma <- TRUE
ROWname <- "RoW"

# NOTE: small countries get unrealistic trade shares with theta \approx 4 and tauRev = FALSE
# Standard results...theta=6(?)

if (TPSP == FALSE) {
  theta <- 6
  tauRev <- FALSE
} else {
  theta <- 6
  tauRev <- TRUE
}
thetaAlt <- 2 * theta

sigma <- theta + 1
sigmaAlt <- 2 * sigma - 2

### OTHER OPTIONS ###

bcOrange <- "#BD6121"

# countries to drop
ccodesDrop <- c("ARG")

# EUD <- FALSE # disaggregate EU?

BNL <- TRUE # aggregate Belgium, Netherlands, Luxembourg (as in Dekle et al)
BNLccodes <- c("BEL", "LUX", "NLD")

MYSG <- TRUE # aggregate Singapore, Malaysia 
MYSGccodes <- c("MYS", "SGP")

ELL <- TRUE # aggregate Baltic countries (Estonia, Latvia, Lithuania)
ELLccodes <- c("EST", "LVA", "LTU")

# figure options (heatmap)
TRIMAI <- F  # include TRI and MAI?
# cluster <- T  # cluster countries?
# Kmeans <- 3  # number of clusters
# KmeansEUD <- 4  # number of clusters with EU disaggregated

# revenues
if (TPSP == TRUE) {
  mu <- 1  # share of potential revenues captured by government
} else {
  mu <- 0  # share of potential revenues captured by government
}

# island indicator
island <- c("AUS", "CYP", "GBR", "IRL", "JPN", "IDN", "PHL")