### SETUP ###

# shiny <- FALSE
# EUD <- FALSE
source("../01_code/params.R")
# ccodes <- read_csv(ccodesPath)

libs <- c('tidyverse', "plotly", "ggvis")
ipak(libs)


M <- 24

tau_quantiles <- read_csv(tau_quantiles_path)
ccodes <- ccodesAll

### PLOT ###

grid.col <- "#E8E8E8"

tauq_ci <- tau_quantiles %>% ggplot(aes(x=q500, y=factor(i_iso3, levels=ccodes))) + 
  geom_point(size=.5) +
  geom_segment(aes(x=q025, xend=q975, y=factor(i_iso3, levels=ccodes), yend=factor(i_iso3, levels=ccodes))) +
  geom_vline(xintercept=1, lty=2) +
  theme_classic() +
  theme(legend.position="none") +
  scale_y_discrete(limits=rev(levels(tau_quantiles$i_iso3))) +
  theme(axis.text.y = element_text(size=5),
        panel.grid.major.x=element_line(c(2, 4, 6), color=grid.col),
        panel.grid.major.y=element_line(rev(levels(tau_quantiles$i_iso3)), color=grid.col)
        ) +
  labs(x="Policy Barrier", y="Trade Partner", title="Policy Barriers, Uncertainty (by Importer)") +
  facet_wrap(~j_iso3, ncol=4)

ggsave(paste0("../", "03_figs/", "tauq_ci.pdf"), tauq_ci, scale=1)
