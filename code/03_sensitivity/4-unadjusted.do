clear
set obs 0
gen analysis = ""
save "$data/results/regression_results_unadjusted.dta", replace

* Check  global covariates have been loaded	
di "$analysis_cov"

if !strpos("$analysis_cov", "male") { 
     run "$path/code/00_extract_and_clean/1-code_dictionary.do"
}

foreach diagnoses in diagnosis_dem {

use "$data/results/analysis.dta", clear

drop if index_date >= `diagnoses'_end

* Set the data, using:
* 	- patid as the unique indicator (needed for time-varying analyses)
* 	- the index_date as the origin
stset `diagnoses'_end, failure(`diagnoses') id(patid) origin(dob) enter(index_date) 

* Split follow-up time between treatment, using date of first drug prescription
stsplit treatment, at(0) after(first_drug_date)

* Change the treatment indicator to 0 (No drug) to 1 (drug)
* stcox defaults to -1 (No drug) and 0 (drug)
replace treatment = treatment + 1 if !missing(first_drug_date)

* Get HR, adjusted for full confounders
stcox treatment

#delimit ;
regsave using "$data/results/regression_results_unadjusted.dta", 
pval ci addlabel(drug, "Any", analysis, "Unadjusted", covariates, "Age", outcome, "diagnosis_any_dementia", N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
append;
#delimit cr

* Get HR, adjusted for full confounders
stcox treatment male

#delimit ;
regsave using "$data/results/regression_results_unadjusted.dta", 
pval ci addlabel(drug, "Any", analysis, "Unadjusted", covariates, "Age + Sex", outcome, "diagnosis_any_dementia", N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
append;
#delimit cr

}

* Run model for each individual outcome ----------------------------------------
foreach diagnoses in adprob adposs vasdem othdem {
	
use "$data/results/analysis.dta", clear

drop if index_date >= diagnosis_dem_end

drop if `diagnoses'_dummy != 1 & diagnosis_any_dementia == 1 // Exlcude those who had a different outcome

stset diagnosis_dem_end, failure(`diagnoses'_dummy) id(patid) origin(dob) enter(index_date)

* Split follow-up time between treatment, using date of first drug prescription
stsplit treatment, at(0) after(first_drug_date)

* Change the treatment indicator to 0 (No drug) to 1 (drug)
* stcox defaults to -1 (No drug) and 0 (drug)
replace treatment = treatment + 1 if !missing(first_drug_date)

* Get HR, adjusted for full confounders
stcox treatment

#delimit ;
regsave using "$data/results/regression_results_unadjusted.dta", 
pval ci addlabel(drug, "Any", analysis, "Unadjusted", covariates, "Age", outcome, "`diagnoses'", N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
append;
#delimit cr	

* Get HR, adjusted for full confounders
stcox treatment male

#delimit ;
regsave using "$data/results/regression_results_unadjusted.dta", 
pval ci addlabel(drug, "Any", analysis, "Unadjusted", covariates, "Age + Sex", outcome, "`diagnoses'", N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
append;
#delimit cr	
}	

foreach file in unadjusted {

* Don't need to expoentiate as results are on HR scale for CC analysis
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