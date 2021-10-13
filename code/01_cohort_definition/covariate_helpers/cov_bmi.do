* List clinical and additional detail files to be used -------------------------

local addfiles : dir "$path/data/additional" files "dated_additional_*.dta"

* Create empty BMI dataset -----------------------------------------------------

clear
set obs 0
gen patid = .
gen bmi = .
gen bmi_date = .
save "$data/tmp/tmp_bmi_only.dta", replace

qui foreach add in `addfiles' {

	* Extract BMI records ------------------------------------------------------

	use patid enttype adid data3 eventdate using "$path/data/additional/`add'" ,clear
	keep if enttype==13
	destring data3, gen(bmi)
	
	* Remove implausible BMI values --------------------------------------------
	
	drop if bmi<10 // BMI too low (Appendix of https://doi.org/10.1016/S0140-6736(16)30054-X)
	drop if bmi>80 // BMI too high (Appendix of https://doi.org/10.1016/S0140-6736(16)30054-X)
	keep patid eventdate bmi
	
	* Remove BMI records after index date --------------------------------------
	
	joinby patid using "$data/results/cohort-clean.dta"
	keep patid yob bmi eventdate index_date
	keep if eventdate<index_date
	keep if year(eventdate)-yob>24
	
	* Keep last BMI record prior to index date ---------------------------------
	
	gsort patid -eventdate
	by patid: egen i = seq()
	keep if i==1
	
	* Save to BMI dataset ------------------------------------------------------
	
	rename eventdate bmi_date
	keep patid bmi* index_date
	compress	
	save "$data/tmp/tmp.dta", replace
	use "$data/tmp/tmp_bmi_only.dta", clear
	append using "$data/tmp/tmp.dta"
	save "$data/tmp/tmp_bmi_only.dta", replace
}

* Check patids are not repeated in BMI file ------------------------------------

use "$data/tmp/tmp_bmi_only.dta", clear
format %td *date
gsort patid -bmi_date
by patid: egen i = seq()
keep if i==1
keep patid bmi*
compress	
save "$data/tmp/tmp_bmi_only.dta", replace

* Create empty hw2 dataset -----------------------------------------------------

clear
set obs 0
gen patid = .
gen bmi = .
gen height_date = .
gen weight_date = .
gen index_date = .
save "$data/tmp/tmp_bmi_hw.dta", replace

foreach add in `addfiles' {

	* Extract height and weight records ----------------------------------------

	use patid enttype adid data1 eventdate using "$data/additional/`add'" ,clear
	keep if enttype==13 | enttype==14
	destring data1, gen(data)
	drop if missing(data1)
	gen height = data if enttype==14
	gen weight = data if enttype==13
	
	* Remove records after index date ------------------------------------------
	
	joinby patid using "$data/results/cohort-clean.dta"
	keep patid yob data weight height eventdate index_date enttype
	keep if eventdate<index_date
	keep if year(eventdate)-yob>24
	
	* Keep last records prior to index date ------------------------------------
	
	gsort patid -eventdate
	by patid: egen i = seq() if !missing(height)
	keep if i==1 | missing(i)
	
	by patid: egen j = seq() if !missing(weight)
	keep if j==1 | missing(j)
	
	* Reformat data ------------------------------------------------------------
	
	keep patid data eventdate height weight index_date enttype
	keep patid data eventdate index_date enttype
	bysort patid: egen n = seq()
	bysort patid: egen nmax = max(n)
	drop if nmax==1
	gen record = cond(enttype==13,"weight","height")
	keep patid data eventdate index_date record
	reshape wide data eventdate, i(patid) j(record) string
	
	* Calculate BMI ------------------------------------------------------------
	
	gen bmi = round(dataweight/(dataheight^2),0.1)
	drop if missing(bmi)
	
	* Remove implausible BMI values --------------------------------------------
	* Using appendix of https://doi.org/10.1016/S0140-6736(16)30054-X ----------
	
	drop if bmi<10
	drop if bmi>80
	
	* Tidy data ----------------------------------------------------------------
	
	rename eventdateheight height_date
	rename eventdateweight weight_date
	keep patid bmi *_date
	format %td *_date
	
	* Save to BMI dataset ------------------------------------------------------
	
	keep patid bmi *_date
	compress	
	save "$data/tmp/tmp.dta", replace
	use "$data/tmp/tmp_bmi_hw.dta", clear
	append using "$data/tmp/tmp.dta"
	save "$data/tmp/tmp_bmi_hw.dta", replace
}

* Check patids are not repeated in hw2 file ------------------------------------

use "$data/tmp/tmp_bmi_hw.dta", clear
format %td *date
gsort patid -weight_date
by patid: egen i = seq()
keep if i==1
keep patid bmi *_date
compress	
save "$data/tmp/tmp_bmi_hw.dta", replace

* Combine bmi and hw2 files ----------------------------------------------------

use "$data/tmp/tmp_bmi_only.dta", clear
append using "$data/tmp/tmp_bmi_hw.dta"
gsort patid -bmi_date -weight_date
by patid: egen i = seq()
keep if i==1
drop i
compress
save "$data/covar/bmi.dta", replace
