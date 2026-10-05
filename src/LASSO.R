library(glmnet)

# ------------------------------------------------------------
# TRAINING AND VALIDATION – LAMBDA PARAMETER SELECTION
# ------------------------------------------------------------


select_lambda=function(X_dev,Y_dev,q,days,initial_n=150){
  y=Y_dev[,q]
  n=nrow(X_dev)
  if (n<=initial_n){
    stop("Initial n too large")
  }
  initial_fit=glmnet(x=X_dev[1:initial_n,,drop=FALSE],y=y[1:initial_n],alpha=1,family = "gaussian",standardize = TRUE,intercept = TRUE)
  grid_lambda=initial_fit$lambda
  i_validation=(initial_n+1):n
  errors=matrix(NA,nrow=length(i_validation),ncol=length(grid_lambda))
  for (i in seq_along(i_validation)){
    d=i_validation[i]
    i_train=1:(d-1)
    model=glmnet(x=X_dev[i_train,,drop=FALSE],y=y[i_train],alpha = 1,lambda=grid_lambda,family = "gaussian",standardize = TRUE,intercept = TRUE)
    pred=predict(model,newx=X_dev[d,,drop=FALSE],s=grid_lambda)
    pred=as.numeric(pred)
    errors[i,]=abs(y[d]-pred)
  }
  colnames(errors)=paste("lambda",1:length(grid_lambda))
  row.names(errors)=paste("day",days[i_validation])
  mae_lambda=colMeans(errors)
  i_opt=which.min(mae_lambda)
  lambda_opt_q=grid_lambda[i_opt]
  list(lambda_opt=lambda_opt_q,lambda_grid=grid_lambda,mae_lambda=mae_lambda,errors=errors)
  
  
  
  
}

get_lambda=function(X_dev,Y_dev,days,initial_n=150){
  lambda_opt=numeric(96)
  lambda_results=vector("list",96)
  for(q in 1:96){
    cat("Selecting lambda for segment",q,"\n")
    result=select_lambda(X_dev,Y_dev,q,days,initial_n)
    lambda_results[[q]]=result
    lambda_opt[q]=result$lambda_opt
  }
  return(list(lambda_opt=lambda_opt,lambda_results=lambda_results))
  
}

# -----------------------------------------------------
# TEST
# -----------------------------------------------------

test=function(X,Y,i_Test,lambda_opt){
  nTest=length(i_Test)
  pred_test=matrix(NA,nrow=nTest,ncol=96)
  for (i in seq_along(i_Test)){
    d=i_Test[i]
    cat("Predicting test day",i,"of",nTest,"\n")
    iTrain=1:(d-1)
    for(q in 1:96){
      model=glmnet(x=X[iTrain,,drop=FALSE],y=Y[iTrain,q],alpha=1,lambda=lambda_opt[q],family = "gaussian",standardize = TRUE,intercept = TRUE)
      pred=predict(model,newx=X[d,,drop=FALSE],s=lambda_opt[q])
      pred_test[i,q]=as.numeric(pred)
    }
    
    
  }
  return(pred_test)
}


# -----------------------------------------------------
# GET TOMORROW'S PREDICTION
# -----------------------------------------------------
prediction=function(X,Y,lambda_opt,omie_data,lags){
  colX=ncol(X)
  nTotal=nrow(X)
  X_tomorrow=matrix(c(Y[nTotal,],X[nTotal,1:(colX-96)]),nrow=1)
  
  
  pred_tomorrow=matrix(NA,nrow=96,ncol=1)
  
  
  for(q in 1:96){
    cat("Predicting segment",q,"of 96\n")
    model=glmnet(x=X,y=Y[,q],alpha=1,lambda=lambda_opt[q],family="gaussian",standardize=TRUE,intercept=TRUE)
    pred=predict(model,newx=X_tomorrow,s=lambda_opt[q])
    pred_tomorrow[q,1]=as.numeric(pred)
  }
  
  rownames(pred_tomorrow)=rownames(omie_data)
  colnames(pred_tomorrow)=format(Sys.Date()+1,"%d/%m/%y")
  
  return(pred_tomorrow)
}


