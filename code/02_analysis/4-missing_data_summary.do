use "$data/results/analysis.dta", clear

* Drop patients whose follow-up ends before their index date
drop if diagnosis_dem_end <= index_date

matrix define N = J(8,2,.)

summarize patid

matrix N[1,1] = r(N)

summarize cohort_full_covar if cohort_full_covar == 1

matrix N[2,1] = r(N)

matrix N[2,2] = r(N)/N[1,1]

summarize patid if missing(imd2010)

matrix N[3,1] = r(N)
matrix N[3,2] = r(N)/N[1,1]

summarize patid if missing(alcohol)

matrix N[4,1] = r(N)
matrix N[4,2] = r(N)/N[1,1]

summarize patid if missing(smoking)

matrix N[5,1] = r(N)
matrix N[5,2] = r(N)/N[1,1]

summarize patid if missing(bmi)

matrix N[6,1] = r(N)
matrix N[6,2] = r(N)/N[1,1]

summarize patid if missing(baseline_tc_all)

matrix N[7,1] = r(N)
matrix N[7,2] = r(N)/N[1,1]

summarize patid if missing(baseline_ldl_all)

matrix N[8,1] = r(N)
matrix N[8,2] = r(N)/N[1,1]

matrix list N

clear
svmat N, names(col)
outsheet using "$path/output/files/missingdata.csv", comma replace
