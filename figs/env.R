# setwd('..')

Y <- 2005
EUntmY <- read_csv("estimation/clean/EUntmY.csv") %>% pull(.)
tarYval <- read_csv("estimation/clean/tarYval.csv") %>% pull(.)

gdp <- read_csv("estimation/clean/gdp.csv")
pop <- read_csv("estimation/clean/pop.csv")
delta <- read_csv('estimation/clean/delta.csv') %>% filter(year==Y)
tau <- read_csv("estimation/results/tauY.csv")
tar <- read_csv("estimation/clean/tarY.csv")
correlates <- read_csv("estimation/results/correlates.csv")
tauHMY <- read_csv("estimation/results/tauHMY.csv")
trimaiY <- read_csv("estimation/results/triMaiY.csv")

# global variables
N <- read_csv("estimation/clean/ccodes.csv") %>% pull(.) %>% length()
gdpSample <- gdp %>% filter(iso3 != "ROW", year==Y) %>% pull(gdp) %>% sum()
gdpWorld <- gdp %>% filter(year==Y) %>% pull(gdp) %>% sum()
sigma <- read_csv("estimation/clean/sigma.csv") %>% pull(.)
sigmaAlt <- read_csv("estimation/clean/sigmaAlt.csv") %>% pull(.)