noi di " - $S_TIME : starting pregnancy"

* Generate empty dataset
clear
set obs 0
gen analysis = ""
save "$data/results/regression_results_pregnancy.dta", replace

* Check  global covariates have been loaded	
di "$analysis_cov"

if !strpos("$analysis_cov", "male") { 
     run "$path/code/00_extract_and_clean/1-code_dictionary.do"
}

* Compute HR for any_dementia outcome ------------------------------------------
* Using imputed data

use "$data/results/analysis_dem_imputed.dta", clear

keep if cohort_over_55 == 1

mi stset diagnosis_dem_end, failure(diagnosis_any_dementia) id(patid) origin(dob) enter(index_date)

* Split follow-up time between treatment, using date of first drug prescription
mi stsplit treatment, at(0) after(first_drug_date)

* Change the treatment indicator to 0 (No drug) to 1 (drug)
* stcox defaults to -1 (No drug) and 0 (drug)
replace treatment = treatment + 1 if !missing(first_drug_date)

* Get HR, adjusted for full confounders
mi estimate: stcox treatment $analysis_cov

#delimit ;
regsave using "$data/results/regression_results_pregnancy.dta", 
pval ci addlabel(drug, "Any", analysis, "Pregnancy cohort", covariates, "full", outcome, "diagnosis_any_dementia", N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
append;
#delimit cr

* Compute HR for dementia subtype outcome --------------------------------------
* Using imputed data

foreach diagnoses in adprob vasdem adposs othdem {

noi di "$S_TIME : Starting analysis of `diagnoses' - imputed"

use "$data/results/analysis_dem_imputed.dta", clear

keep if cohort_over_55 == 1

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

* Get HR, adjusted for full confounders
mi estimate: stcox treatment $analysis_cov

#delimit ;
regsave using "$data/results/regression_results_pregnancy.dta", 
pval ci addlabel(drug, "Any", analysis, "Pregnancy cohort", covariates, "full", outcome, `diagnoses', N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
append;
#delimit cr

}

foreach file in pregnancy {

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
