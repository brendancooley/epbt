deficit <- function(X, flowValName, ccodes) {
  
  X$flowVal <- X[[flowValName]]
  Xval <- X %>% select(i_iso3, j_iso3, flowVal)
  Xzeros <- cbind(ccodes, ccodes, 0) %>% as_tibble()
  colnames(Xzeros) <- c("i_iso3", "j_iso3", "flowVal")
  Xzeros$flowVal <- as.numeric(Xzeros$flowVal)
  Xval <- bind_rows(Xval, Xzeros) %>% arrange(j_iso3, i_iso3)
  
  XvalM <- Xval %>% 
    group_by(i_iso3) %>%
    mutate(id = row_number()) %>%
    spread(i_iso3, flowVal) %>%
    select(-id, -j_iso3) %>%
    as.matrix()
  
  XvalE <- rowSums(XvalM)
  XvalR <- colSums(XvalM)
  
  valD <- cbind(ccodes, XvalE, XvalR) %>% as_tibble()
  colnames(valD) <- c("iso3", "fExp", "fRev")
  valD$fExp <- as.numeric(valD$fExp)
  valD$fRev <- as.numeric(valD$fRev)
  valD$deficit <- valD$fExp - valD$fRev
  # cifD$deficit %>% sum()
  valD <- valD %>% select(iso3, deficit)
  
  return(valD)
}