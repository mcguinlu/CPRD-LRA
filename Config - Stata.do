***********************************
* Cohort A.2 - "At risk" analysis *
***********************************

* Edit to your own path!
global path "//ads.bris.ac.uk/folders/Health Sciences/SafeHaven/CPRD Projects UOB/Projects/15_246/LRA-IV"
global dofiles "$path/code"
global output "$path/output"
global data "$path/data"
run "$dofiles/codedict.do"

* Define covariates to be retained in all files --------------------------------

global hc_basic "patid pracid gender region yob frd crd uts tod lcd deathdate fup accept data_* index_* diagnosis* studytime drug5 drug10 drug_fup male pres_year_* exposed dementia_within_6 ssa first_drug first_drug_date first_drug_consid first_drug_staff first_drug_last_date index_baseline_tc index_baseline_ldl" // 
global hc_cov "male index_age_start cad cbs cvd bmi charlson imd2010 cons_rate smoking alcohol pad hyp"

* Generate cohort --------------------------------------------------------------

global dofiles "$path/code/cohort2"

//run "$dofiles/cohort2.do"

* Add covariates (Note: cov.do requires cov_*.do) ------------------------------

//run "$dofiles/cov2.do"

* Gerenate data for Table 1 ----------------------------------------------------

//run "$dofiles/toc.do"

* Generate data on missing covariate information -------------------------------

//run "$dofiles/missingdata.do"

* Run Cox regression analysis --------------------------------------------------

run "$dofiles/analysis2.do"

* Generate indicator for pushover message
clear
set obs 0
gen pushover = ""
save "$path/pushover.dta", replace
