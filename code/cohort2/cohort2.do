// DATA SPECIFICATION FOR COHORT 2

* Upload basic patient information ---------------------------------------------
		
use "$path/data/raw/patient_001.dta", clear

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

save "$data/cohort2-nofilter.dta", replace

* Add relevant diagnostic information ------------------------------------------

quietly foreach list in $dem_cond {
	noi di "$S_TIME : Adding eventlist: `list'"
	use "$data/cohort2-nofilter.dta", clear
	merge 1:1 patid using "$path/data/patlists/patlist_`list'.dta", keep(match master) keepusing(index_date)
	rename index_date `list'_date
	format %td *date
	drop _merge
	save "$data/cohort2-nofilter.dta", replace
}

* Add relevant treatment information and choose between prescriptions prescibed 
* on the same day for the same drug class --------------------------------------

quietly foreach list in $hc_treat { 
	noi di "$S_TIME : Adding eventlist: `list'"
	use "$path/data/eventlists/eventlist_`list'.dta", clear
	keep patid index_date consid issueseq qty staffid
	gsort patid index_date consid issueseq -qty staffid
	by patid: egen patseq = seq()
	gsort patid -patseq
	by patid: egen patseq_l = seq()
	keep if patseq==1 | patseq_l == 1
	drop patseq_l
	replace patseq=2 if patseq!=1
	* Reshape to wide
	sort patid patseq
	reshape wide index_date consid staffid qty issueseq, i(patid) j(patseq)
	keep patid index_date1 index_date2 consid1 staffid1
	rename index_date1 index_date
	save "$path/data/eventlists/eventlist_`list'_temp.dta"
	use "$path/data/patlists/patlist_`list'.dta",clear
	merge 1:m patid index_date using "$path/data/eventlists/eventlist_`list'_temp.dta", keep(match master) keepusing(index_date2 consid staffid)
	rm "$path/data/eventlists/eventlist_`list'_temp.dta"
	keep patid index_date* consid staffid
	format %td *date
	rename index_date `list'_date
	rename index_date2 `list'_last_date
	rename consid1 `list'_consid
	rename staffid1 `list'_staffid
	save "$data/cohortpatlists/cohortpatlist_`list'.dta", replace
	use "$data/cohort2-nofilter.dta", clear
	merge 1:1 patid using "$data/cohortpatlists/cohortpatlist_`list'.dta", keep(match master)
	drop _merge
	save "$data/cohort2-nofilter.dta", replace
	}

quietly foreach list in $dem_treat { 
	noi di "$S_TIME : Adding eventlist: `list'"
	use "$path/data/patlists/patlist_`list'.dta", clear
	merge 1:m patid index_date using "$path/data/eventlists/eventlist_`list'.dta", keep(match master) keepusing(consid issueseq qty staffid)
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
	use "$data/cohort2-nofilter.dta", clear
	merge 1:1 patid using "$data/cohortpatlists/cohortpatlist_`list'.dta", keep(match master)
	drop _merge
	save "$data/cohort2-nofilter.dta", replace
}

quietly foreach list in  $hc_codes {
	noi di "$S_TIME : Adding eventlist: `list'"
	use "$path/data/patlists/patlist_`list'.dta", clear // clean data with patid index_count and index_date
	merge 1:m patid index_date using "$path/data/eventlists/eventlist_`list'.dta", keep(match master) // gets data on index test
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
	use "$data/cohort2-nofilter.dta", clear
	merge 1:1 patid using "$data/cohortpatlists/cohortpatlist_`list'.dta", keep(match master)
	drop _merge
	save "$data/cohort2-nofilter.dta", replace
	}

quietly foreach list in hc_testrisk {
	noi di "$S_TIME : Adding eventlist: `list'"
	use "$path/data/patlists/patlist_`list'.dta", clear // clean data with patid index_count and index_date
	merge 1:m patid index_date using "$path/data/eventlists/eventlist_`list'.dta", keep(match master) // gets data on index test
	format %td *date
	gen baseline_tc = test_data2 if enttype==163 & test_data1==3 // TC
	gen baseline_ldl = test_data2 if enttype==177 & test_data1==3 // LDL-c
	keep patid index_date consid staffid baseline_tc baseline_ldl
	gsort patid index_date consid staffid baseline_tc baseline_ldl
	by patid: egen patseq = seq()
	keep if patseq==1 
	keep patid index_date consid staffid baseline_tc baseline_ldl
	rename index_date `list'_date
	rename consid `list'_consid
	rename staffid `list'_staffid
	rename baseline_tc `list'_baseline_tc
	rename baseline_ldl `list'_baseline_ldl
	save "$data/cohortpatlists/cohortpatlist_`list'.dta", replace
	use "$data/cohort2-nofilter.dta", clear
	merge 1:1 patid using "$data/cohortpatlists/cohortpatlist_`list'.dta", keep(match master)
	drop _merge
	save "$data/cohort2-nofilter.dta", replace
	}	
	
	
use "$data/cohort2-nofilter.dta", clear


*************************************
* == Generate required variables == *
*************************************

matrix define N = J(14,1,.)

matrix N[1,1] = _N

* Determine index date ---------------------------------------------------------
	egen index_date = rowmin($hc_treat_date $hc_codes_date hc_testrisk_date)
	egen first_drug_date = rowmin($hc_treat_date)

	keep if !missing(index_date)
	matrix N[2,1] = _N

* Generate age at start --------------------------------------------------------

	gen index_age_start = year(index_date) - yob

* Determine index event --------------------------------------------------------
// This process gives a single index_event per patient
// Need single event in order to be able to extract relavant staffid, which may be used to adjust for clustering
// Order of preference for index_event : Test results < treatment code < diagnosis code

	gen index_event = ""

	// Create temp consulation variables if date = index_date
	quietly foreach x in $hc_codes $hc_treat hc_testrisk { 
		gen `x'_consid_temp =.
		replace `x'_consid_temp = `x'_consid if `x'_date == index_date
	}

	// Determine id of first consultation
	egen first_consultation = rowmin(hc_cond_consid_temp hc_risk_consid_temp hc_bas_consid_temp hc_eze_consid_temp hc_eze_sta_consid_temp hc_fib_consid_temp hc_nag_consid_temp hc_om3_consid_temp hc_sta_consid_temp hc_testrisk_consid_temp) 

	// Remove temporary variables
	quietly foreach x in $hc_codes $hc_treat hc_testrisk { 
		drop `x'_consid_temp 	
	}

	// If treatments prescribed in index consulation, replace index_event with these details
	quietly foreach x in $hc_treat { 
		replace index_event = ";`x'" if (`x'_date == index_date) & (`x'_consid == first_consultation)
	}

	// If diagnosis made in the index consulation, replace index_event with these details
	quietly foreach x in $hc_codes { 
		replace index_event = ";`x'" if `x'_date == index_date & `x'_consid == first_consultation
	}
	
	// if testrisk and testcond are different, fill in relevant index event details
	//quietly foreach x in hc_testrisk { 
	//	replace index_event = ";`x'" if missing(index_event) & (`x'_date == index_date) & (`x'_consid == first_consultation) & ((hc_testrisk_staffid != hc_testcond_staffid) | (hc_testrisk_consid != hc_testcond_consid))
	//}
	
	replace index_event = ";hc_testrisk" if (hc_testrisk_date == index_date) & (hc_testrisk_consid == first_consultation)

	// Clean index_event
	replace index_event = substr(index_event,2,.)

* Determine index consultation details -----------------------------------------
	gen double index_staff = .
	gen double index_consid = .
	quietly foreach x in $hc_treat $hc_codes hc_testrisk { 
		replace index_staff = `x'_staff if "`x'" == index_event 
		replace index_consid = `x'_consid if "`x'" == index_event
	}
	
	gen index_baseline_tc = hc_testrisk_baseline_tc if "hc_testrisk" == index_event 
	gen index_baseline_ldl =hc_testrisk_baseline_ldl if "hc_testrisk" == index_event 
	

	format %td index_date
	format %15.0g index_staff index_consid 
	
* Generate first drug prescribed -----------------------------------------------

	gen first_drug = "" 
	quietly foreach x in $hc_treat { 
		replace first_drug =  first_drug + ";`x'" if !missing(first_drug_date) & `x'_date == first_drug_date // Find treatments prescribed on the index date
	}
	replace first_drug = substr(first_drug,2,.)

* Determine first drug consultation details -----------------------------------------
	
	gen double first_drug_staff = .
	gen double first_drug_consid = .
	quietly foreach x in $hc_treat { 
		replace first_drug_staff = `x'_staff if "`x'" == first_drug & !strpos(first_drug, ";")
		replace first_drug_consid = `x'_consid if "`x'" == first_drug & !strpos(first_drug, ";")
	}
	format %td first_drug_date
	format %15.0g first_drug_staff first_drug_consid

* Generate last prescription date for first_drug 
	gen first_drug_last_date=.
	quietly foreach x in $hc_treat { 
	replace first_drug_last_date = `x'_last_date if "`x'" == first_drug & !strpos(first_drug, ";")
	replace first_drug_last_date = `x'_date if "`x'" == first_drug & !strpos(first_drug, ";") & missing(first_drug_last_date)
	}
format %td first_drug_last_date

* Collate dementia information -------------------------------------------------

	egen dem_cond_date = rowmin($dem_cond_date $dem_treat_date)
	egen dem_treat_date = rowmin($dem_treat_date)
	egen dem_ad_date = rowmin(dem_adprob_date dem_adposs_date)

	gen diagnosis_dem = .
	replace diagnosis_dem = 0 if missing(dem_vas_date) & missing(dem_ad_date) & missing(dem_oth_date)
	replace diagnosis_dem = 1 if !missing(dem_adprob_date) & missing(dem_vas_date) & missing(dem_oth_date)
	replace diagnosis_dem = 2 if !missing(dem_adposs_date) & missing(dem_adprob_date) & missing(dem_vas_date) & missing(dem_oth_date)
	replace diagnosis_dem = 3 if missing(dem_ad_date) & !missing(dem_vas_date) & missing(dem_oth_date)
	replace diagnosis_dem = 4 if missing(dem_ad_date) & missing(dem_vas_date) & !missing(dem_oth_date)
	replace diagnosis_dem = 4 if !missing(dem_adprob_date) & (!missing(dem_vas_date) | !missing(dem_oth_date))
	replace diagnosis_dem = 4 if !missing(dem_adposs_date) & missing(dem_adprob_date) & (!missing(dem_vas_date) | !missing(dem_oth_date))
	replace diagnosis_dem = 4 if missing(dem_ad_date) & !missing(dem_vas_date) & !missing(dem_oth_date)
	replace diagnosis_dem = 4 if missing(dem_vas_date) & missing(dem_ad_date) & missing(dem_oth_date) & (!missing(dem_ns_date) | !missing(dem_treat_date))

	#delimit ; // This converts the command delimiter to a semi-colon
	label define diagnosis
	0 "No dementia"
	1 "Probable AD"
	2 "Possible AD"
	3 "Vascular dementia"
	4 "Other dementias";
	#delimit cr // This converts the command delimiter back to a carraige return

	label values diagnosis_dem diagnosis

	rename dem_cond_date diagnosis_date

	gen diagnosis_any_dementia = .
	replace diagnosis_any_dementia = 0 if diagnosis_dem == 0
	replace diagnosis_any_dementia = 1 if diagnosis_dem != 0
	
	
	#delimit ; // This converts the command delimiter to a semi-colon
	label define diagnosis_any_dementia
	0 "No dementia"
	1 "Any dementia";
	#delimit cr // This converts the command delimiter back to a carraige return

	label values diagnosis_any_dementia diagnosis_any_dementia


* Calculate end date in study and age at end -----------------------------------

	egen index_end = rowmin(data_end diagnosis_date)
	gen index_age_end = year(index_end)-yob
	gen studytime = index_end - index_date
	gen studytime_w = studytime/7

* Calculate total follow up time in years --------------------------------------
 
	gen fup = (data_end - index_date)/365.25

* Determine if another drug was recieved within 5 years ------------------------

	gen drug5 = 0
	foreach drug in $hc_treat_date {
		replace drug5 = 1 if !missing(`drug') & year(`drug')-year(first_drug_date)<=5 & `drug'!=first_drug_date & `drug'<=index_end
	}

* Determine if another drug was recieved within 10 years -----------------------

	gen drug10 = 0
	foreach drug in $hc_treat_date {
		replace drug10 = 1 if !missing(`drug') & year(`drug')-year(first_drug_date)<=10 & `drug'!=first_drug_date & `drug'<=index_end
	}

* Determine if another drug was recieved during follow-up ----------------------

	gen drug_fup = 0
	gen drug_fup_item = ""
	foreach drug in $hc_treat_date {
		replace drug_fup = 1 if !missing(`drug') & `drug'!=first_drug_date & `drug'<=index_end
		replace drug_fup_item = drug_fup_item + "; `drug'" if !missing(`drug') & `drug'!=first_drug_date & `drug'<=index_end
	}
	
	* Count number of switches per person
	gen drug_fup_item1 = length(drug_fup_item) - length(subinstr(drug_fup_item, ";", "", .))
	
* Add year of prescription -----------------------------------------------------

	gen pres_year = year(first_drug_date)

	gen pres_cat = 1
	replace pres_cat = 2 if pres_year>=1996
	replace pres_cat = 3 if pres_year>=2001
	replace pres_cat = 4 if pres_year>=2006
	replace pres_cat = 5 if pres_year>=2011
	tab pres_cat, gen(pres_year_)

* Create prevalent dementia (<6 months from index) variable

	gen dementia_within_6 =.
	replace dementia_within_6 = 1 if (diagnosis_date-index_date<=183)
	replace dementia_within_6 = 0 if (diagnosis_date-index_date>183)

* Calculate delay between prescription and first drug --------------------------

	gen exposed = .
	replace exposed = 1 if (first_drug_date - index_date<=183)
	replace exposed = 0 if (first_drug_date - index_date>183)

	//replace first_drug = "No LRA within 6 months" if exposed == 0
	
	
* Calculate time at risk for each person ---------------------------------------

	gen exposed_time =.
	replace exposed_time = data_end - first_drug_date if (first_drug_date - index_date<=183)
	
	gen unexposed_time=.
	replace unexposed_time = first_drug_date - index_date if (first_drug_date - index_date<=183)
	replace unexposed_time = data_end - index_date if (first_drug_date - index_date>183)
	
	
* Stopped/added/switched
gen ssa=.
	*Stopped
	replace ssa = 1 if (first_drug_last_date+183)<index_end
	
foreach drug_date in $hc_treat_date{
	* Added
	replace ssa = 2 if !missing(`drug_date') & `drug_date'!=first_drug_date & `drug_date'<=first_drug_last_date
	* Switched
	replace ssa = 3 if !missing(`drug_date') & `drug_date'!=first_drug_date & `drug_date'>first_drug_last_date
}


**************************************************
* == Apply reamining filters and extract no's == *
**************************************************
* Remove patients without acceptable patient flag ------------------------------

	drop if accept!=1

	matrix N[3,1] = _N

* Remove patients with an index date prior to 01/01/1987 -----------------------

	drop if index_date < mdy(1,1,1987)

	matrix N[4,1] = _N

* Remove patients with an index data after 29/02/2016 --------------------------

	drop if index_date > mdy(2,29,2016)

	matrix N[5,1] = _N

* Remove patients under 40 -----------------------------------------------------

	drop if index_age_start < 40

	matrix N[6,1] = _N

* Remove patients with insufficient prior data ---------------------------------
// This is the section that gives a discrepancy with the statin #'s in the previous cohort
// Due to the index being different

	drop if uts > crd & (ym(year(index_date), month(index_date)) - ym(year(uts), month(uts))) < 12
	drop if uts > crd & (ym(year(index_date), month(index_date)) - ym(year(uts), month(uts))) == 12 & day(index_date) < day(uts)
	drop if crd >= uts & (ym(year(index_date), month(index_date)) - ym(year(crd), month(crd))) < 12
	drop if crd >= uts & (ym(year(index_date), month(index_date)) - ym(year(crd), month(crd))) == 12 & day(index_date) < day(crd)

	matrix N[7,1] = _N

* Remove patients with an index date after death -------------------------------

	drop if index_date > deathdate

	matrix N[8,1] = _N

* Remove patients with an index date after last collection date ----------------

	drop if lcd < index_date

	matrix N[9,1] = _N

* Remove patients with an index date after transfer out date -------------------

	drop if index_date > tod

	matrix N[10,1] = _N

* Remove patients of unknown gender --------------------------------------------

	keep if inlist(gender,1,2)
	gen male = cond(gender==1,1,0)

	matrix N[11,1] = _N

* Drop if multiple lipid regulating agents prescribed at first_drug-------------
// No way to differentiate between these => unless, does us

	drop if strpos(first_drug, ";")

	matrix N[12,1] = _N

* Drop if follow-up ends/condition occurs before index_date --------------------

	drop if index_date>index_end
	matrix N[13,1] = _N

* Drop if index_date prior 1st January 1996 ------------------------------------
// Data not good prior to start of 1995 and needs 12 months of data to be included
	
	drop if index_date<mdy(1,1,1996)
	matrix N[14,1] = _N

* Save -------------------------------------------------------------------------

	format %td *_date index_end	
	keep $hc_basic
	compress
	save "$data/cohort2.dta", replace

	matrix list N
	clear
	svmat N, names(col)
	outsheet using "$path/output/cohort2_attrition.csv",comma replace
