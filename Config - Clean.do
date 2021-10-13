* Perform basic setup ----------------------------------------------------------

global path "//ads.bris.ac.uk/folders/Health Sciences/SafeHaven/CPRD Projects UOB/Projects/15_246/CPRD-LRA"
global dofiles "$path/code/00_extract_and_clean"
global data "$path/data"
global codelists "$data/codelists"

* Define commonly used code combinations ---------------------------------------

run "$dofiles/1-code_dictionary.do"

* Convert all files to Stata datasets ------------------------------------------

run "$dofiles/raw_codes.do"
run "$dofiles/raw_cprd.do"

* Extract Read code events (>36 hour run time) ---------------------------

*************************************************
* Note: need to reset to the default of all files
*************************************************

	run "$dofiles/events_codes.do"
	local files = "smeeth_azd smeeth_oth"
	// local files : dir "$codelists" files "*.dta"
	foreach file in `files' {
		use "$codelists/`file'", clear
		capture confirm variable prodcode
		if !_rc {
			drop if missing(prodcode)
			duplicates drop
			merge 1:1 prodcode using "$path/data/meddict.dta", keep(match master) keepusing(prodcode drugsubstance)
			drop _merge
			save "$codelists/`file'", replace
		}
		use "$codelists/`file'", clear
		local noextension=subinstr("`file'",".dta","",.)
		noi display "Starting `noextension' codelist at " c(current_time)
		capture confirm variable medcode
		if !_rc {	
 			events_codes med `noextension' 
		}
		capture confirm variable prodcode
		if !_rc {
			events_codes prod `noextension'
		}
	}


* Extract test result events ---------------------------------------------------

run "$dofiles/events_test.do"
events_test "tc_all" "test" "(enttype==163 & test_data1==3)" // TC
events_test "ldl_all" "test" "(enttype==177 & test_data1==3)" // LDL

* Extract ICD events -----------------------------------------------------------

run "$dofiles/events_icd.do"

* Extract covariate events -----------------------------------------------------

run "$dofiles/events_covar.do"
