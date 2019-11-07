* Obtain smoking status from additional detail (AD) files ----------------------

** List AD files ---------------------------------------------------------------

local addfiles : dir "$path/data/additional" files "dated_additional_*.dta"

** Create empty AD dataset -----------------------------------------------------

clear
set obs 0
gen patid = .
gen smoking = .
gen smoking_date = .
save "$data/tmp/tmp_adsmoking.dta", replace

qui foreach add in `addfiles' {

	** Extract records ---------------------------------------------------------

	use patid enttype adid data1 eventdate using "$path/data/additional/`add'" ,clear
	keep if enttype==4
	keep if inlist(data1,"1","2","3")
	gen smoking = .
	replace smoking = 1 if data1=="1" // YND 1 = "YES"
	replace smoking = 2 if data1=="3" // YND 3 = "EX"
	replace smoking = 3 if data1=="2" // YND 2 = "NO"
	keep patid smoking eventdate
	
	** Remove records after index date -----------------------------------------
	
	joinby patid using "$data/cohort.dta"
	keep patid smoking eventdate index_date
	keep if eventdate<index_date
	
	** Keep last record prior to index date ------------------------------------
	
	gsort patid -eventdate
	by patid: egen i = seq()
	keep if i==1
	
	** Save to AD dataset ------------------------------------------------------
	
	rename eventdate smoking_date
	keep patid smoking* index_date
	compress	
	save "$data/tmp/tmp.dta", replace
	use "$data/tmp/tmp_adsmoking.dta", clear
	append using "$data/tmp/tmp.dta"
	save "$data/tmp/tmp_adsmoking.dta", replace
}

** Check patids are not repeated in file ----------------------------------------

use "$data/tmp/tmp_adsmoking.dta", clear
gen source = "Additional details"
format %td *date
gsort patid -smoking_date
by patid: egen i = seq()
keep if i==1
keep patid smoking* source
compress	
save "$data/tmp/tmp_adsmoking.dta", replace

* Obtain smoking status from Read code (RC) files ------------------------------

** Retrieve status labels for smoking RCs --------------------------------------

import delimited using "$data/covariates/csv/smoke_status.csv", clear
gen smoking = .
replace smoking = 1 if status=="current smoker"
replace smoking = 2 if status=="ex smoker"
replace smoking = 3 if status=="never smoker"
keep medcode smoking
save "$data/tmp/tmp_status.dta", replace

** Label smoking RCs -----------------------------------------------------------

use patid medcode eventdate using "$data/covariates/eventlists/eventlist_smoke_status.dta", clear
merge m:1 medcode using "$data/tmp/tmp_status.dta"
keep patid smoking eventdate
save "$data/tmp/tmp_status.dta", replace

** Remove records after index date ---------------------------------------------
	
joinby patid using "$data/cohort.dta"
keep patid smoking eventdate index_date
keep if eventdate<index_date

** Keep last record prior to index date ----------------------------------------

gsort patid -eventdate
by patid: egen i = seq()
keep if i==1

** Save to RC dataset ----------------------------------------------------------

rename eventdate smoking_date
keep patid smoking*
gen source = "Read"
compress	
save "$data/tmp/tmp_status.dta", replace

* Combine AD and RC datasets ---------------------------------------------------

use "$data/tmp/tmp_adsmoking.dta", clear
append using "$data/tmp/tmp_status.dta"
format %td *date
gsort patid -smoking_date smoking
by patid: egen i = seq()
keep if i==1
keep patid smoking*
label define status 1 "current" 2 "former" 3 "never"
label values smoking status	
compress	
save "$data/covar/smoking.dta", replace
