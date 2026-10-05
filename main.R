source("src/omie_data.R")
source("src/generate_matrix.R")
source("src/LASSO.R")
source("src/Metrics.R")
source("src/Benchmarks.R")
# -----------------------------------------------------
#  GET DATA
# -----------------------------------------------------
omie_data=get_data()
# -----------------------------------------------------
# LEAR/LASSO Matrix Retrieval
# -----------------------------------------------------
lags=1:7
lear=generate_lag_matrix(omie_data,lags)
X=lear$X
Y=lear$Y
days=lear$days
nTotal=nrow(X)
nTest=28
nTrain=nTotal-nTest
i_dev=1:nTrain
i_Test=(nTrain+1):nTotal
colX=ncol(X)
# -----------------------------------------------------
# Training/Test Matrix Split
# -----------------------------------------------------
X_train=X[ i_dev,,drop=FALSE]
Y_train=Y[i_dev,,drop=FALSE]
X_test=X[i_Test,,drop=FALSE]
Y_test=Y[i_Test,,drop=FALSE]



# ------------------------------------------------------------
# TRAINING AND VALIDATION – LAMBDA PARAMETER SELECTION
# ------------------------------------------------------------
Lambda=get_lambda(X_train,Y_train,days)

# -----------------------------------------------------
# TEST
# -----------------------------------------------------
pred_test=test(X,Y,i_Test,Lambda$lambda_opt)

##########              GET TOMORROW'S PREDICTION               ##########
prediction(X,Y,Lambda$lambda_opt,omie_data)
#########
test_days = days[i_Test]
metrics_lasso=calc_metrics(Y_test,pred_test)
pred_d1=predict_naive(omie_data,test_days,1)
metrics_d1=calc_metrics(Y_test,pred_d1)
pred_d7=predict_naive(omie_data,test_days,7)
metrics_d7=calc_metrics(Y_test,pred_d7)
pred_4_week=predict_weekly_average(omie_data,test_days)
metrics_4_week=calc_metrics(Y_test,pred_4_week)



##########                  LASSO'S METRICS                     ##########
show_metrics_lasso(metrics_lasso)
##########                RESULTS VS BENCHMARKS                 ##########
show_mae_rmse_average(metrics_d1,metrics_d7,metrics_4_week,metrics_lasso)
##########     RESULTS VS BENCHMARKS COMPARISONS PER SEGMENTS   ##########
show_metrics_segments(metrics_d1,metrics_d7,metrics_4_week,metrics_lasso)
