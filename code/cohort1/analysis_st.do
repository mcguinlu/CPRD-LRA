* Create summary statistics ----------------------------------------------------

matrix define N = J(9,1,.)

* Total number of participants

use "$data/analysis2.dta", clear

* Drop if interval diagnosis occured within 6 months of index 
	display _N
	// display 3575/(3575+38953)*100
	// lose ~ 8.5% of cases by limiting start date to 6 months
	
matrix N[1,1] = _N

* Total follow-up time

summarize fup

matrix N[2,1] = r(sum)

* Median age and interquartile range

summarize index_age_start, detail

matrix N[3,1] = r(p50)
matrix N[4,1] = r(p25)
matrix N[5,1] = r(p75)

* Median follow-up and interquartile range

summarize fup, detail

matrix N[6,1] = r(p50)
matrix N[7,1] = r(p25)
matrix N[8,1] = r(p75)


summarize cohort2 if cohort2 ==1

matrix N[9,1] = r(N)

matrix list N

clear
svmat N, names(col)
outsheet using "$path/output/cohort1description.csv", comma replace


********************************************************************************
* Analysis

foreach diagnoses in diagnosis_any_dementia adposs adprob vasdem othdem {
use "$data/analysis.dta", clear
*Generate diagnosis factors to split the data
gen adprob=.
replace adprob = 1 if diagnosis_dem == 1

gen adposs=.
replace adposs = 1 if diagnosis_dem == 2

gen vasdem=.
replace vasdem = 1 if diagnosis_dem == 3

gen othdem=.
replace othdem = 1 if diagnosis_dem == 4

* Set data
stset index_end, failure(`diagnoses') id(patid) origin(data_start) enter(index_date)
stptime, by(statins_yn) per(1000)
}

clear
set obs 0
gen analysis = ""
save "$data/regresults-cohort1.dta", replace

qui foreach diagnoses in diagnosis_any_dementia adposs adprob vasdem othdem {
noi di "$S_TIME : Starting analysis of `diagnoses'"

use "$data/analysis.dta", clear

*Generate diagnosis factors to split the data
gen adprob=.
replace adprob = 1 if diagnosis_dem == 1

gen adposs=.
replace adposs = 1 if diagnosis_dem == 2

gen vasdem=.
replace vasdem = 1 if diagnosis_dem == 3

gen othdem=.
replace othdem = 1 if diagnosis_dem == 4

* Set data
stset index_end, failure(`diagnoses') id(patid) origin(data_start) enter(index_date)

* Analysis of statins vs all other drugs ---------------------------------------
stcox statins_yn
#delimit ;
regsave using "$data/regresults-cohort1.dta", 
pval ci addlabel(drug, "Any", analysis, "Statins vs Any", covariates, "none", outcome, `diagnoses')
append;
#delimit cr

stcox statins_yn male index_age_start
#delimit ;
regsave using "$data/regresults-cohort1.dta", 
pval ci addlabel(drug, "Any", analysis, "Statins vs Any", covariates, "age/sex", outcome, `diagnoses')
append;
#delimit cr


stcox statins_yn $hc_cov
#delimit ;
regsave using "$data/regresults-cohort1.dta", 
pval ci addlabel(drug, "Any", analysis, "Statins vs Any", covariates, "full", outcome, `diagnoses')
append;
#delimit cr
}


use "$data/regresults-cohort1.dta",clear
keep if var=="statins_yn"
drop if drug == "hc_eze_sta"

replace outcome = "Any dementia" if outcome=="diagnosis_any_dementia"
replace outcome = "Possible AD" if outcome=="adposs"
replace outcome = "Probable AD" if outcome=="adprob"
replace outcome = "Vascular dementia" if outcome=="vasdem"
replace outcome = "Other dementia" if outcome=="othdem"

replace coef = exp(coef)
rename coef HR
replace ci_lower = exp(ci_lower)
replace ci_upper = exp(ci_upper)

drop var
order outcome drug analysis covariates HR stderr pval ci_lower ci_upper N
outsheet using "$output/analysis-cohort1_reg.csv", comma replace


