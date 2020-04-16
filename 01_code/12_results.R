source("params.R")

libs <- c("tidyverse")
ipak(libs)

### DATA ###

ccodes <- read_csv(paste0(cleandir, "ccodes.csv")) %>% pull(.)

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

write_csv(tau_quantiles, tau_quantiles_path)
write_csv(tau_quantiles, tau_quantiles_shiny_path)
