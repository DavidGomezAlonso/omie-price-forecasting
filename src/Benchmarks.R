######### BENCHMARKS LAGS ######### 
predict_naive=function(omie_data,test_days,lag){
  nTest=length(test_days)
  pred=matrix(NA,nrow=nTest,ncol=96)
  for (i in seq_along(test_days)) {
    d = test_days[i]
    pred[i, ] = omie_data[, d - lag]
  }
  return(pred)
  
}


######### BENCHMARKS WEEKLY AVERAGE ######### 
predict_weekly_average=function(omie_data,test_days){
  nTest=length(test_days)
  pred_4_week=matrix(NA,nrow = nTest,ncol = 96)
  for (i in seq_along(test_days)) {
    d =test_days[i]
    pred_4_week[i, ] = (omie_data[, d - 7] +omie_data[, d - 14] +omie_data[, d - 21] +omie_data[, d - 28]) / 4
  }
  return(pred_4_week)
  
}

