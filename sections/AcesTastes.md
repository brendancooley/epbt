Demand for variety $\omega$ is
$$
q_i(\omega) = \tilde{\alpha}_{i, h(\omega)} p_i(\omega)^{-\sigma} E_i^q P_i^{\sigma - 1}
$$
and expenditure is
$$
x_i(\omega) = p_i(\omega) q_i(\omega) = \tilde{\alpha}_{i, h(\omega)} p_i(\omega)^{1-\sigma} E_i^q P_i^{\sigma - 1} . 
$$

With constant prices in each basic heading, total spending on goods in category $k$ is
\begin{align*}
x_{ik} &= \int_{\omega \in \Omega_k} \tilde{\alpha}_{i, h(\omega)} p_i(\omega)^{1-\sigma} E_i^q P_i^{\sigma - 1} d \omega \\
&= \int_{\omega \in \Omega_k} \tilde{i, \alpha}_k p_{ik}^{1 - \sigma} E_i^q P_i^{\sigma - 1} d \omega \\
&= \frac{1}{K} \tilde{\alpha}_{ik} p_{ik}^{1 - \sigma} E_i^q P_i^{\sigma - 1}
\end{align*}
and the share of $i$'s tradables expenditure spent on goods in category $k$ is 
$$
\lambda_{ik} = \frac{x_{ik}}{E_i^q} = \frac{1}{K} \tilde{\alpha}_{ik} p_{ik}^{1 - \sigma} P_i^{\sigma - 1} .
$$

With the United States as the base country, $p_{\text{US}, k} = 1$ for all $k$. Differencing by $\lambda_{\text{US}, k}$ then gives
\begin{align*}
\frac{\lambda_{ik}}{\lambda_{\text{US}, k}} &= \frac{\tilde{\alpha}_{ik}}{\tilde{\alpha}_{\text{US}, k}} p_{ik}^{1-\sigma} P_i^{\sigma - 1}
\\
&= \frac{\epsilon_{ik}}{\epsilon_{\text{US},k}} p_{ik}^{1-\sigma} P_i^{\sigma - 1}
\end{align*}
where I enforce the normalization that $P_{US} = 1$. Taking logs,
$$
\ln \left( \frac{\lambda_{ik}}{\lambda_{\text{US}, k}} \right) = \ln \left( \frac{\epsilon_{ik}}{\epsilon_{\text{US},k}} \right) + (1 - \sigma) \ln \left( p_{ik} \right) + (\sigma - 1) \ln \left( P_i \right)
$$
which can be rearranged as
$$
\ln p_{ik} = \frac{1}{1 - \sigma} \ln \left( \frac{\lambda_{ik}}{\lambda_{\text{US}, k}} \right) + \ln \left( P_i \right) + \frac{1}{\sigma - 1} \ln \left( \frac{\epsilon_{ik}}{\epsilon_{\text{US},k}} \right) .
$$
Because $\E [ \epsilon_{ik} ] = 1$,
$$
\E \left[ \ln p_{ik} \right] = \frac{1}{1 - \sigma} \ln \left( \frac{\lambda_{ik}}{\lambda_{\text{US}, k}} \right) + \ln \left( P_i \right) 
$$
which gives a moment condition that I estimate via ordinary least squares.