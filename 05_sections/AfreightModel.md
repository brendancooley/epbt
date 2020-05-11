I build a simple model of demand for transportation services in order to estimate freight costs. There are $M$ sectors, indexed $m \in \left\{ 1, ..., M \right\}$ and $K$ modes of transportation (air, sea, land), indexed $k \in \left\{ 1, ..., K \right\}$. There is a mass of exporters within each country-sector. The cost of shipping a good from sector $m$ from country $i$ to country $j$ via mode $k$ is $\delta_{ij}^{mk}(\bm{Z}_ij)$ where $\bm{Z}_{ij}$ is a vector storing geographic covariates including indicators of air and sea distances between $i$ and $j$, and whether or not $i$ and $j$ are contiguous.

Exporters have preferences over the mode of transit and cost of freight. Let 
$$
V_{ij}^{mk} = \tilde{\beta}_0 \delta_{ij}^{mk}(\bm{Z}_{ij}) + \tilde{\beta}_k + \eta_{ij}^{km}
$$
where $\eta_{ij}^{km}$ is a Type-I extreme value-distributed preference shock with $\E [\eta_{ij}^{km}] = 0$. $\tilde{\beta}_k$ modulates exporters' relative preference for mode $k$, independent of it's cost. This is a simple logit model of mode choice a la @Mcfadden1974. Under these assumptions, the share of exporters in sector $k$ that choose to ship from $j$ to $i$ via mode $m$ is
\begin{equation} \label{eq:logitShares}
\zeta_{ij}^{m k} = \frac{\exp \left( \tilde{\beta}_0 \delta_{ij}^{mk}(\bm{Z}_{ij}) + \tilde{\beta}_k \right)}{\sum_{k^\prime=1}^K \exp \left( \tilde{\beta}_0 \delta_{ij}^{mk^\prime}(\bm{Z}_{ij}) + \tilde{\beta}_{k^\prime} \right)} .
\end{equation}
I impose natural technological constraints on this function, prohibiting shipment by sea to landlocked countries and shipment by land to islands or across continents.^[Where Eurasia is treated as an aggregate.]

I model $\delta_{ij}^{mk}(\bm{Z}_{ij})$ as linear in distance and contiguity and sector (HS2) fixed effects.^[I also smooth the model's predictions over years using a polynomial spline.] Parameter estimates for each mode are reported in the next section.

I obtain estimates for $\tilde{\beta}_0$ and $\tilde{\beta}_k$ by taking the log of \ref{eq:logitShares}, differencing with respect to a base transportation mode, and estimating the resulting linear equation via ordinary least squares. With parameter estimates in hand, I can compute predictions for total trade costs by aggregating over sectors and projecting out of sample. 

The total free on board (f.o.b.) value of imports of country $i$ from country $j$ is given by $X_{ij}$. The cost, insurance, and freight (c.i.f.) value of these goods is $\delta_{ij} X_{ij}$. These c.i.f. costs can be decomposed by product and mode of transporatation as follows
$$
\delta_{ij} X_{ij} = \sum_{m = 1}^M \delta_{ij}^m x_{ij}^m
$$
where
$$
\delta_{ij}^m x_{ij}^m = \sum_{k=1}^K \delta_{ij}^{m k} x_{ij}^{m k} \implies \delta_{ij}^m =  \sum_{k=1}^K \delta_{ij}^{m k} \frac{x_{ij}^{m k}}{x_{ij}^m} .
$$

Recall that $\zeta_{ij}^{m k}$ is the share of imports by $i$ from $j$ of good $m$ that travel by mode $k$
$$
\zeta_{ij}^{m k} = \frac{x_{ij}^{m k}}{x_{ij}^m} .
$$

With these terms defined, total predicted freight costs can be computed as 
$$
\hat{\delta}_{ij} \left( \bm{Z}_{ij} \right) = \frac{1}{X_{ij}} \sum_{m = 1}^M x_{ij}^m \sum_{k=1}^K \zeta_{ij}^{m k}\left( \delta_{ij}^{mk}(\bm{Z}_{ij}) \right) \delta_{ij}^{mk}(\bm{Z}_{ij}) .
$$

