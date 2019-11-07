use "$data/analysis2.dta", clear

* Complete case analysis
drop if cohort_full_covar==0
drop if missing(index_baseline_tc)

matrix define N = J(5,1,.)

summarize cohort_full_covar if cohort_full_covar ==1

matrix N[1,1] = r(N)

summarize patid if missing(imd2010)

matrix N[2,1] = r(N)

summarize patid if missing(alcohol)

matrix N[3,1] = r(N)

summarize patid if missing(smoking)

matrix N[4,1] = r(N)

summarize patid if missing(bmi)

matrix N[5,1] = r(N)

matrix list N

clear
svmat N, names(col)
outsheet using "$path/output/cohort2missingdata.csv",comma replace
