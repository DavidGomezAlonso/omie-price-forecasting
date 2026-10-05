generate_lag_matrix=function(data,lags=c(1,2,3,4,5,6,7)){
  num_days=ncol(data)
  days_available=(max(lags)+1):num_days
  numPredictors=length(lags)
  X=matrix(NA,nrow=length(days_available),ncol = numPredictors*96)
  Y=matrix(NA,nrow=length(days_available),ncol=96)
  for(i in seq_along(days_available)){
    d=days_available[i]
    row=c()
    for (j in seq_along(lags)){
      row=c(row,data[,d-lags[j]])
    }
    X[i,]=row
    Y[i,]=data[,d]
    
  }
  segment_names=sprintf("%02d",1:96)
  names_X=c()
  for(lag in lags){
    names_X=c(names_X,paste0("d",lag,"_",segment_names))
  }
  colnames(X)=names_X
  colnames(Y)=segment_names
  list(X=X,Y=Y,days=days_available)
}

