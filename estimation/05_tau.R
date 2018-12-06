### TODO ###

# why can measure show up less than one?
  # controlling the scale on the relative price indices might work
  # simple solution: just choose scale parameter such that tau almost always positive
# Korea and Japan are outliers because they're importing a lot of (presumably) cheap intermediates that don't show up in EIU data
# Producer price indices? Trick is we need to pull out tradeable portion
  # is it possible to just use trade in final goods?
  # problem is that we don't have dyadic intermediates imports for OECD IOTS

# Change sigma to theta

### SETUP ###

rm(list=ls())

sourceFiles <- list.files("source/")
for (i in sourceFiles) {
  source(paste0("source/", i))
}

# devtools::install_github("timelyportfolio/d3treeR")
libs <- c('tidyverse', 'latex2exp', 'ggrepel', 'ggthemes', "scales", "treemap", "d3treeR", 
          "data.tree", "jsonlite", "ggraph", "igraph", "viridis")
ipak(libs)

# Y <- 2011

tau <- function(Lji, Lii, delta, Pj, Pi, sigma) {
  return((Lji / Lii)^(1/(1-sigma)) * Pj / Pi * 1 / delta)
}

sigma <- 6
sigmaAlt <- 11
write_csv(sigma %>% as.data.frame(), "clean/sigma.csv")
write_csv(sigmaAlt %>% as.data.frame(), "clean/sigmaAlt.csv")

Y <- 2005

### DATA ###

# flows and predicted costs
X <- read_csv('clean/delta.csv') %>% filter(year==Y)

# prices
P <- read_csv('clean/priceIndex.csv') %>% select(iso3, year, P) %>% filter(year==Y)
Tshare <- read_csv('clean/priceIndex.csv') %>% select(iso3, year, Tshare) %>% filter(year==Y)

# gross consumption
gc <- read_csv("clean/gc.csv") %>% filter(year==Y)
gc$gc <- gc$gc * 1000
colnames(gc)[colnames(gc)=="gc"] <- "j_tot_exp"

# gdp
gdp <- read_csv("clean/gdp.csv") %>% filter(year==Y)
gdp$gdp <- gdp$gdp * 1000
gdp <- left_join(gdp, Tshare)
gdp$gdpS <- gdp$gdp * (1 - gdp$Tshare)
gdp <- gdp %>% select(iso3, year, gdpS)
colnames(gdp)[colnames(gdp)=="gdpS"] <- "j_gdpS"

# get home_exp and own share
X <- left_join(X, gc, by=c("year"="year", "j_iso3"="iso3"))
colnames(gc)[colnames(gc)=="j_tot_exp"] <- "i_tot_exp"
X <- left_join(X, gc, by=c("year"="year", "i_iso3"="iso3"))
X$delta <- X$avc
X$val <- X$fob

# correct for tradable shares
X <- left_join(X, gdp, by=c("year"="year", "j_iso3"="iso3"))
colnames(gdp)[colnames(gdp)=="j_gdpS"] <- "i_gdpS"
X <- left_join(X, gdp, by=c("year"="year", "i_iso3"="iso3"))
X$j_gcT <- X$j_tot_exp - X$j_gdpS
X$i_gcT <- X$i_tot_exp - X$i_gdpS

Ximp <- X %>% group_by(i_iso3, year) %>%
  summarise(i_tot_imp=sum(fob),
            i_gcT=mean(i_gcT))

# Ximp <- left_join(Ximp, gc, by=c("i_iso3"="iso3", "year"="year"))
# Ximp <- left_join(Ximp, gdp, by=c("i_iso3"="iso3", "year"="year"))
Ximp$i_home_expT <- Ximp$i_gcT - Ximp$i_tot_imp
# Ximp$i_home_expT <- Ximp$i_home_exp - Ximp$gdpS
Ximp <- Ximp %>% select(i_iso3, year, i_home_expT)

X <- left_join(X, Ximp, by=c("i_iso3", "year"))

colnames(Ximp) <- c("j_iso3", "year", "j_home_expT")

X <- left_join(X, Ximp, by=c("j_iso3", "year"))


# calculate shares of total tradable expenditure
X$Lji <- X$val / X$j_gcT
X$Lii <- X$i_home_expT / X$i_gcT
X$Ljj <- X$j_home_expT / X$j_gcT

# append price indices
colnames(P) <- c("i_iso3", "year", "Pi")
X <- left_join(X, P)
colnames(P) <- c("j_iso3", "year", "Pj")
X <- left_join(X, P)

X$tau <- tau(X$Lji, X$Lii, X$delta, X$Pj, X$Pi, sigma)
X$tauAlt <- tau(X$Lji, X$Lii, X$delta, X$Pj, X$Pi, sigmaAlt)

Xtau <- X %>% select(i_iso3, j_iso3, year, tau, tauAlt)

# export
write_csv(Xtau, "results/tauY.csv")


# calculate TRI and MAI
# gc weights, reflects value of markets, not value of trade
TRI <- X %>% filter(i_iso3 != j_iso3) %>% group_by(j_iso3, year) %>%
  summarise(
    tau=weighted.mean(tau, i_gcT, na.rm = T)
  )
TRI$i_iso3 <- "TRI"
TRI %>% filter(year==2011) %>% print(n=30)

# calculate TRI and MAI
MAI <- X %>% filter(i_iso3 != j_iso3) %>% group_by(i_iso3, year) %>%
  summarise(
    tau=weighted.mean(tau, j_gcT, na.rm=T)
  )
MAI$j_iso3 <- "MAI"
MAI %>% filter(year==2011) %>% print(n=30)



### PLOTS ###
tauHM <- bind_rows(list(Xtau, TRI, MAI))
tauHMY <- tauHM %>% filter(year==Y)

write_csv(tauHMY, "results/tauHMY.csv")

# TRI and MAI
trimai <- left_join(TRI %>% select(j_iso3, year, tau), MAI %>% select(i_iso3, year, tau), by=c("j_iso3"="i_iso3", "year")) %>% ungroup()
colnames(trimai) <- c("iso3", "year", "TRI", "MAI")
trimaiY <- trimai %>% filter(year==Y)

write_csv(trimaiY, "results/trimaiY.csv")












### SCRATCH ###
tauHMY <- read_csv("results/tauHMY.csv")
Y <- 2005

ccodes <- tauHMY$i_iso3 %>% unique() %>% setdiff("TRI")

tauHMY$i_iso3 <- factor(tauHMY$i_iso3, levels=c(sort(ccodes), "TRI"))
tauHMY$j_iso3 <- factor(tauHMY$j_iso3, levels=c(sort(ccodes), "MAI"))

i_iso3 <- unique(tauHMY$i_iso3)
j_iso3 <- unique(tauHMY$j_iso3)

x <- seq(0, 1, length = 25)
hmColors <- tableau_seq_gradient_pal("Orange-Gold")(x)

hm <- ggplot(tauHMY, aes(x=i_iso3, y=j_iso3, fill=tau)) +
  geom_tile(colour="white", width=.9, height=.9) +
  scale_fill_gradient(low=hmColors[1], high=hmColors[length(hmColors)], trans="log", breaks=c(1, max(tauHMY$tau)), labels=c("Low", "High"), guide="colorbar") +
  geom_segment(y=length(i_iso3)-.5, yend=length(j_iso3)-.5, x=.5, xend=length(i_iso3)+.5) +
  geom_segment(y=.5, yend=length(j_iso3)+.5, x=length(i_iso3)-.5, xend=length(i_iso3)-.5) +
  labs(x='Exporter', y='Importer', title=paste0('Policy Barriers to Trade, ', Y, " (Log Scale)")) +
  labs(fill="Policy Barrier") +
  theme_classic() +
  coord_fixed() +
  theme(axis.text.x=element_text(angle=60, hjust=1),
        axis.ticks.y=element_blank(),
        axis.ticks.x=element_blank(),
        axis.line.y=element_blank(),
        axis.line.x=element_blank())




### CIRCLE PACKING TREE MAPS


# https://stackoverflow.com/questions/33644266/visualizing-hierarchical-data-with-circle-packing-in-ggplot2
Xlambda <- X %>% select(i_iso3, j_iso3, Lji, Ljj, j_gcT) %>% arrange(j_iso3)
Xlambda$LjiX <- Xlambda$Lji * Xlambda$j_gcT
Xlambda$ij <- paste0(Xlambda$i_iso3, "-", Xlambda$j_iso3)
Xlambda %>% filter(LjiX > j_gcT)

# We need a data frame giving a hierarchical structure. Let's consider the flare dataset:
edges <- Xlambda %>% select(j_iso3, ij)
colnames(edges) <- c("from", "to")

# Usually we associate another dataset that give information about each node of the dataset:
Xlambda$j_iso3_2 <- Xlambda$j_iso3
v1 <- Xlambda %>% select(j_iso3, j_iso3_2, j_gcT) %>% unique()
colnames(v1) <- c("name", "fill", "share")
v1$color <- "black"
v2 <- Xlambda %>% select(ij, i_iso3, LjiX)
colnames(v2) <- c("name", "fill", "share")
v2$color <- "black"

vertices <- bind_rows(v1, v2)
vertices <- vertices %>% add_row(name="origin", share=0, fill="white", color="white")

edgesO <- data.frame("origin", Xlambda$j_iso3)
colnames(edgesO) <- c("from", "to")

edges <- bind_rows(edges, edgesO)

# Then we have to make a 'graph' object using the igraph library:
mygraph <- graph_from_data_frame(edges, vertices=vertices)

# Make the plot
ggraph(mygraph, layout = 'circlepack', weight="share") + 
  geom_node_circle(aes(fill = as.factor(depth), color = as.factor(depth))) +
  scale_fill_manual(values=c("0" = "white", "1" = viridis(4)[1], "2" = viridis(4)[2])) +
  scale_color_manual(values=c("0" = "white", "1" = "black", "2" = "black")) +
  theme_void()




edges=flare$edges

# Usually we associate another dataset that give information about each node of the dataset:
vertices = flare$vertices

# Then we have to make a 'graph' object using the igraph library:
mygraph <- graph_from_data_frame( edges, vertices=vertices )

# Make the plot
ggraph(mygraph, layout = 'circlepack') + 
  geom_node_circle() +
  theme_void()

ggraph(mygraph, layout='dendrogram', circular=TRUE) + 
  geom_edge_diagonal() +
  theme_void() +
  theme(legend.position="none")

ggraph(mygraph, layout='dendrogram', circular=FALSE) + 
  geom_edge_diagonal() +
  theme_void() +
  theme(legend.position="none")

ggraph(mygraph, 'treemap', weight = 'size') + 
  geom_node_tile(aes(fill = depth), size = 0.25) +
  theme_void() +
  theme(legend.position="none")

ggraph(mygraph, 'partition', circular = TRUE) + 
  geom_node_arc_bar(aes(fill = depth), size = 0.25) +
  theme_void() +
  theme(legend.position="none")

ggraph(mygraph) + 
  geom_edge_link() + 
  geom_node_point() +
  theme_void() +
  theme(legend.position="none")

Xlambda %>% mutate_each_(funs(factor), c("i_iso3", "j_iso3"))

indexList <- c("i_iso3", "j_iso3")
treeData <- treemap(Xlambda, index=indexList, vSize="LjiX", type="value", fun.aggregate = "sum",
                    palette = 'RdYlBu')
