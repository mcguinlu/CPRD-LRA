* Perform basic setup ----------------------------------------------------------

global path "//ads.bris.ac.uk/folders/Health Sciences/SafeHaven/CPRD Projects UOB/Projects/15_246/LRA-IV"
global dofiles "$path/code-clean"
global codelists "$path/codelists"
global data "$path/data"
global codelists "$data/codelists"

* Define commonly used code combinations ---------------------------------------

run "$dofiles/codedict.do"

* Convert all files to Stata datasets ------------------------------------------

run "$dofiles/raw_codes.do"
//run "$dofiles/raw_cprd.do"

* Extract Read code events (>36 hour run time) ---------------------------

quietly{
	run "$dofiles/events_codes.do"
	local files = "pad_cond.dta pad_treat.dta"
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
}

* Extract test result events ---------------------------------------------------

//run "$dofiles/events_test.do"
//events_test "ht_testrisk" "dated_additional" "(enttype==1 & data1>=80) | (enttype==1 & data2>=120)"
//events_test "ht_testcond" "dated_additional" "(enttype==1 & data1>=90) | (enttype==1 & data2>=140)"
//events_test "hc_testrisk" "test" "(enttype==163 & test_data1==3 & test_data2>=4) | (enttype==177 & test_data1==3 & test_data2>=2)"
//events_test "hc_testcond" "test" "(enttype==163 & test_data1==3 & test_data2>=5) | (enttype==177 & test_data1==3 & test_data2>=3)"

* Extract ICD events -----------------------------------------------------------

//run "$dofiles/events_icd.do"

* Extract covariate events -----------------------------------------------------

run "$dofiles/events_covar.do"
