priceIndex <- function(alpha, p, sigma) {
  sum(alpha * p^(1 - sigma))^(1 / (1 - sigma))
}