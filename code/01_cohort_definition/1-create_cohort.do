*******************************************************************************
* Create basic cohort
* This script extracts all relevant events and data from the processed files
* created by the cleaning scripts
*******************************************************************************

* Upload basic patient information ---------------------------------------------
		
use "$data/raw/patient_001.dta", clear

replace yob=yob+1800

* Add practice information -----------------------------------------------------

gen pracid = mod(patid,1000)

merge m:1 pracid using "$path/data/raw/practice_001.dta"
drop _merge // _merge = 3 

keep patid pracid gender region yob frd crd uts tod lcd deathdate accept

* Calculate data start and end dates -------------------------------------------

egen data_start = rowmax(crd uts) // current registration date and up to standard date
egen data_end = rowmin(lcd tod deathdate) // last collection date, transfer out date, death date
format %td data_start data_end // Format as date

save "$data/cohort-raw.dta", replace

* Add outcome data -------------------------------------------------------------
* Add data on first dementia diagnosis	

quietly foreach list in $dem_cond {
	noi di "$S_TIME : Adding eventlist: `list'"
	use "$data/cohort-raw.dta", clear
	merge 1:1 patid using "$data/patlists/patlist_`list'.dta", keep(match master) keepusing(index_date)
	rename index_date `list'_date
	format %td *date
	drop _merge
	save "$data/cohort-raw.dta", replace
}

quietly foreach list in $dem_treat { 
	noi di "$S_TIME : Adding eventlist: `list'"
	use "$data/patlists/patlist_`list'.dta", clear
	merge 1:m patid index_date using "$data/eventlists/eventlist_`list'.dta", keep(match master) keepusing(consid issueseq qty staffid)
	format %td *date
	keep patid index_date consid issueseq qty staffid
	gsort patid index_date consid issueseq -qty staffid
	by patid: egen patseq = seq()
	keep if patseq == 1
	keep patid index_date consid staffid
	rename index_date `list'_date
	rename consid `list'_consid
	rename staffid `list'_staffid
	save "$data/cohortpatlists/cohortpatlist_`list'.dta", replace
	use "$data/cohort-raw.dta", clear
	merge 1:1 patid using "$data/cohortpatlists/cohortpatlist_`list'.dta", keep(match master)
	drop _merge
	save "$data/cohort-raw.dta", replace
}

* Add data on first backpain diagnosis (negative control) ----------------------
* Add data on first ischemic heart disease diagnosis (pos control) -------------
* Add data on first myocardial infarction diagnosis (pos control) --------------
* Add data on coronary artery disease diagnosis (pos control)

quietly foreach list in backpain_cond ihd_cond mi_cond cad_cond dm_type2_cond { 
	noi di "$S_TIME : Adding eventlist: `list'"
	use "$data/cohort-raw.dta", clear
	merge 1:1 patid using "$data/patlists/patlist_`list'.dta", keep(match master) keepusing(index_date)
	rename index_date `list'_date
	format %td *date
	drop _merge
	save "$data/cohort-raw.dta", replace
}

* Add data on smeeth outcomes for comparsion

quietly foreach list in smeeth_azd smeeth_oth { 
	noi di "$S_TIME : Adding eventlist: `list'"
	use "$data/cohort-raw.dta", clear
	merge 1:1 patid using "$data/patlists/patlist_`list'.dta", keep(match master) keepusing(index_date)
	rename index_date `list'_date
	format %td *date
	drop _merge
	save "$data/cohort-raw.dta", replace
}

* Add relevant treatment information and choose between prescriptions prescibed 
* on the same day for the same drug class --------------------------------------

* Add information on other treatments	
quietly foreach list in $hc_treat { 
	noi di "$S_TIME : Adding eventlist: `list'"
	use "$data/eventlists/eventlist_`list'.dta", clear
	keep patid index_date consid issueseq qty staffid prodcode
	gsort patid index_date consid issueseq -qty staffid 
	by patid: egen patseq = seq()
	gsort patid -patseq
	by patid: egen patseq_l = seq()
	keep if patseq==1 | patseq_l == 1
	drop patseq_l
	replace patseq=2 if patseq!=1
	* Reshape to wide
	sort patid patseq
	reshape wide index_date consid staffid qty issueseq prodcode, i(patid) j(patseq)
	keep patid index_date1 index_date2 consid1 staffid1 prodcode1
	rename index_date1 index_date
	save "$data/eventlists/eventlist_`list'_temp.dta"
	use "$data/patlists/patlist_`list'.dta",clear
	merge 1:m patid index_date using "$data/eventlists/eventlist_`list'_temp.dta", keep(match master) keepusing(index_date2 consid1 staffid1 prodcode1)
	rm "$data/eventlists/eventlist_`list'_temp.dta"
	keep patid index_date* consid1 staffid1 prodcode1
	format %td *date
	rename index_date `list'_date
	rename index_date2 `list'_last_date
	rename consid1 `list'_consid
	rename staffid1 `list'_staffid
	rename prodcode1 `list'_prodcode
	save "$data/cohortpatlists/cohortpatlist_`list'.dta", replace
	use "$data/cohort-raw.dta", clear
	merge 1:1 patid using "$data/cohortpatlists/cohortpatlist_`list'.dta", keep(match master)
	drop _merge
	save "$data/cohort-raw.dta", replace
	}

* Add data on first hypercholesterolemia diagnosis
quietly foreach list in $hc_codes {
	noi di "$S_TIME : Adding eventlist: `list'"
	use "$data/patlists/patlist_`list'.dta", clear // clean data with patid index_count and index_date
	merge 1:m patid index_date using "$data/eventlists/eventlist_`list'.dta", keep(match master) // gets data on index test
	format %td *date
	keep patid index_date consid staffid
	gsort patid index_date consid staffid
	by patid: egen patseq = seq()
	keep if patseq==1 
	keep patid index_date consid staffid
	rename index_date `list'_date
	rename consid `list'_consid
	rename staffid `list'_staffid
	save "$data/cohortpatlists/cohortpatlist_`list'.dta", replace
	use "$data/cohort-raw.dta", clear
	merge 1:1 patid using "$data/cohortpatlists/cohortpatlist_`list'.dta", keep(match master)
	drop _merge
	save "$data/cohort-raw.dta", replace
	}

* Add data on first total cholesterol measure and on first LDL cholesterol measure	
quietly foreach list in tc_all ldl_all {
	noi di "$S_TIME : Adding eventlist: `list'"
	use "$data/patlists/patlist_`list'.dta", clear // clean data with patid index_count and index_date
	merge 1:m patid index_date using "$data/eventlists/eventlist_`list'.dta", keep(match master) // gets data on index test
	format %td *date
	gen baseline_`list' = test_data2
	keep patid index_date consid staffid baseline_`list'
	gsort patid index_date consid staffid baseline_`list'
	by patid: egen patseq = seq()
	keep if patseq==1 
	keep patid index_date consid staffid baseline_`list'
	rename index_date `list'_date
	rename consid `list'_consid
	rename staffid `list'_staffid
	rename baseline_`list' `list'_baseline
	save "$data/cohortpatlists/cohortpatlist_`list'.dta", replace
	use "$data/cohort-raw.dta", clear
	merge 1:1 patid using "$data/cohortpatlists/cohortpatlist_`list'.dta", keep(match master)
	drop _merge
	save "$data/cohort-raw.dta", replace
	}	
	
* Save final file in results folder
save "$data/results/cohort-raw.dta", replace // Save to 
erase "$data/cohort-raw.dta" // Delete temp file
