library(tidyverse)

### SOURCE HELPERS ###

ccodesAll <- c()

wd <- getwd()
if ("sections" %in% strsplit(wd, "/")[[1]]) {
  sourceFiles <- list.files("../estimation/source/")
  for (i in sourceFiles) {
    source(paste0("../estimation/source/", i))
  }
} else {
  if ("estimation" %in% strsplit(wd, "/")[[1]]) {
    sourceFiles <- list.files("source/")
    for (i in sourceFiles) {
      source(paste0("source/", i))
    }
    ccodesAll <- read_csv(paste0(cleandir, "ccodes.csv")) %>% pull(.)  # all
  } else {
    sourceFiles <- list.files("estimation/source/")
    for (i in sourceFiles) {
      source(paste0("estimation/source/", i))
    }
  }
}

helperPath <- "~/Dropbox (Princeton)/14_Software/R/"
helperFiles <- list.files(helperPath)
for (i in helperFiles) {
  source(paste0(helperPath, i))
}

### DIRECTORIES ###

datadir <- "01_data/"
cleandir <- "02_clean/"
resultsdir <- "03_results/"
otherdir <- "04_other/"

cleandirTPSP <- "tpsp_clean/"
resultsdirTPSP <- "tpsp_results/"
expdirTPSP <- "tpsp_data/"

cleandirEU <- paste0(cleandir, "EUD/")
resultsdirEU <- paste0(resultsdir, "EUD/")

### PARAMETERS ###

startY <- 1995
endY <- 2011
Y <- 2011

# NOTE: small countries get unrealistic trade shares with theta \approx 4 and tauRev = FALSE
# Standard results...theta=6(?)
theta <- 6
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
KmeansEUD <- 4  # number of clusters with EU disaggregated

# revenues
tauRev <- FALSE
mu <- 1  # share of potential revenues captured by government

# mini economy for tpsp
# tpspC <- TRUE
# ccodesTPSP <- c("CHN", "EU", "JPN", "BRA", "USA")  # subset
ccodesTPSP <- ccodesAll

# island indicator
island <- c("AUS", "CYP", "GBR", "IRL", "JPN", "IDN", "PHL")