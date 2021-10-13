noi di " - $S_TIME : starting control outcomes"

* Check  global covariates have been loaded	
di "$analysis_cov"

if !strpos("$analysis_cov", "male") { 
     run "$path/code/00_extract_and_clean/1-code_dictionary.do"
}

* Run analyses for control outcomes

foreach outcome in backpain ihd dm_type2 {

* Create dataset

clear
set obs 0
gen analysis = ""
save "$data/results/regression_results_`outcome'.dta", replace

* Load data
use "$data/results/analysis_dem_imputed.dta", clear

mi stset diagnosis_`outcome'_end, failure(diagnosis_`outcome') id(patid) origin(dob) enter(index_date)

* Split follow-up time between treatment, using date of first drug prescription
mi stsplit treatment, at(0) after(first_drug_date)

* Change the treatment indicator to 0 (No drug) to 1 (drug)
* stcox defaults to -1 (No drug) and 0 (drug)
replace treatment = treatment + 1 if !missing(first_drug_date)

* Get HR, adjusted for full confounders
mi estimate: stcox treatment $analysis_cov

#delimit ;
regsave using "$data/results/regression_results_`outcome'.dta", 
pval ci addlabel(drug, "Any", analysis, "`outcome'", covariates, "full", outcome, "`outcome'", N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
append;
#delimit cr

* Run for each sub-group
foreach drug in $hc_treat {
	noi di " - $S_TIME : Starting analysis of `drug' in `outcome'"

	mi estimate: stcox treatment $analysis_cov if first_drug == "`drug'" | first_drug == "None"
			
	#delimit ;
	regsave using "$data/results/regression_results_`outcome'.dta", 
	pval ci addlabel(drug, "`drug'", analysis, "`outcome'", covariates, "full", outcome, "`outcome'", N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
	append;
	#delimit cr			
}
}

foreach file in ihd backpain dm_type2 {

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
