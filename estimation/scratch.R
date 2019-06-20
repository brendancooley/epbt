### OLD EXPORT ###

# X <- left_join(P, tau)



delta <- delta %>% select(i_iso3, j_iso3, year, avc)

X <- left_join(shares, P)
X <- left_join(X, tau)
X <- left_join(X, delta)

X$tau <- ifelse(is.na(X$tau), 1, X$tau)
X$avc <- ifelse(is.na(X$avc), 1, X$avc)

X %>% group_by(j_iso3) %>%
  summarise(test=sum(Lji*tau))

X$Xji_pc <- X$Lji * X$tau * X$j_gcT

# X %>% group_by(j_iso3) %>% 
#   summarise(test=sum(Xji_pc),
#             test2=sum(Lji*tau))
# X

X <- X %>% arrange(j_iso3, i_iso3) %>% select(i_iso3, j_iso3, year, everything())
X
X %>% filter(i_iso3==j_iso3) %>% print(n=50)

write_csv(X, "~/Dropbox (Princeton)/2_Projects/tpsp/data/tpsp.csv")

# gdpR
# Xr <- X %>% group_by(j_iso3) %>% summarise(r = sum(rji))
# X$test <- X$cif * (X$tau - 1) * mu
# X$test == X$rji  # good
# gdpR <- left_join(gdpR, Xr)
# gdpR$test <- gdpR$j_tot_exp + gdpR$r - gdpR$j_expS
# gdpR$j_gcT == gdpR$test  # good

# X %>% select(i_iso3, j_iso3, tau, Lii, Ljj) %>% arrange(j_iso3, i_iso3)
# X %>% pull(tau) %>% mean() # 2.53 with tauRev = TRUE (home shares go up with revenue)
# X %>% pull(tau) %>% mean() # 2.49 with tauRev = FALSE

# X %>% select(i_iso3, j_iso3, year, tau, tauAlt, Lji, Lii, Ljj, LiiAlt, LjjAlt, j_gcT, i_gcT) %>% print(n=50)
# X %>% select(i_iso3, j_iso3, year, tau, tauAlt, Lji, Lii, Ljj, LiiAlt, LjjAlt, j_gcT, i_gcT) %>% filter(j_iso3=="AUS") %>% print(n=50)

# Xtest %>% select(Lii, Lji, tau, everything()) %>% filter(j_iso3=="BNL") %>% print(n=100)
# Xtest %>% select(Lii, Lji, tau, everything()) %>% filter(i_iso3=="BNL") %>% print(n=100)
# Xtest %>% select(Lii, Lji, tau, everything()) %>% filter(j_iso3=="MYSG") %>% print(n=100)
# 
# Xtest %>% select(Lii, Lji, tau, everything()) %>% filter(j_iso3=="DEU") %>% print(n=100)
# 
# Xtest %>% select(Lii, Lji, tau, everything()) %>% filter(j_iso3=="SGP")
# Xtest %>% select(Lii, Lji, tau, everything()) %>% filter(j_iso3=="NLD") %>% print(n=100)
# Xtest %>% select(Lii, Lji, tau, everything()) %>% filter(j_iso3=="EST") %>% print(n=100)
# 
# Xtest %>% group_by(j_iso3) %>% 
#   summarise(Lji=sum(Lji*tau)) %>% print(n=100)

# if(tauCIF==TRUE) {
#   X$tau <- tau1(X$Lji, X$Lii, X$delta, X$Pj, X$Pi, theta)
#   X$tauAlt <- tau1(X$Lji, X$Lii, X$delta, X$Pj, X$Pi, thetaAlt)
# } else {
#   X$tau <- tau2(X$Lji, X$Lii, X$delta, X$Pj, X$Pi, theta)
#   X$tauAlt <- tau2(X$Lji, X$Lii, X$delta, X$Pj, X$Pi, thetaAlt)
# }

Xshares %>% print(n=50)
# gdpR$test <- gdpR$j_home_expT + gdpR$Xnj_pc + gdpR$j_deficit + gdpR$rj # this checks out when we do missing income version
gdpR$test <- gdpR$j_home_expT + gdpR$Xnj_pc

X$mu <- mu
X$test1 <-((X$tau - 1) * (1 - mu) + 1) * X$cif
X$test2 <- X$tau * X$cif
X$test3 <- X$tau*X$cif-X$mu*X$cif*(X$tau-1)
X %>% select(cif, test1, test2, test3, tau, everything())
Xsales <- X %>% group_by(i_iso3) %>%
  summarise(Xj_R=sum(tau*cif-mu*cif*(tau-1)),
            Xj_bar=sum(tau*cif),
            Xj_ubar=sum(cif))
colnames(Xsales) <- c("j_iso3", "Xj_R", "Xj_bar", "Xj_ubar")

# Xsales <- Xsales %>% select(j_iso3, Xj_R)
gdpR <- gdpR %>% left_join(Xsales)
gdpR$test2 <- gdpR$j_home_expT + gdpR$Xj_R + gdpR$j_deficit + gdpR$rj  # close on some but not exactly right (need this = j_gcT)
# gets further away as mu gets smaller
# using cif deficits fixes this. Now for lost revenue case...
# start w/ mu = 0 (test2 too low for revenue raising countries, vice versa for subsidizing countries)
gdpR %>% select(test2, j_gcT, everything()) %>% print(n=50)

# Xshares %>% pull(j_iso3) %>% unique() %>% sort()
Xshares %>% arrange(j_iso3)
Xshares %>% group_by(j_iso3) %>%
  summarise(testji=sum(Lji*tau),
            testjj=mean(Ljj),
            test=testji+testjj) %>% print(n=100)

# filter ROW
# X <- X %>% filter(i_iso3 != "ROW", j_iso3 != "ROW")

test <- left_join(xexp, gdp)
colnames(P)[colnames(P)=="j_iso3"] <- "iso3"
test <- left_join(test, P)
colnames(r)[colnames(r)=="j_iso3"] <- "iso3"
test <- left_join(test, r)

test$Es <- ttest$gdp * (1 - test$Tshare)
test$goTest <- test$xexp + test$Es
test %>% select(go, goTest, everything())
test$goTest == test$go

gcT <- shares %>% group_by(j_iso3) %>% summarise(gcT=mean(j_gcT))
colnames(gcT)[colnames(gcT)=="j_iso3"] <- "iso3"
test <- left_join(test, gcT)
test$goTest2 <- test$gcT + test$Es - test$deficit  # this one works
test %>% select(go, goTest, goTest2, everything()) %>% print(n=100)
test %>% select(go, goTest, goTest2, everything()) %>% filter(go!=goTest2) %>% print(n=100)
test$goTest2
test$go


# TEST BAY

sharesT <- shares %>% left_join(gdp, by=c("j_iso3"="iso3", "year"))

sharesT$j_gcT
test <- sharesT %>% group_by(j_iso3) %>%
  summarise(j_gcT=mean(j_gcT),
            gc=mean(gc),
            r=sum(r_ji),
            gdp=mean(gdp),
            Tshare=mean(Tshare))
test$Es <- (test$gdp + test$deficit) * (1 - test$Tshare)
test$test <- test$gc + test$r - test$Es  # this should equal j_gcT, but j_gcT seems to be much too high atm
test$test == test$j_gcT

gdpKor <- gdp %>% filter(iso3=="KOR") %>% mutate(test=gdp+r)

gdp$test <- ((1 - gdp$beta) * gdp$xexp + (1 - gdp$Tshare) * (gdp$gdp + gdp$r)) / gdp$gdp # this should be one (TODO: problem)

gdp %>% select(test, everything()) %>% arrange(test) %>% print(n=100)

# Everything here was computed assuming that no revenue was collected
# Need to recompute share of revenue spend on tradables, home share of spending, etc, where total income is gdp + r



# colSums(XM) * (1 - gdp$beta) + (1 - nu) * r / (gdp$gdp * nu)