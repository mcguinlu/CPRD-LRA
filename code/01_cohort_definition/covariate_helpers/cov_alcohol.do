* List clinical and additional detail files to be used -------------------------

local addfiles : dir "$path/data/additional" files "dated_additional_*.dta"

* Create empty BMI dataset -----------------------------------------------------

clear
set obs 0
gen patid = .
gen alcohol = .
gen alcohol_date = .
save "$data/covar/alcohol.dta", replace

qui foreach add in `addfiles' {

	* Extract records ----------------------------------------------------------

	use patid enttype adid data1 eventdate using "$path/data/additional/`add'" ,clear
	keep if enttype==5
	keep if inlist(data1,"1","2","3")
	gen alcohol = .
	replace alcohol = 1 if data1=="1" // YND 1 = "YES"
	replace alcohol = 2 if data1=="3" // YND 3 = "EX"
	replace alcohol = 3 if data1=="2" // YND 2 = "NO"
	keep patid alcohol eventdate
	
	* Remove records after index date ------------------------------------------
	
	joinby patid using "$data/results/cohort-clean.dta"
	keep patid alcohol eventdate index_date
	keep if eventdate<index_date
	
	* Keep last record prior to index date -------------------------------------
	
	gsort patid -eventdate
	by patid: egen i = seq()
	keep if i==1
	
	* Save to BMI dataset ------------------------------------------------------
	
	rename eventdate alcohol_date
	keep patid alcohol* index_date
	compress	
	save "$data/tmp/tmp.dta", replace
	use "$data/covar/alcohol.dta", clear
	append using "$data/tmp/tmp.dta"
	save "$data/covar/alcohol.dta", replace
}

* Check patids are not repeated in BMI file ------------------------------------

use "$data/covar/alcohol.dta", clear
format %td *date
gsort patid -alcohol_date
by patid: egen i = seq()
keep if i==1
keep patid alcohol*
label define status 1 "current" 2 "former" 3 "never"
label values alcohol status	
compress	
save "$data/covar/alcohol.dta", replace
