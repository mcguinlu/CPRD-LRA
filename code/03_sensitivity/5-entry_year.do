noi di " - $S_TIME : starting entry year"

* Get summary table

use "$data/results/analysis.dta", clear

drop if diagnosis_dem_end <= index_date

tabout index_year_group diagnosis_dem using "$output/files/dementia_types.tsv", replace c(freq row)

*Get follow-up by year

matrix define N = J(4,2,.)

* FOLLOW-UP -----------
use "$data/results/analysis.dta", clear

drop if diagnosis_dem_end <= index_date

gen time = diagnosis_dem_end - index_date

gen time_years = time/365.25

foreach num of numlist 1/4 {

summ time_years if index_year_group == `num', det

* Median

matrix N[`num',2] = r(p50)

matrix N[`num',1] = `num'

}

matrix list N

clear
svmat N, names(col)
export delim using "$path/output/files/fu_by_cohort_entry.csv", replace


* Generate empty dataset
clear
set obs 0
gen analysis = ""
save "$data/results/regression_results_entry_year.dta", replace

* Check  global covariates have been loaded	
di "$analysis_cov"

if !strpos("$analysis_cov", "male") { 
     run "$path/code/00_extract_and_clean/1-code_dictionary.do"
}

noi di "Starting analysis of year group `year'"

* Compute HR for any_dementia outcome ------------------------------------------
* Using imputed data

use "$data/results/analysis_dem_imputed.dta", clear

mi stset diagnosis_dem_end, failure(diagnosis_any_dementia) id(patid) origin(dob) enter(index_date)

* Split follow-up time between treatment, using date of first drug prescription
mi stsplit treatment, at(0) after(first_drug_date)

* Change the treatment indicator to 0 (No drug) to 1 (drug)
* stcox defaults to -1 (No drug) and 0 (drug)
replace treatment = treatment + 1 if !missing(first_drug_date)

foreach year in 1 2 3 4 {

noi di "$S_TIME : Starting analysis of year group `year' in any_dementia"

* Get HR, adjusted for full confounders
mi estimate: stcox treatment $analysis_cov if index_year_`year' == 1

#delimit ;
regsave using "$data/results/regression_results_entry_year.dta", 
pval ci addlabel(drug, "Any", analysis, "Year Group `year'", covariates, "full", outcome, "diagnosis_any_dementia", N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
append;
#delimit cr

}

* Compute HR for dementia subtype outcome --------------------------------------
* Using imputed data

foreach diagnoses in adprob vasdem adposs othdem {

noi di "$S_TIME : Starting analysis of `diagnoses' - imputed"

use "$data/results/analysis_dem_imputed.dta", clear

drop if `diagnoses'_dummy != 1 & diagnosis_any_dementia == 1 // Exlcude those who had a different outcome

* Set the data, using:
* 	- patid as the unique indicator (needed for time-varying analyses)
* 	- the index_date as the origin
mi stset diagnosis_dem_end, failure(`diagnoses'_dummy) id(patid) origin(dob) enter(index_date) 

* Split follow-up time between treatment, using date of first drug prescription
mi stsplit treatment, at(0) after(first_drug_date)

* Change the treatment indicator to 0 (No drug) to 1 (drug)
* stcox defaults to -1 (No drug) and 0 (drug)
replace treatment = treatment + 1 if !missing(first_drug_date)

foreach year in 1 2 3 4 {
    
noi di "$S_TIME : Starting analysis of year group `year' in `diagnoses'"

* Get HR, adjusted for full confounders
mi estimate: stcox treatment $analysis_cov if index_year_`year' == 1

#delimit ;
regsave using "$data/results/regression_results_entry_year.dta", 
pval ci addlabel(drug, "Any", analysis, "Year Group `year'", covariates, "full", outcome, `diagnoses', N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
append;
#delimit cr
}
}

foreach file in entry_year {

use "$data/results/regression_results_`file'.dta", clear
keep if var=="treatment"
replace coef = exp(coef) 
replace ci_lower = exp(ci_lower) 
replace ci_upper = exp(ci_upper) 
 
rename coef HR
replace outcome = "Any dementia" if outcome == "diagnosis_any_dementia"
replace outcome = "Vascular dementia" if outcome == "vasdem"
replace outcome = "Other dementia" if outcome == "othdem"
replace outcome = "Probable AD" if outcome == "adprob"
replace outcome = "Possible AD" if outcome == "adposs"

outsheet using "$output/files/regression_results_`file'.csv", comma replace
}

