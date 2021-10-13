*******************************************************************************
* Add covariates
* This script adds the most recent value of the covariate prior to the index event
* to create "baseline" values of each covariate
********************************************************************************

* Run dependencies -------------------------------------------------------------


* Load cohort data -------------------------------------------------------------

use "$data/results/cohort-clean.dta", clear
save "$data/analysis.dta", replace

* Add charlson index, consultation rate, bmi, smoking and alcohol status -------

local adj "charlson cons_rate bmi smoking alcohol"

local vars "$hc_basic"

foreach x in `adj' {
	noi di "$S_TIME : Adding covarlist: `x'"
	run "$dofiles/covariate_helpers/cov_`x'.do"
	use "$data/analysis.dta", clear
	merge 1:1 patid using "$data/covar/`x'.dta", keep(match master) keepusing(patid `x')
	local vars = "`vars'" + " `x'"
	keep `vars'
	compress
	save "$data/analysis.dta", replace
}

* Add comorbidities ------------------------------------------------------------
* cad = coronary artery diseas
* cbs = coronary bypass surgery
* cvd = cardiovascular disease
* hyp = hypertension
* pad = peripheral arterial disease
* ckd = chronic kidney disease
* dm_type* = diabetes, type 1 & 2

* Load function used to add binary (present/absent) values for comorbidities

run "$dofiles/covariate_helpers/1-cov_comorbid_function.do"

* Add baseline values of comorbidities

local cms "cad cbs cvd hyp pad ckd dm_type1 dm_type2"

local cms "ihd"

foreach cm in `cms' {
	noi di "$S_TIME : Adding comorbidlist: `cm'"
	comorbid "`cm'" // Function defined in the cv_comorbid script
	use "$data/analysis.dta", clear
	merge 1:1 patid using "$data/covar/`cm'.dta", keep(match master)
	replace `cm' = 0 if missing(`cm')
	drop _merge
	save "$data/analysis.dta", replace
}


* Add index of multiple deprivation --------------------------------------------

use "$data/analysis.dta", clear
noi di "$S_TIME : Adding imd2010"
merge 1:1 patid pracid using "$data/link/link_ab_patient_imd2010.dta", keep(match master) keepusing(patid pracid imd2010_20)
drop _merge
rename imd2010_20 imd2010
merge 1:1 patid pracid using "$data/link/link_c_patient_imd2010.dta", keep(match master) keepusing(patid pracid imd2010_20)
drop _merge
rename imd2010_20 imd2010c
replace imd2010 = imd2010c if missing(imd2010)
keep $hc_basic `cms'* `adj' imd2010
save "$data/analysis.dta", replace
*/

* Add baseline cholesterol test results ----------------------------------------
foreach x in tc_all ldl_all { 

noi di "$S_TIME : Adding `x' as covariate"

use patid index_date using "$data/results/cohort-clean.dta", clear
joinby patid using "$data/eventlists/eventlist_`x'.dta"
gen `x' = test_data2
keep patid `x' eventdate index_date

* Get the last test result prior to index event
keep if eventdate <= index_date
gsort patid -eventdate
by patid: egen i = seq()
keep if i==1
save "$data/covar/`x'.dta", replace

* Merge with analysis dataset
use "$data/analysis.dta", clear
merge 1:1 patid using "$data/covar/`x'.dta", keep(match master) keepusing(patid `x')
drop _merge
rename `x' baseline_`x'
save "$data/analysis.dta", replace
}

* Create cohort indicators -----------------------------------------------------

use "$data/analysis.dta", clear

gen whole_cohort = 1								
egen cohort_full_covar = rownonmiss($hc_cov) 		
replace cohort_full_covar = cond(cohort_full_covar==18,1,0) 	
gen cohort_over_55 = cond(index_age_start>=55,1,0)	// aged 55 and over at index
gen cohort_pregnant = cond(index_age_start<55 & male==0,0,1) // Pregnant, with options reversed


* Save data --------------------------------------------------------------------

compress
save "$data/results/analysis.dta", replace
erase "$data/analysis.dta"
