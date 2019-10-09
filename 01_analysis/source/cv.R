cvMARS <- function(dataX, dataY, N=10, K=5, d=2, np=NULL, weights=NULL) {
  
  mseVec <- c()
  
  for (i in 1:N) {
    rows <- seq(1, nrow(dataX))
    sampleN <- floor(nrow(dataX) / K)
    sampleVec <- sample(rows, sampleN)
    
    if (is.null(weights)) {
      W <- rep(1, nrow(dataXtrain))
    }
    else {
      W <- weights[-sampleVec]
    }
    
    dataXtest <- dataX[sampleVec, ]
    dataXtrain <- dataX[-sampleVec, ]
    
    dataYtest <- dataY[sampleVec, ]
    dataYtrain <- dataY[-sampleVec, ]
    
    mars <- earth(x=dataXtrain, y=dataYtrain, degree=d, nprune=np)
    
    predY <- predict(object=mars, newdata=dataXtest)
    
    sqer <- (dataYtest - predY)^2
    
    mse <- mean(sqer)
    
    mseVec <- c(mseVec, mse)
  }
  
  out <- mean(mseVec)

  return(out)
}

cvLM <- function(dataX, dataY, N=10, K=5, weights=NULL) {
  
  mseVec <- c()
  
  for (i in 1:N) {
    
    rows <- seq(1, nrow(dataX))
    sampleN <- floor(nrow(dataX) / K)
    sampleVec <- sample(rows, sampleN)
    
    dataXtest <- dataX[sampleVec, ]
    dataXtrain <- dataX[-sampleVec, ]
    
    if (is.null(weights)) {
      W <- rep(1, nrow(dataXtrain))
    }
    else {
      W <- weights[-sampleVec]
    }
    
    dataYtest <- dataY[sampleVec, ]
    dataYtrain <- dataY[-sampleVec, ]
    
    dataTrain <- bind_cols(dataYtrain, dataXtrain)
    colnames(dataTrain)[1] <- "y"
    # print(dataTest)
    
    model <- lm(y ~ ., data = dataTrain, weights = W)
    
    predY <- predict(model, newdata=dataXtest)
    
    Wtest <- weights[sampleVec]
    wfrac <- Wtest / sum(Wtest)
    wsqer <- (dataYtest - predY)^2 * wfrac

    wmse <- sum(wsqer)  # sum provides mse because weights already included
    
    mseVec <- c(mseVec, wmse)
  }
  
  out <- mean(mseVec)

  return(out)
}