In order to estimate the magnitude of policy barriers to trade, I must difference out the component of trade costs attributable to freight costs. However, freight costs are, at best, *partially* observed. I employ data from the United States Census Bureau and the Australian Bureau of Statistics on the c.i.f. and f.o.b. values of its imports.^[The Australian data are also used by @Shapiro2016 and @Adao2017.] The ratio of the c.i.f. value of goods to their f.o.b. value can then be taken as a measure of the ad valorem freight cost. I supplement these values with international data on the costs of *maritime* shipments from the OECD's [Maritime Transport Cost Dataset](https://doi.org/10.1787/data-00490-en) [@Korinek2011]. I also observe the transportation modes of imports (air, land, or sea) to the European Union, Japan, Brazil, Australia and the United States .^[Data from the United States come from the Census Bureau and are available on the website of [Peter Schott](http://faculty.som.yale.edu/peterschott/sub_international.htm). Data from the European Union are from [Eurostat](https://ec.europa.eu/eurostat). Data from Japan are from the government's statistical agency, [e-Stat](https://www.e-stat.go.jp/en/stat-search/files?page=1&toukei=00350300&bunya_l=16&tstat=000001013142&result_page=1&second=1). Data from Brazil come from the [ministry of trade and industry](http://comexstat.mdic.gov.br/en/home). Data from Australia are from the Australian Bureau of Statistics.]

Geographic covariates $\bm{Z}_{ij}$ include indicators of air and sea distances between $i$ and $j$, whether or not $i$ and $j$ are contiguous, and whether or not $i$ and/or $j$ are island countries. Sea distances are from [CERDI](http://www.ferdi.fr/en/indicator/cerdi-seadistance-database) [@Bertoli2016]. The remainder of these data are from CEPII's [GeoDist](http://www.cepii.fr/cepii/en/bdd_modele/presentation.asp?id=6) database [@Mayer2011].

To model international freight costs, assume there are $M$ categories of goods, indexed $m \in \left\{ 1, ..., M \right\}$ and $K$ modes of transportation, indexed $k \in \left\{ 1, ..., K \right\}$.

The total free on board (f.o.b.) value of imports of country $i$ from country $j$ is given by $X_{ij}$. The cost, insurance, and freight (c.i.f.) value of these goods is $\delta_{ij} X_{ij}$. These c.i.f. costs can be decomposed by product and mode of transporatation as follows
$$
\delta_{ij} X_{ij} = \sum_{m = 1}^M \delta_{ij}^m x_{ij}^m
$$
where
$$
\delta_{ij}^m x_{ij}^m = \sum_{k=1}^K \delta_{ij}^{m k} x_{ij}^{m k} \implies \delta_{ij}^m =  \sum_{k=1}^K \delta_{ij}^{m k} \frac{x_{ij}^{m k}}{x_{ij}^m}
$$

Let $\zeta_{ij}^{m k}$ denote the share of imports by $i$ from $j$ of good $m$ that travel by mode $k$
$$
\zeta_{ij}^{m k} = \frac{x_{ij}^{m k}}{x_{ij}^m}
$$

In the data, I observe product-level trade flows, $x_{ij}^m$, but observe only a subset of ad valorem freight costs by mode $\delta_{ij}^{m k}$ and mode shares $\zeta_{ij}^{m k}$.^[All these variables are aggregated at the HS-2 level.] I also observe bilateral geographic covariates $\bm{Z}_{ij}$ and product dummies $d^m \in \left\{ 0, 1 \right\}$ that may be predictive of freight costs and mode shares. To compute aggregate freight costs $\delta_{ij}$ for all country pairs in our sample, I seek functions
$$
g: \left\{ \bm{Z}_{ij}, d^m \right\} \rightarrow \delta_{ij}^{m k}
$$
$$
h: \left\{ \bm{Z}_{ij}, d^m \right\} \rightarrow \zeta_{ij}^{m k}
$$
from which I can compute 
$$
\hat{\delta}_{ij} \left( \bm{Z}_{ij}, \bm{d}_{ij} \right) = \frac{1}{X_{ij}} \sum_{m = 1}^M x_{ij}^m \sum_{k=1}^K g \left( \bm{Z}_{ij}, d^m \right) h \left( \bm{Z}_{ij}, d^m \right)
$$

Let $\tilde{\bm{\delta}}$ and $\tilde{\bm{\zeta}}$ denote sets of observed freight costs and mode shares. Let $\mathcal{G}$ denote the set of possible functions $g$ and $\mathcal{H}$ denote the set of possible functions $h$. I choose $g$ and $h$ to satisfy the following
\begin{equation} \label{eq:deltaG}
\begin{split} 
\hat{g}^m = \min_{g \in \mathcal{G}} & \quad \sum_{ \delta_{ij}^{m k} \in \tilde{\bm{\delta}} } \left( \delta_{ij}^{m k} - g \left( \bm{Z}_{ij}, d^m \right) \right)^2 \\
\text{subject to  } & \quad g \left( \bm{Z}_{ij}, d^m \right) \geq 1
\end{split}
\end{equation}
\begin{equation}
\begin{split} 
\hat{h} = \min_{h \in \mathcal{H}} & \quad \sum_{\zeta_{ij}^{m k} \in \tilde{\bm{\zeta}}} \left( \zeta_{ij}^{\ell k} - h \left( \bm{Z}_{ij}, d^m \right) \right)^2 \\
\text{subject to  } & \quad \sum_{k=2}^K h \left( \bm{Z}_{ij}, d^m \right) = 1
\end{split}
\end{equation}

I let $\mathcal{G}$ be the set of linear functions with polynomial time splines and $\mathcal{H}$ be the set of multinomial link functions, following @Shapiro2016. I impose the constraints in Equation \ref{eq:deltaG} ex post, replacing values violating the constraint with $1$.

This results in three functions $\hat{g}^m$ for each transportation mode (air, land, sea) and one function $\hat{h}$ that outputs predicted mode shares. The data used to estimate these functions is discussed in more detail below.