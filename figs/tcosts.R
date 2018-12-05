CP <- correlates %>% gather(tau, wtar, avc, key="cost_type", value="cost") %>% select(i_iso3, j_iso3, cost_type, cost)
CP <- CP %>% group_by(cost_type) %>% mutate(meanC=mean(cost)) %>% ungroup()

CP$cost_type <- ifelse(CP$cost_type=="tau", "A: Policy Barriers",
                       ifelse(CP$cost_type=="wtar", "C: Tariffs", "B: Freight Costs"))
CP <- CP %>% mutate(cost_type=reorder(cost_type, -meanC))

tCostsPlot <- ggplot(CP, aes(x=cost)) +
  geom_line(stat="density", size=1) +
  theme_classic() +
  geom_vline(aes(xintercept=meanC), lty=2) +
  facet_wrap(~cost_type, scales="free")