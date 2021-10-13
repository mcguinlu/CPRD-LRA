*******************************************************************************
*******************************************************************************
*******************************************************************************
* ANALYSIS #4
* Sensitivity analysis
* Exp: Any lipid regulating agent vs none
* Outcome: Dementia and subgroups
* Variation: Group statins by lipophilicity

*******************************************************************************

noi di " - $S_TIME : starting statin properties"

* Create table -----------------------------------------------------------------
use "$data/results/analysis.dta", clear

keep if first_drug == "hc_sta"

tabout pres_year_group first_drug_type using "$output/files/sta_type_table.tsv", replace c(freq row)


* Check  global covariates have been loaded	
di "$analysis_cov"

if !strpos("$analysis_cov", "male") { 
     run "$path/code/00_extract_and_clean/1-code_dictionary.do"
}

* Perform analysis -------------------------------------------------------------
clear
set obs 0
gen analysis = ""
save "$data/results/regression_results_sta_type.dta", replace


use "$data/results/analysis_dem_imputed.dta", clear

keep if first_drug == "hc_sta" | first_drug == "None"

mi stset diagnosis_dem_end, failure(diagnosis_any_dementia) id(patid) origin(dob) enter(index_date)

* Split follow-up time between treatment, using date of first drug prescription
mi stsplit treatment, at(0) after(first_drug_date)

* Change the treatment indicator to 0 (No drug) to 1 (drug)
* stcox defaults to -1 (No drug) and 0 (drug)
replace treatment = treatment + 1 if !missing(first_drug_date)

foreach type in Lipophilic Hydrophilic {

* Get HR, adjusted for full confounders
#delimit ;
mi estimate: stcox treatment
$analysis_cov if first_drug_type == "`type'" | first_drug_type == "";

regsave using "$data/results/regression_results_sta_type.dta", 
pval ci addlabel(drug, "Any", analysis, "`type'", covariates, "full", outcome, "diagnosis_any_dementia", N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All") 
append;
#delimit cr

}

* By dementia subtypes ---------------------------------------------------------

foreach diagnoses in vasdem adprob adposs othdem { 

use "$data/results/analysis_dem_imputed.dta", clear

keep if first_drug == "hc_sta" | first_drug == "None"

drop if `diagnoses'_dummy != 1 & diagnosis_any_dementia == 1 // Exlcude those who had a different outcome

mi stset diagnosis_dem_end, failure(`diagnoses'_dummy) id(patid) origin(dob) enter(index_date) 

* Split follow-up time between treatment, using date of first drug prescription
mi stsplit treatment, at(0) after(first_drug_date)

* Change the treatment indicator to 0 (No drug) to 1 (drug)
* stcox defaults to -1 (No drug) and 0 (drug)
replace treatment = treatment + 1 if !missing(first_drug_date)

foreach type in Lipophilic Hydrophilic {

* Get HR, adjusted for full confounders
#delimit ;
mi estimate: stcox treatment
$analysis_cov if first_drug_type == "`type'" | first_drug_type == "";

regsave using "$data/results/regression_results_sta_type.dta", 
pval ci addlabel(drug, "Any", analysis, "`type'", covariates, "full", outcome, `diagnoses', N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All") 
append;
#delimit cr

}
}

foreach file in sta_type {

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

replace drug = "Statins" if drug == "Any"

outsheet using "$output/files/regression_results_`file'.csv", comma replace
}
