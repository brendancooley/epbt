Demand for variety $\omega$ is
$$
q_i(\omega) = \alpha_{h(\omega)} p_i(\omega)^{-\sigma} E_i^q P_i^{\sigma - 1}
$$
and expenditure is
$$
x_i(\omega) = p_i(\omega) q_i(\omega) = \alpha_{h(\omega)} p_i(\omega)^{1-\sigma} E_i^q P_i^{\sigma - 1}
$$

With constant prices in each basic heading, total spending on goods in category $k$ is
\begin{align*}
x_{ik} &= \int_{\omega \in \Omega_k} \alpha_{h(\omega)} p_i(\omega)^{1-\sigma} E_i^q P_i^{\sigma - 1} d \omega \\
&= \int_{\omega \in \Omega_k} \alpha_k p_{ik}^{1 - \sigma} E_i^q P_i^{\sigma - 1} d \omega \\
&= \frac{1}{K} \alpha_k p_{ik}^{1 - \sigma} E_i^q P_i^{\sigma - 1}
\end{align*}
The share of $i$'s tradables expenditure spent on goods in category $k$ is 
$$
\lambda_{ik} = \frac{x_{ik}}{E_i^q} = \frac{1}{K} \alpha_k p_{ik}^{1 - \sigma} P_i^{\sigma - 1}
$$

Normalizing $\alpha_0 = 1$ gives
$$
\frac{\lambda_{ik}}{\lambda_{i0}} = \alpha_k \left( \frac{p_{ik}}{p_{i0}} \right)^{1 - \sigma}
$$

Consumers are subject to relative demand shocks $\epsilon_{ik}$ that are i.i.d. across countries and good categories. Observed relative expenditure is then
\begin{align*}
\frac{\lambda_{ik}}{\lambda_{i0}} &= \alpha_k \epsilon_{ik} \left( \frac{p_{ik}}{p_{i0}} \right)^{1 - \sigma} \\
\Delta \lambda_{ik} &= \alpha_k \epsilon_{ik} \left( \Delta p_{ik} \right)^{1 - \sigma}
\end{align*}
Taking logs,
$$
\ln \Delta \lambda_{ik} = \ln \alpha_k + (1 - \sigma) \ln \Delta p_{ik} + \ln \epsilon_{ik}
$$
Rearranging
\begin{align*}
\ln \epsilon_{ik} &= \ln \Delta \lambda_{ik} - (1 - \sigma) \ln \Delta p_{ik} - \ln \alpha_k \\
&= \varphi_{ik} - \gamma_k
\end{align*}
where
$$
\varphi_{ik} = \ln \Delta \lambda_{ik} - (1 - \sigma) \ln \Delta p_{ik}
$$
and $\gamma_k = \ln \alpha_k$.

Let $\ln \epsilon_{ik} \sim \mathcal{N}(0, \sigma_{\epsilon}^2)$. Then, a weighted least squares estimate for $\ln \alpha_k$ solves
$$
\hat{\gamma}_k = \argmin_{\gamma_k} \sum_i w_i \epsilon_{ik}^2 = \sum_i w_i \left( \varphi_{ik} - \gamma_k \right)^2
$$
with $\sum_i w_i = 1$ and is given by
$$
\hat{\gamma}_k = \sum_i w_i \varphi_{ik}
$$
I use as weights each country's total expenditure on tradeables, $E_i^q$. The theory-consistent estimate for the price index can then be calculated as
$$
\hat{P}_i = \left( \int_\omega \hat{\alpha}_{h(\omega)} p_i(\omega)^{1 - \sigma} \right)^{\frac{1}{1 - \sigma}} = \frac{1}{K} \left( \sum_k \hat{\alpha}_k p_{ik}^{1 - \sigma} \right)^{\frac{1}{1 - \sigma}}
$$