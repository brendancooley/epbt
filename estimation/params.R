Y <- 2011

theta <- 4
thetaAlt <- 2 * theta

sigma <- theta + 1
sigmaAlt <- 2 * sigma - 2

bcOrange <- "#BD6121"

# countries to drop
ccodesDrop <- c("ARG")

EUD <- FALSE # disaggregate EU?

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
tauRev <- TRUE
mu <- 1  # share of potential revenues captured by government

# mini economy for tpsp
tpspC <- TRUE
ccodesTPSP <- c("CHN", "EU", "JPN", "BRA", "USA")