* Load patient list ------------------------------------------------------------

use "$data/cohort.dta", clear
keep patid index_date
rename index_date date_cohort

* Add Charlson index variables -------------------------------------------------

local patfiles : dir "$data/covariates/patlists" files "patlist_ci_*.dta"
local score1 = "rheumatological_disease peptic_ulcer_disease myocardial_infarction congestive_heart_disease peripheral_vascular_disease cerebrovascular_disease dementia chronic_pulmonary_disease mild_liver_disease diabetes"
local score2 = "hemiplegia renal_disease diabetes_with_complications cancer"
local score3 = "mod_liver_disease"
local score6 = "metastatic_tumour aids"
	
qui foreach file in `patfiles' {
	
	local index_name = subinstr(subinstr("`file'",".dta","",.),"patlist_ci_","",.)
	
	if strpos("`score1'","`index_name'")>0 {
		local index_score = 1
	} 
	else if strpos("`score2'","`index_name'")>0 {
		local index_score = 2
	} 
	else if strpos("`score3'","`index_name'")>0 {
		local index_score = 3
	} 
	else if strpos("`score6'","`index_name'")>0 {
		local index_score = 6
	} 
	else {
		local index_score = .
	}
	
	joinby patid using "$data/covariates/patlists/`file'", unmatched(master)
	gen `index_name' = cond(!missing(index_date) & index_date<date_cohort,`index_score',0)
	drop index* _merge
}

* Calculate Charlson score -----------------------------------------------------

egen charlson = rowtotal(`score1' `score2' `score3' `score6')

gen charlson6 = cond(charlson<6,charlson,6)

save "$data/covar/charlson.dta", replace
