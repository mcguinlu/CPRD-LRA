use "$data/results/analysis.dta", clear

* Drop patients whose follow-up ends before their index date
drop if diagnosis_dem_end <= index_date

matrix define N = J(7,1,.)

* FOLLOW-UP -----------

gen time = diagnosis_dem_end - index_date

gen time_years = time/365.25

summ time_years, det

* Median
matrix N[1,1] = r(p50)

* Lower IQ

matrix N[2,1] = r(p25)

* Higher IQ
matrix N[3,1] = r(p75)


* AGE ------------------

summ index_age_start, det

* Median
matrix N[4,1] = r(p50)

* Lower IQ

matrix N[5,1] = r(p25)

* Higher IQ
matrix N[6,1] = r(p75)

* TOTAL PATIENT YEARS OF FOLLOW-UP

total time_years

matrix N[7,1] = e(b)

matrix list N

clear
svmat N, names(col)
export delim using "$path/output/files/characteristics.csv", replace
