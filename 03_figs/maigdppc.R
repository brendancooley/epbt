# code_dir <- "01_code/"
source(paste0("../", code_dir, "params.R"))

library(tidyverse)
library(ggrepel)

trimaiY <- read_csv(paste0(resultsdir, "trimaiY.csv"))
gdp <- read_csv(paste0(cleandir, "gdp.csv"))
pop <- read_csv(paste0(cleandir, "pop.csv"))

trimaiY <- left_join(trimaiY, gdp)
trimaiY <- left_join(trimaiY, pop)

trimaiY$gdppc <- trimaiY$gdp / trimaiY$pop

maigdppcPlot <- ggplot(data=trimaiY, aes(x=gdppc, y=MAI, label=iso3))  +
  geom_point() +
  geom_text_repel() +
  geom_smooth(method='lm', lty=2, se=FALSE, color=bcOrange, size=.75) +
  xlab('GDP Per Capita') +
  ylab('Market Access Index') +
  ggtitle(paste0('National Income and Market Access, ', Y)) +
  theme_classic() +
  theme(aspect.ratio=1)