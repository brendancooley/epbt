if (!exists("TPSP")) {
  TPSP <- FALSE
}
if (!exists("mini")) {
  mini <- FALSE
}

library(tidyverse)

### DIRECTORIES ###

analysis_dirname <- "01_analysis"

basedir <- "~/Dropbox (Princeton)/1_Papers/epbt/01_data/"

datadir <- paste0(basedir, "01_raw/")
cleandir <- paste0(basedir, "02_clean/")
resultsdir <- paste0(basedir, "03_results/")
otherdir <- paste0(basedir, "04_other/")

if (mini==TRUE) {
  cleandirTPSP <- paste0(basedir, "tpsp_clean_mini/")
  resultsdirTPSP <- paste0(basedir, "tpsp_results_mini/")
  expdirTPSP <- paste0(basedir, "tpsp_data_mini/")
} else {
  cleandirTPSP <- paste0(basedir, "tpsp_clean/")
  resultsdirTPSP <- paste0(basedir, "tpsp_results/")
  expdirTPSP <- paste0(basedir, "tpsp_data/")
}

cleandirEU <- paste0(cleandir, "EUD/")
resultsdirEU <- paste0(resultsdir, "EUD/")

proprietaryDataPath <- "~/Dropbox (Princeton)/1_Papers/epbt/estimation/dataProprietary/"

### SOURCE HELPERS ###

ccodesAll <- c()

wd <- getwd()

if ("sections" %in% strsplit(wd, "/")[[1]]) {
  sourceDir <- paste0("../", analysis_dirname, "/source/")
  sourceFiles <- list.files(sourceDir)
  for (i in sourceFiles) {
    source(paste0(sourceDir, i))
  }
} else {
  if (analysis_dirname %in% strsplit(wd, "/")[[1]]) {
    sourceFiles <- list.files("source/")
    for (i in sourceFiles) {
      source(paste0("source/", i))
    }
    ccodesPath <- paste0(cleandir, "ccodes.csv")
    if (file.exists(ccodesPath)) {
      ccodesAll <- read_csv(ccodesPath) %>% pull(.)  # all
    }
  } else {
    sourceDir <- paste0(analysis_dirname, "/source/")
    sourceFiles <- list.files(sourceDir)
    print(sourceFiles)
    for (i in sourceFiles) {
      source(paste0(sourceDir, i))
    }
  }
}

# helperPath <- "~/Dropbox (Princeton)/14_Software/R/"
# helperFiles <- list.files(helperPath)
# for (i in helperFiles) {
#   source(paste0(helperPath, i))
# }

### PARAMETERS ###

startY <- 1995
endY <- 2011
Y <- 2011

est_sigma <- TRUE

# NOTE: small countries get unrealistic trade shares with theta \approx 4 and tauRev = FALSE
# Standard results...theta=6(?)

if (TPSP == FALSE) {
  theta <- 6
} else {
  theta <- 6
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
cluster <- T  # cluster countries?
Kmeans <- 3  # number of clusters
KmeansEUD <- 3  # number of clusters with EU disaggregated

# revenues
tauRev <- FALSE
mu <- 1  # share of potential revenues captured by government

# mini economy for tpsp
if (mini==TRUE) {
  ccodesTPSP <- c("CHN", "EU", "JPN", "RUS", "USA")  # subset for mini economy
} else {
  dropTPSP1 <- c("VNM", "IND", "ISR", "NZL", "PER", "CHL", "ZAF", "PHL", "COL", "THA")
  dropTPSP2 <- c("AUS", "IDN", "KOR", "MEX", "TUR") # comment out if we want larger set of countries
  # This leaves BRA, CAN, CHN, EU, JPN, ROW, RUS, USA
  ccodesTPSP <- setdiff(ccodesAll, dropTPSP1)
  ccodesTPSP <- setdiff(ccodesTPSP, dropTPSP2)
}

# island indicator
island <- c("AUS", "CYP", "GBR", "IRL", "JPN", "IDN", "PHL")