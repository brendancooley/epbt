args <- commandArgs(trailingOnly=TRUE)
if (is.null(args) | identical(args, character(0))) {
  EUD <- FALSE
  TPSP <- FALSE
  size <- "all"
} else {
  EUD <- ifelse(args[1] == "True", TRUE, FALSE)
  TPSP <- ifelse(args[2] == "True", TRUE, FALSE)
  size <- args[3]
}

shiny <- FALSE
source("params.R")

libs <- c("tidyverse")
ipak(libs)

### DATA ###

if (EUD == FALSE) {
  ccodes <- read_csv(paste0(cleandir, "ccodes.csv")) %>% pull(.)
} else {
  ccodes <- read_csv(paste0(cleandir, "EUD/", "ccodes.csv")) %>% pull(.)
}

tau_M <- data.frame(expand.grid(ccodes, ccodes)) %>% as_tibble()
colnames(tau_M) <- c("i_iso3", "j_iso3")
tau_M <- tau_M %>% filter(i_iso3!=j_iso3)

for (i in 1:M) {
  tau_i <- read_csv(paste0(bootstrap_tau_dir, i, ".csv")) %>% select(i_iso3, j_iso3, tau)
  colnames(tau_i) <- c("i_iso3", "j_iso3", i)
  tau_M <- tau_M %>% left_join(tau_i)
}

Q <- apply(tau_M %>% select(-i_iso3, -j_iso3) %>% as.matrix(), 1, quantile, probs=c(.025, .5, .975)) %>% t() %>% as_tibble()
colnames(Q) <- c("q025", "q500", "q975")

tau_quantiles <- cbind(tau_M %>% select(i_iso3, j_iso3), Q) %>% as_tibble()
tau_quantiles$i_iso3 <- as.factor(tau_quantiles$i_iso3)

if (TPSP==FALSE) {
  write_csv(tau_quantiles, tau_quantiles_path)
  write_csv(tau_quantiles, tau_quantiles_shiny_path)
}
