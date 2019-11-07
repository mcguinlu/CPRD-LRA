* Run dependencies ------------------------------------------------------------

run "$dofiles/cov_comorbid.do"

* Load cohort data -------------------------------------------------------------

use "$data/cohort.dta", clear
save "$data/analysis.dta", replace

* Add charlson index, consultation rate, bmi, smoking and alcohol status -------
* cad = coronary artery diseas
* cvd = cardiovascular disease
* cbs = 

local cms "cad cbs cvd hyp pad"

local adj "charlson cons_rate bmi smoking alcohol"

local vars "$hc_basic"

foreach x in `adj' {
	run "$dofiles/cov_`x'.do"
	use "$data/analysis.dta", clear
	merge 1:1 patid using "$data/covar/`x'.dta", keep(match master) keepusing(patid `x')
	local vars = "`vars'" + " `x'"
	keep `vars'
	compress
	save "$data/analysis.dta", replace
}

* Add comorbidities ------------------------------------------------------------

foreach cm in `cms' {
	comorbid "`cm'" // Function defined in the cv_comorbid script
	use "$data/analysis.dta", clear
	merge 1:1 patid using "$data/covar/`cm'.dta", keep(match master)
	replace `cm' = 0 if missing(`cm')
	drop _merge
	save "$data/analysis.dta", replace
}

* Add index of multiple deprivation --------------------------------------------

use "$data/analysis.dta", clear
merge 1:1 patid pracid using "$path/data/link/link_ab_patient_imd2010.dta", keep(match master) keepusing(patid pracid imd2010_20)
drop _merge
rename imd2010_20 imd2010
merge 1:1 patid pracid using "$path/data/link/link_c_patient_imd2010.dta", keep(match master) keepusing(patid pracid imd2010_20)
drop _merge
rename imd2010_20 imd2010c
replace imd2010 = imd2010c if missing(imd2010)
keep $hc_basic `cms' `adj' imd2010
save "$data/analysis.dta", replace

* Add anxiety ------------------------------------------------------------------

use "$data/eventlists/eventlist_anxiety.dta", clear
keep patid index_date
gen anxiety = 1
duplicates drop
save "$data/tmp/anxiety_date.dta", replace

use "$data/eventlists/eventlist_anxiety.dta", clear
keep patid index_date consid
rename consid index_consid
gen anxiety = 1
duplicates drop
save "$data/tmp/anxiety_date_consid.dta", replace

use "$data/analysis.dta", clear
merge 1:1 patid index_date index_consid using "$data/tmp/anxiety_date_consid.dta", keep(match master)
drop _merge
replace anxiety = 0 if missing(anxiety)
save "$data/analysis.dta", replace

* Add initial dose information
// Adds variable that indicates if dosage of drug received was above 25th 
// percentile (1) or below 25th percentile (0)

quietly foreach list in $hc_treat {
	use "$data/eventlists/eventlist_`list'.dta", clear
	keep patid consid staffid issueseq index_date prodname
	gen mg = regexs(0) if regexm(prodname, "[0-9\.]+mg")
	replace mg = regexr(mg,"mg","")
	gen microgram = regexs(0) if regexm(prodname, "[0-9\.]+microgram")
	replace microgram = regexr(microgram,"microgram","")
	replace mg = microgram if missing(mg)
	drop microgram
	destring mg, replace
	egen min_date = min(index_date), by(patid)
	keep if index_date==min_date
	egen min_iss = min(issueseq), by(patid)
	keep if issueseq==min_iss
	drop issueseq min_iss min_date
	keep patid index_date mg
	collapse (sum) mg, by(patid index_date)
	gen index_drug = "`list'"
	sum mg, detail
	gen `list'_hi = cond(mg>r(p25),1,0)
	keep patid index_date `list'_hi
	save "$data/initialdose/initialdose_`list'.dta", replace
	use "$data/analysis.dta", clear
	merge 1:1 patid index_date using "$data/initialdose/initialdose_`list'.dta", keep(match master)
	drop _merge
	save "$data/analysis.dta", replace
}

* Add indicator variable for those in adjusted analysis ------------------------

gen whole_cohort = 1									// main analysis
egen cohort_full_covar = rownonmiss($hc_cov) 				// complete covariate
replace cohort_full_covar = cond(cohort_full_covar==13,1,0) 	
gen cohort_no_anxie = cond(anxiety==0,1,0)				// remove those with anxiety
egen cohort_hi_dosage = rowmax(*_hi)						// remove those with in the bottom 25% of doses
gen cohort_over_55 = cond(index_age_start>=55,1,0)	// aged 55 and over at index

* Save data --------------------------------------------------------------------

compress
save "$data/analysis.dta", replace
