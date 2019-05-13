Y <- 2011

theta <- 6
thetaAlt <- 12

sigma <- 6
sigmaAlt <- 11

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
mu <- .5  # share of potential revenues captured by government