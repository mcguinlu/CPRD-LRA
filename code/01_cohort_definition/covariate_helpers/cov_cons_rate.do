* Create master consulatations file --------------------------------------------

clear
set obs 0
gen double patid = .
gen nvals = .
gen source = ""
format %15.0g patid
save "$data/covar/cons_rate.dta", replace

* Load consultation data -------------------------------------------------------

local consfiles : dir "$path/data/raw" files "consultation_*.dta"

qui foreach file in `consfiles' {

	use "$path/data/raw/`file'", clear
	noi di "$S_TIME : Adding `file'"
	* Restrict to events within time frame -------------------------------------

	merge m:1 patid using "$data/results/cohort-clean.dta", keep(master match) keepusing(patid data_start index_date)
	drop if missing(index_date)
	replace eventdate = sysdate if missing(eventdate) // saves removal of 21 patients
	keep if eventdate>=data_start & eventdate<index_date
	keep if inlist(constype, 1,9)

	* Count number of events ---------------------------------------------------

	bysort patid: gen nvals = _n
	keep patid nvals
	by patid: egen maxval = max(nvals)
	keep if nvals == maxval
	keep patid nvals 
	gen source = "`file'"
	save "$data/tmp/tmp.dta", replace

	* Append to master consultations file --------------------------------------

	use "$data/covar/cons_rate.dta", clear
	append using "$data/tmp/tmp.dta", force
	save "$data/covar/cons_rate.dta", replace
	
}

* Collate information from seperate consultation files -------------------------

use "$data/covar/cons_rate.dta", clear
bysort patid: egen consultations = total(nvals)
keep patid consultations
save "$data/covar/cons_rate.dta", replace

* Calculate consultation rate --------------------------------------------------

use "$data/results/cohort-clean.dta", clear
keep patid data_start index_date
merge 1:1 patid using "$data/covar/cons_rate.dta", keep(master match)
drop _merge
replace consultations = 0 if missing(consultations)
gen time =(index_date-data_start)/365.25
gen cons_rate = consultations/time

* Save -------------------------------------------------------------------------
save "$data/covar/cons_rate.dta", replace
