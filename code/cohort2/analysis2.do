* Create summary statistics ----------------------------------------------------

matrix define N = J(9,1,.)

* Total number of participants

use "$data/analysis2.dta", clear

drop if cohort_full_covar==0
drop if missing(index_baseline_tc)

* Drop if interval diagnosis occured within 6 months of index 
display _N
	
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


summarize cohort_full_covar if cohort_full_covar ==1

matrix N[9,1] = r(N)

matrix list N

clear
svmat N, names(col)
outsheet using "$path/output/cohort2description.csv",comma replace


clear
set obs 0
gen analysis = ""
save "$data/regresults-cohort2.dta", replace

*******************************************************************************
* Survival analysis with time varying drug exposure variable -------------------

noi di "***** $S_TIME : Starting time-varying analysis w/o 6-month cutoff *****"

qui foreach diagnoses in diagnosis_any_dementia adposs adprob vasdem othdem {

use "$data/analysis2.dta", clear

drop if cohort_full_covar==0
drop if missing(index_baseline_tc)

gen age_cat=""
replace age_cat = "<65" if index_age_start <65
replace age_cat = "65-74" if (index_age_start>64) & (index_age_start<=74)
replace age_cat = ">75" if (index_age_start>=75)

noi di "$S_TIME : Starting analysis of `diagnoses'"
*Generate diagnosis factors to split the data
gen adprob=.
replace adprob = 1 if diagnosis_dem == 1

gen adposs=.
replace adposs = 1 if diagnosis_dem == 2

gen vasdem=.
replace vasdem = 1 if diagnosis_dem == 3

gen othdem=.
replace othdem = 1 if diagnosis_dem == 4

stset index_end, failure(`diagnoses') id(patid) origin(index_date)

stsplit treatment, at(0) after(first_drug_date)

replace treatment = treatment + 1 if !missing(first_drug_date)

* Get crude HR of exposed
noi di " - $S_TIME : Starting analysis of whole"
stcox treatment 
#delimit ;
regsave using "$data/regresults-cohort2.dta", 
pval ci addlabel(drug, "Any", analysis, "TV - All", covariates, "none", outcome, `diagnoses', N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
append;
#delimit cr

* Get crude HR of exposed adjusted for minimal confounders
stcox treatment male index_age_start 
#delimit ;
regsave using "$data/regresults-cohort2.dta", 
pval ci addlabel(drug, "Any", analysis, "TV - All", covariates, "age/sex", outcome, `diagnoses', N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
append;
#delimit cr

* Get crude HR of exposed adjusted for full confounders
stcox treatment male index_age_start cad cbs cvd bmi charlson imd2010 cons_rate smoking alcohol pad hyp 
#delimit ;
regsave using "$data/regresults-cohort2.dta", 
pval ci addlabel(drug, "Any", analysis, "TV - All", covariates, "full", outcome, `diagnoses', N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
append;
#delimit cr

* Get crude HR of exposed adjusted for full confounders
stcox treatment male index_age_start cad cbs cvd bmi charlson imd2010 cons_rate smoking alcohol pad hyp index_baseline_tc
#delimit ;
regsave using "$data/regresults-cohort2.dta", 
pval ci addlabel(drug, "Any", analysis, "TV - All", covariates, "full+tc", outcome, `diagnoses', N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
append;
#delimit cr

* Analysis by age subgroup 
foreach x in "<65" "65-74" ">75" {
	stcox treatment male index_age_start cad cbs cvd bmi charlson imd2010 cons_rate smoking alcohol pad hyp index_baseline_tc if age_cat=="`x'"
	#delimit ;
	regsave using "$data/regresults-cohort2.dta", 
	pval ci addlabel(drug, "Any", analysis, "TV - All", covariates, "full+tc", outcome, `diagnoses', N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "`x'")
	append;
	#delimit cr
}

* Analysis by drug subgroup

	* Get crude HR for treatment
	foreach drug in $hc_treat{
			noi di " - $S_TIME : Starting analysis of `drug' in `x'"

			stcox treatment if first_drug == "`drug'" | first_drug == ""
			#delimit ;
			regsave using "$data/regresults-cohort2.dta", 
			pval ci addlabel(drug, "`drug'", analysis, "TV - All", covariates, "none", outcome, `diagnoses', N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
			append;
			#delimit cr

			* Get crude HR of treatment adjusted for minimal confounders
			stcox treatment male index_age_start if first_drug == "`drug'" | first_drug == ""
			#delimit ;
			regsave using "$data/regresults-cohort2.dta", 
			pval ci addlabel(drug, "`drug'", analysis, "TV - All", covariates, "age/sex", outcome, `diagnoses', N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
			append;
			#delimit cr

			* Get crude HR of treatment adjusted for full confounders
			stcox treatment male index_age_start cad cbs cvd bmi charlson imd2010 cons_rate smoking alcohol pad hyp if first_drug == "`drug'" | first_drug==""
			#delimit ;
			regsave using "$data/regresults-cohort2.dta", 
			pval ci addlabel(drug, "`drug'", analysis, "TV - All", covariates, "full", outcome, `diagnoses', N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
			append;
			#delimit cr
			
			* Get crude HR of treatment adjusted for full confounders
			stcox treatment male index_age_start cad cbs cvd bmi charlson imd2010 cons_rate smoking alcohol pad hyp index_baseline_tc if first_drug == "`drug'" | first_drug==""
			#delimit ;
			regsave using "$data/regresults-cohort2.dta", 
			pval ci addlabel(drug, "`drug'", analysis, "TV - All", covariates, "full+tc", outcome, `diagnoses', N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "All")
			append;
			#delimit cr	
			
	}
	
	foreach drug in $hc_treat{
		foreach x in "<65" "65-74" ">75"{
			stcox treatment male index_age_start cad cbs cvd bmi charlson imd2010 cons_rate smoking alcohol pad hyp index_baseline_tc if (first_drug == "`drug'" | first_drug=="") & age_cat=="`x'"
			#delimit ;
			regsave using "$data/regresults-cohort2.dta", 
			pval ci addlabel(drug, "`drug'", analysis, "TV - All", covariates, "full+tc", outcome, `diagnoses', N_sub, `e(N_sub)', N_fail, `e(N_fail)', age, "`x'")
			append;
			#delimit cr
		}
	}
}



