*******************************************************************************
* ANALYSIS #1 *
* Primary analysis
* Exp: Any lipid regulating agent vs none
* Outcome: any dementia, and sub-group by outcome
*******************************************************************************

* Set-up -----------------------------------------------------------------------
noi di "***** $S_TIME : Starting primary analysis #1 *****"

* Generate empty dataset
clear
set obs 0
gen analysis = ""
save "$data/results/regression_results_p1.dta", replace

* Generate empty dataset
clear
set obs 0
gen analysis = ""
save "$data/results/regression_results_p2.dta", replace

* Compute HR for any_dementia outcome ------------------------------------------
* Using imputed data

use "$data/results/analysis_dem_imputed.dta", clear

mi stset diagnosis_dem_end, failure(diagnosis_any_dementia) id(patid) origin(dob) enter(index_date)

* Split follow-up time between treatment, using date of first drug prescription
mi stsplit treatment, at(0) after(first_drug_date)

* Change the treatment indicator to 0 (No drug) to 1 (drug)
* stcox defaults to -1 (No drug) and 0 (drug)
replace treatment = treatment + 1 if !missing(first_drug_date)

* Get HR, adjusted for full confounders
mi estimate: stcox treatment $analysis_cov

#delimit ;
regsave using "$data/results/regression_results_p1.dta", 
pval ci addlabel(drug, "Any", analysis, "P1 - Imputed", covariates, "full", outcome, "diagnosis_any_dementia", N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
append;
#delimit cr

foreach drug in $hc_treat {
			noi di " - $S_TIME : Starting analysis of `drug' in diagnoses_any_dementia"

			* Get crude HR of treatment adjusted for full confounders
			mi estimate: stcox treatment $analysis_cov if first_drug == "`drug'" | first_drug == "None"
			#delimit ;
			regsave using "$data/results/regression_results_p2.dta", 
			pval ci addlabel(drug, "`drug'", analysis, "P2 - Imputed", covariates, "full", outcome, "diagnosis_any_dementia", N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
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

* Get HR, adjusted for full confounders
mi estimate: stcox treatment $analysis_cov

#delimit ;
regsave using "$data/results/regression_results_p1.dta", 
pval ci addlabel(drug, "Any", analysis, "P1", covariates, "full", outcome, `diagnoses', N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
append;
#delimit cr


foreach drug in $hc_treat {
			noi di " - $S_TIME : Starting analysis of `drug' in `diagnoses'"

			mi estimate: stcox treatment $analysis_cov if first_drug == "`drug'" | first_drug == "None"
			
			#delimit ;
			regsave using "$data/results/regression_results_p2.dta", 
			pval ci addlabel(drug, "`drug'", analysis, "P2", covariates, "full", outcome, `diagnoses', N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
			append;
			#delimit cr			
}
}

*******************************************************************************
* Clean and export results ----------------------------------------------------
*******************************************************************************

foreach file in p1 p2 {

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

replace drug = "Statins" if drug == "hc_sta"
replace drug = "Fibrates" if drug == "hc_fib"
replace drug = "Bile acid sequestrants" if drug == "hc_bas"
replace drug = "Ezetimibe" if drug == "hc_eze"
replace drug = "Omega-3 Fatty Acid Groups" if drug == "hc_om3"

outsheet using "$output/files/regression_results_`file'.csv", comma replace
}