* Andrea Bruckner
  PREDICT 410, Sec 55
  Winter 2016
  Assignment 6
;

********************************************************************;
* Preliminary Steps;
********************************************************************;

* Access library where stock portfolio data set is stored;
libname mydata '/scs/crb519/PREDICT_410/SAS_Data/' access=readonly;
proc datasets library=mydata; run; quit;

********************************************************************;
* Step 1;
********************************************************************;

* Set stock portfolio data set to short name;
data temp;
set mydata.stock_portfolio_data;
run;

proc contents data=temp; run;
proc print data=temp (obs=10); run;

* AA	BAC	BHI	CVX	DD	DOW	DPS	GS	HAL	HES	HON	HUN	JPM	KO	MMM	MPC	PEP	SLB	WFC	XOM	VV;

proc sort data=temp; by date; run; quit;
data temp;
set temp;
* Compute the log-returns - log of the ratio of today's price
to yesterday's price;
* Note that the data needs to be sorted in the correct
direction in order for us to compute the correct return;
return_AA = log(AA/lag1(AA));
return_BAC = log(BAC/lag1(BAC));
* Continue to compute the log-returns for all of the stocks;
return_BHI = log(BHI/lag1(BHI));
return_CVX = log(CVX/lag1(CVX));
return_DD = log(DD/lag1(DD));
return_DOW = log(DOW/lag1(DOW));
return_DPS = log(DPS/lag1(DPS));
return_GS = log(GS/lag1(GS));
return_HAL = log(HAL/lag1(HAL));
return_HES = log(HES/lag1(HES));
return_HON = log(HON/lag1(HON));
return_HUN = log(HUN/lag1(HUN));
return_JPM = log(JPM/lag1(JPM));
return_KO = log(KO/lag1(KO));
return_MMM = log(MMM/lag1(MMM));
return_MPC = log(MPC/lag1(MPC));
return_PEP = log(PEP/lag1(PEP));
return_SLB = log(SLB/lag1(SLB));
return_WFC = log(WFC/lag1(WFC));
return_XOM = log(XOM/lag1(XOM));

* Name the log-return for VV as the response variable;
response_VV = log(VV/lag1(VV));
run;
proc print data=temp(obs=10); run; quit;
*The log-returns have only 501 observations instead of 502 because they were created by
computing the ratio from the next day to the previous day. Day 1 doesn't have a previous day
and therefore contains missing return values/a blank row.;

********************************************************************;
* Step 2;
********************************************************************;

* We can use ODS TRACE to print out all of the data sets available to ODS for a particular SAS procedure.;
* We can also look these data sets up in the SAS User's Guide in the chapter for the selected procedure.;
*ods trace on;
ods output PearsonCorr=portfolio_correlations;
proc corr data=temp;
*var return: with response_VV;
var return_:;
with response_VV;
run; quit;
*ods trace off;
proc print data=portfolio_correlations; run; quit;
* This prints the p-values of the log-returns in addition to the correlation between the response and log-returns;

********************************************************************;
* Step 3;
********************************************************************;

data wide_correlations;
set portfolio_correlations (keep=return_:); * This gets rid of the p-values;
run;

* Note that wide_correlations is a 'wide' data set and we need a 'long' data set;
* We can use PROC TRANSPOSE to convert data from one format to the other;
proc transpose data=wide_correlations out=long_correlations;
run; quit;

data long_correlations;
set long_correlations;
tkr = substr(_NAME_,8,3); * Little SAS pg 78-19. What does 8 mean? This does not seem right:
The correlation column is 7 characters, so the tkr column needs to start at the 8th character
and it needs to be 3 characters long to fit the names of the stocks;
drop _NAME_;
rename COL1=correlation;
run;

proc print data=long_correlations; run; quit;

********************************************************************;
* Step 4;
********************************************************************;

* Merge on sector id and make a colored bar plot;
data sector;
input tkr $ 1-3 sector $ 4-35; * numbers define how many characters per column;
datalines;
AA Industrial - Metals
BAC Banking
BHI Oil Field Services
CVX Oil Refining
DD Industrial - Chemical
DOW Industrial - Chemical
DPS Soft Drinks
GS Banking
HAL Oil Field Services
HES Oil Refining
HON Manufacturing
HUN Industrial - Chemical
JPM Banking
KO Soft Drinks
MMM Manufacturing
MPC Oil Refining
PEP Soft Drinks
SLB Oil Field Services
WFC Banking
XOM Oil Refining
VV Market Index
;
run;
proc print data=sector; run; quit;
proc sort data=sector; by tkr; run;
proc sort data=long_correlations; by tkr; run;
data long_correlations;
merge long_correlations (in=a) sector (in=b);
by tkr;
if (a=1) and (b=1);
run;

proc print data=long_correlations; run; quit;

* Make Grouped Bar Plot;
* p. 48 Statistical Graphics Procedures By Example;
ods graphics on;
title 'Correlations with the Market Index';
proc sgplot data=long_correlations;
format correlation 3.2; * Little SAS pg. 110-11: The 3 is the width ('0.77' is width 3), and .2 is how many decimal places to keep for the correlation values;
vbar tkr / response=correlation group=sector groupdisplay=cluster datalabel;
run; quit;
ods graphics off;

********************************************************************;
* Step 5;
********************************************************************;

data return_data;
set temp (keep= return_:); * This gets rid of the date and name columns (AA, BAC, BHI, etc.). VV is not part of the table since it's a response variable (response_VV v. return_stock);
* What happens when I put this keep statement in the set statement?; 
* Look it up in The Little SAS Book; * pg 198-199: helps you avoid reading lots of variables you don't need to read;
run;

proc print data=return_data(obs=10); run;

ods graphics on;
proc princomp data=return_data out=pca_output outstat=eigenvectors plots=scree(unpackpanel); *Do plots=all to see more plots and decide which are important;
run; quit;
ods graphics off;
* Notice that PROC PRINCOMP produces a lot of output;
* How many principal components should we keep?; * 8 because this is where the elbow is in the scree plot;
* Do the principal components have any interpretability?;
* Can we display that interpretability using graphics?;

proc print data=pca_output(obs=10); run;

* proc print data=eigenvectors without specifying _TYPE_='SCORE' prints a huge table
with the mean, std, n, correlation matrix, eigenvalues, and the PCs. We need just the PCs.; 

proc print data=eigenvectors(where=(_TYPE_='SCORE')); run;
* Display the two plots and the Eigenvalue table from the output;

data pca2;
set eigenvectors(where=(_NAME_ in ('Prin1','Prin2')));
drop _TYPE_ ;
run;

proc print data=pca2; run;

proc transpose data=pca2 out=long_pca; run; quit;
proc print data=long_pca; run;

data long_pca;
set long_pca;
format tkr $3.;
tkr = substr(_NAME_,8,3);
drop _NAME_;
run;

proc print data=long_pca; run;

* Plot the first two eigenvectors;
* Note that SAS has been calling them Prin* but giving them type SCORE;
data long_pca;
merge long_pca (in=a) sector (in=b);
by tkr;
if (a=1) and (b=1);
run;
proc print data=long_pca; run; quit;

ods graphics on;
proc sgplot data=long_pca;
scatter x=Prin1 y=Prin2 / datalabel=tkr group=sector;
run; quit;
ods graphics off;
* Do we see anything interesting here? Why would we make such a plot?;

********************************************************************;
* Step 6;
********************************************************************;

* Create a training data set and a testing data set from the PCA output;
* Note that we will use a SAS shortcut to keep both of these 'datasets' in one data set that we will call cv_data (cross-validation data). ;

data cv_data;
merge pca_output temp(keep=response_VV); * pca_output doesn't contain response_VV, but temp does--appending response_VV to pca_output;
* No BY statement needed here. We are going to append a column in its current order;
* generate a uniform(0,1) random variable with seed set to 123;
u = uniform(123);
if (u < 0.70) then train = 1;
else train = 0;
if (train=1) then train_response=response_VV;
else train_response=.;
run;

proc print data=cv_data(obs=10); run;

* View frequency test/train data;
proc freq data=cv_data;
tables train;
title 'Observation Counts for the Cross-Validation Data Partition';
run; quit;

********************************************************************;
* Step 7;
********************************************************************;

* Fit a regression model using all of the individual stocks with train_response as the response variable.;
ods graphics on;
title;
proc reg data=cv_data outest=Model_All_out;
Model_All: model train_response = return_: / selection=rsquare start=20 stop=20 adjrsq aic bic mse cp vif;
output out = Model_All_fit pred=yhat;
run;
ods graphics off;
 
proc print data=Model_All_out; run;

data Model_All_fit;
set Model_All_fit;
residual = response_VV - yhat;
abs_res = abs(residual);
sq_res = residual*residual;
run;

proc print data=Model_All_fit (obs=10);
run;

title "Model_All's MSE and MAE";
proc means data=Model_All_fit nway noprint;
class train;
var sq_res abs_res;
output out = msemae_Model_All_fit
mean(sq_res abs_res) = MSE MAE;
proc print data = msemae_Model_All_fit;
run; quit;

********************************************************************;
* Step 8;
********************************************************************;

* Fit a regression model using the first 8 principal components with train_response as the response variable.;
ods graphics on;
title;
proc reg data=cv_data outest=Model_PC8_out;
Model_PC8: model train_response = Prin1-Prin8 / selection=rsquare start=8 stop=8 adjrsq aic bic mse cp vif;
output out = Model_PC8_fit pred=yhat;
run;
ods graphics off;
 
proc print data=Model_PC8_out; run; 

data Model_PC8_fit;
set Model_PC8_fit;
residual = response_VV - yhat;
abs_res = abs(residual);
sq_res = residual*residual;
run;

proc print data=Model_PC8_fit (obs=10);
run;

title "Model_PC8's MSE and MAE";
proc means data=Model_PC8_fit nway noprint;
class train;
var sq_res abs_res;
output out = msemae_Model_PC8_fit
mean(sq_res abs_res) = MSE MAE;
proc print data = msemae_Model_PC8_fit;
run; quit;

********************************************************************;
* Create Unpacked Models;
********************************************************************;

ods graphics on;
title;
proc reg data=cv_data outest=Model_All_out plots(unpack);
Model_All: model train_response = return_: / selection=rsquare start=20 stop=20 adjrsq aic bic mse cp vif;
output out = Model_All_fit pred=yhat;
run;
ods graphics off;

ods graphics on;
title;
proc reg data=cv_data outest=Model_PC8_out plots(unpack);
Model_PC8: model train_response = Prin1-Prin8 / selection=rsquare start=8 stop=8 adjrsq aic bic mse cp vif;
output out = Model_PC8_fit pred=yhat;
run;
ods graphics off;

********************************************************************;
* End;
********************************************************************;