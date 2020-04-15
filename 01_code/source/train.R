trainEN <- function(dataX, dataY, weights=rep(1, nrow(dataX))) {
  
  A <- seq(0, 1, .1)
  
  mseVec <- c()
  
  for (i in A) {
    
    model <- cv.glmnet(dataX, dataY, alpha=i, weights=weights)
    
    print(model$lambda.min)
    i <- which(model$lambda == model$lambda.min)
    mse <- model$cvm[i]
    
    mseVec <- c(mseVec, mse)
  }
  
  astar <- A[which.min(mseVec)]
  
  out <- list(astar=astar, mseVec=mseVec)
  
  return(out)
}