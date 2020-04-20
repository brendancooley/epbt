tau1 <- function(Lji, Lii, delta, Pj, Pi, theta) {
  return((Lji / Lii)^(-1/(theta+1)) * (Pj / Pi)^(theta/(theta+1)) * (1 / delta)^(theta/(theta+1)))
}

tau2 <- function(Lji, Lii, delta, Pj, Pi, theta) {
  return((Lji / Lii)^(-1/theta) * Pj / Pi * 1 / delta)
}

norm_vec <- function(x) sqrt(sum(x^2))

tauLambda <- function(X, theta, tauName, LiiName, LjjName) {
  
  # Xj: importer-specific data
  # takes vectors and searches for fixed point of estimating equation by iteratively recalculating Lii
  
  Lii_current <- 1
  Lii_last <- 0
  threshold <- .0001
  
  while(norm_vec(Lii_last - Lii_current) > threshold) {
    
    Lii_last <- Lii_current
    X[[tauName]] <- tau1(X$Lji, X[[LiiName]], X$delta, X$Pj, X$Pi, theta)
    X$tempTau <- X[[tauName]]
    Xi <- X %>% group_by(j_iso3) %>%
      summarise(tempL=1-sum(Lji*tempTau))
    colnames(Xi) <- c("i_iso3", LiiName)
    Xi[[LiiName]] <- ifelse(Xi[[LiiName]] <=0, .0001, Xi[[LiiName]])
    # Xi %>% print()
    
    X <- X %>% select(-LiiName)
    X <- left_join(X, Xi)

    Xj <- Xi
    colnames(Xj) <- c("j_iso3", LjjName)
    X <- X %>% select(-LjjName)
    X <- left_join(X, Xj)
    
    Lii_current <- X[[LiiName]]
    
  }
  
  X %>% select(-tempTau)
  
  return(X)
}

tauLambdaRev <- function(X, gdpR, theta, mu) {
  
  Xii_current <- 1
  Xii_last <- 0
  threshold <- .1
  
  while(norm_vec(Xii_last - Xii_current) > threshold) {
    
    gdpR$rj <- 0
    gdpR$Xnj <- 0
    gdpR$Xnj_pc <- 0
    
    Xii_last <- Xii_current
    
    X$tau <- tau1(X$Lji, X$Lii, X$delta, X$Pj, X$Pi, theta)
    X$rji <- (X$tau - 1) * mu * X$cif
    X$cifmu <- X$tau * X$cif - mu * X$cif * (X$tau - 1)
    # X %>% select(tau, Lji, Lii, Ljj, rji, cifmu, cif, everything()) %>% print()
    # summary(X) %>% print()
    # X %>% filter(is.na(rji)) %>% select(tau, Lji, Lii, Ljj, rji, cifmu, everything()) %>% print()
    
    # recompute deficits
    ccodes <- X$j_iso3 %>% unique() %>% sort()
    cifmuD <- deficit(X, "cifmu", ccodes)
    # cifmuD %>% print(n=50)
    colnames(cifmuD) <- c("j_iso3", "j_deficit")
    # print(cifmuD$j_deficit %>% sum())
    
    Xj <- X %>% group_by(j_iso3) %>%
      summarise(rj=sum(rji),
                Xnj_pc=sum(cif*tau))
    # Xj %>% print()
    colnames(Xj) <- c("j_iso3", "rj", "Xnj_pc")
    
    # gdpR %>% print()
    gdpR <- gdpR %>% select(-rj, -Xnj_pc, -j_deficit)
    gdpR <- gdpR %>% left_join(Xj, by=c("j_iso3"))
    gdpR <- gdpR %>% left_join(cifmuD, by="j_iso3")
    # gdpR %>% print(n=50)
    gdpR$j_expS <- (1 - gdpR$j_Tshare) * (gdpR$j_con_exp - gdpR$j_deficit)
    gdpR$j_gcT <- gdpR$j_tot_exp - gdpR$j_expS
    gdpR$j_home_expT <- gdpR$j_gcT - gdpR$Xnj_pc
    # print(gdpR)

    gdpRbind <- gdpR %>% select(j_iso3, year, j_home_expT, j_gcT)
    X <- X %>% select(-j_home_expT, -j_gcT)
    X <- left_join(X, gdpRbind)
    
    colnames(gdpRbind) <- c("i_iso3", "year", "i_home_expT", "i_gcT")
    X <- X %>% select(-i_home_expT, -i_gcT)
    X <- left_join(X, gdpRbind)
    
    X$Lii <- X$i_home_expT / X$i_gcT
    X$Ljj <- X$j_home_expT / X$j_gcT
    X$Lji <- X$cif / X$j_gcT
    
    # correct negative observations
    X$Lii <- ifelse(X$Lii <=0, .01, X$Lii)
    # X %>% select(tau, Lji, Lii, Ljj, rji, cifmu, everything()) %>% print()
    
    Xii_current <- X$i_home_expT
    
  }
  
  return(list(X, gdpR))
  
}