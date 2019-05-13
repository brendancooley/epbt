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