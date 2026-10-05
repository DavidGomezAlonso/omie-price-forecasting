calc_metrics = function(real, pred) {
  error=real - pred
  list(MAE = mean(abs(error)),RMSE = sqrt(mean(error^2)),MAE_time = colMeans(abs(error)),RMSE_time = sqrt(colMeans(error^2)),
       MAE_day = rowMeans(abs(error)))
}

show_metrics_lasso=function(metrics_lasso){
  par(mfrow=c(2,2))
  plot(1:96,metrics_lasso$MAE_time,type = "l",xlab = "Segment",ylab = "MAE (€/MWh)",main = "LEAR's MAE by Segment")
  plot(1:96,metrics_lasso$RMSE_time,type = "l",xlab = "Segment",ylab = "RMSE (€/MWh)",main = "LEAR's RMSE by Segment")
  plot(metrics_lasso$MAE_day,type = "l",xlab = "Test day",ylab = "MAE (€/MWh)",main = "LEAR's Daily MAE")
  par(mfrow=c(1,1))
  
}



#### RESULTS VS BENCHMARKS ####

show_mae_rmse_average=function(metrics_d1,metrics_d7,metrics_4_week,metrics_lasso){
  results=data.frame(Models=c("Naive d-1","Naive d-7","4 week","LEAR-LASSO"),
                     MAE=c(metrics_d1$MAE,metrics_d7$MAE,metrics_4_week$MAE,metrics_lasso$MAE),
                     RMSE = c(metrics_d1$RMSE,metrics_d7$RMSE,metrics_4_week$RMSE,metrics_lasso$RMSE))
  return(results)
}

#### RESULTS AND BENCHMARKS COMPARISON BY SEGMENTS ####
show_metrics_segments=function(metrics_d1,metrics_d7,metrics_4_week,metrics_lasso){
  matplot(1:96,cbind(metrics_d1$MAE_time,metrics_d7$MAE_time,metrics_4_week$MAE_time,metrics_lasso$MAE_time),type = "l",
          lty = 1,xlab = "Segment",ylab = "MAE (€/MWh)",main = "MAE by segment",col = 1:4,xaxt="n")
  
  axis(1,at=seq(1,96,by=2))
  
  legend("topleft",legend = c("Naive d-1","Naive d-7","4 weeks","LEAR-LASSO"),lty = 1,col=1:4)
  
  
}


