*******************************************************************************
* APPLY INCLUSION CRITERIA
* This script also generates some of the variables need to apply the critera
* # after each criteria is applied are captured and stored for an attrition flowchart
*******************************************************************************

use "$data/results/cohort-raw.dta", clear

matrix define N = J(14,1,.)

matrix N[1,1] = _N

* Generate date of birth -------------------------------------------------------
* Using 1 Jan for all patients

gen dob = mdy(1,1,yob)
format %td dob

* Determine index date ---------------------------------------------------------

	* Get rid of extra data on index lipid tests if they don't meet the criteria
	* For total cholesterol, needs to be greater than 4
	* For ldl cholesterol, needs to be greater than 2
	replace tc_all_date = . if tc_all_baseline <= 4
	replace tc_all_consid = . if tc_all_baseline <=  4
	replace tc_all_staffid = . if tc_all_baseline <= 4
	replace tc_all_baseline = . if tc_all_baseline <= 4

	replace ldl_all_date = . if ldl_all_baseline <= 2
	replace ldl_all_consid = . if ldl_all_baseline <=  2
	replace ldl_all_staffid = . if ldl_all_baseline <= 2
	replace ldl_all_baseline = . if ldl_all_baseline <= 2
	
	drop tc_all_baseline ldl_all_baseline
	
	*Get date of index event, which is min of treatment or diagnosis of hyperchol, or date of elevated test result		
	egen index_date = rowmin($hc_treat_date $hc_codes_date tc_all_date ldl_all_date)
	
	* Get date of first drug prescription
	egen first_drug_date = rowmin($hc_treat_date)

	* Remove if missing index event and save to attrition matrix
	keep if !missing(index_date)
	matrix N[2,1] = _N

* Generate age at start --------------------------------------------------------

	gen index_age_start = year(index_date) - yob

* Determine index event --------------------------------------------------------
// This process gives a single index_event per patient
// Need single event in order to be able to extract relavant staffid, which may be used to adjust for clustering
// Order of preference for index_event : LDL test result < TC test result < treatment code < diagnosis code

	gen index_event = ""

	// Create temp consulation variables if date = index_date
	quietly foreach x in  $hc_codes $hc_treat tc_all ldl_all { 
		gen `x'_consid_temp =.
		replace `x'_consid_temp = `x'_consid if `x'_date == index_date
	}

		// Determine id of first consultation
	egen first_consultation = rowmin(hc_cond_consid_temp hc_risk_consid_temp hc_bas_consid_temp hc_eze_consid_temp hc_eze_sta_consid_temp hc_fib_consid_temp hc_nag_consid_temp hc_om3_consid_temp hc_sta_consid_temp tc_all_consid_temp ldl_all_consid_temp) 

	// Remove temporary variables
	quietly foreach x in $hc_codes $hc_treat tc_all ldl_all { 
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
	
	* Note, this gives preference to the tc_all test, as it overwrites the ldl_all values, if both were done in same consultation
	* This is okay, as the only thing this is used for is to extract consulation details
	quietly foreach x in ldl_all tc_all { 
		replace index_event = ";`x'" if (`x'_date == index_date) & (`x'_consid == first_consultation)
	}
	
	// Clean index_event
	replace index_event = substr(index_event,2,.)

* Determine index consultation details -----------------------------------------
	gen double index_staff = .
	gen double index_consid = .
	quietly foreach x in $hc_treat $hc_codes tc_all ldl_all { 
		replace index_staff = `x'_staff if "`x'" == index_event 
		replace index_consid = `x'_consid if "`x'" == index_event
	}
	
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
	gen first_drug_prodcode = .
	quietly foreach x in $hc_treat { 
		replace first_drug_staff = `x'_staff if "`x'" == first_drug & !strpos(first_drug, ";")
		replace first_drug_consid = `x'_consid if "`x'" == first_drug & !strpos(first_drug, ";")
		replace first_drug_prodcode = `x'_prodcode if "`x'" == first_drug & !strpos(first_drug, ";")
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
	
	replace first_drug = "None" if missing(first_drug)

	
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

	rename dem_cond_date diagnosis_dem_date

	* Generate and label composite outcome
	gen diagnosis_any_dementia = .
	replace diagnosis_any_dementia = 0 if diagnosis_dem == 0
	replace diagnosis_any_dementia = 1 if diagnosis_dem != 0
	
	#delimit ; // This converts the command delimiter to a semi-colon
	label define diagnosis_any_dementia
	0 "No dementia"
	1 "Any dementia";
	#delimit cr // This converts the command delimiter back to a carraige return

	label values diagnosis_any_dementia diagnosis_any_dementia
	
	
	* Generate dummy variables for different diagnoses
	gen adprob_dummy=.
	replace adprob_dummy = 1 if diagnosis_dem == 1

	gen adposs_dummy=.
	replace adposs_dummy = 1 if diagnosis_dem == 2

	gen vasdem_dummy=.
	replace vasdem_dummy = 1 if diagnosis_dem == 3

	gen othdem_dummy=.
	replace othdem_dummy = 1 if diagnosis_dem == 4

	* Generate end of data for 
	egen diagnosis_dem_end = rowmin(data_end diagnosis_dem_date)	
	
* Define control outcomes ------------------------------------------------------

	quietly foreach x in backpain mi ihd cad dm_type2 { 
		* Create standard variables
		gen diagnosis_`x' = 0
		replace diagnosis_`x' = 1 if !missing(`x'_cond_date)	
		rename `x'_cond_date diagnosis_`x'_date
		* Generate enddate for each outcome
		egen diagnosis_`x'_end = rowmin(data_end diagnosis_`x'_date)
	}
	
	
* Define smeeth outcomes for comparison ----------------------------------------

	quietly foreach x in smeeth_azd smeeth_oth { 
		* Create standard variables
		gen diagnosis_`x' = 0
		replace diagnosis_`x' = 1 if !missing(`x'_date)	
		rename `x'_date diagnosis_`x'_date
		* Generate enddate for each outcome
		egen diagnosis_`x'_end = rowmin(data_end diagnosis_`x'_date)
	}
	
* Calculate end date in study and age at end -----------------------------------

	gen index_age_end = year(diagnosis_dem_end)-yob
	gen studytime = diagnosis_dem_end - index_date
	gen studytime_w = studytime/7
	
* Calculate total follow up time in years --------------------------------------
 
	gen fup = (data_end - index_date)/365.25

* Determine if another drug was recieved within 5 years ------------------------

	gen drug5 = 0
	foreach drug in $hc_treat_date {
		replace drug5 = 1 if !missing(`drug') & year(`drug')-year(first_drug_date)<=5 & `drug'!=first_drug_date & `drug'<=diagnosis_dem_end
	}

* Determine if another drug was recieved within 10 years -----------------------

	gen drug10 = 0
	foreach drug in $hc_treat_date {
		replace drug10 = 1 if !missing(`drug') & year(`drug')-year(first_drug_date)<=10 & `drug'!=first_drug_date & `drug'<=diagnosis_dem_end
	}

* Determine if another drug was recieved during follow-up ----------------------

	gen drug_fup = 0
	gen drug_fup_item = ""
	foreach drug in $hc_treat_date {
		replace drug_fup = 1 if !missing(`drug') & `drug'!=first_drug_date & `drug'<=diagnosis_dem_end
		replace drug_fup_item = drug_fup_item + "; `drug'" if !missing(`drug') & `drug'!=first_drug_date & `drug'<=diagnosis_dem_end
	}
	
	* Count number of switches per person
	gen drug_fup_item1 = length(drug_fup_item) - length(subinstr(drug_fup_item, ";", "", .))
	
* Add year of prescription -----------------------------------------------------

	gen pres_year = year(first_drug_date)

	gen pres_year_group = .
	replace pres_year_group = 1 if pres_year>=1996
	replace pres_year_group = 2 if pres_year>=2001
	replace pres_year_group = 3 if pres_year>=2006
	replace pres_year_group = 4 if pres_year>=2011
	
	#delimit ; // This converts the command delimiter to a semi-colon
	label define pres_year_label
	1 ">=1996"
	2 ">=2001"
	3 ">=2006"
	4 ">=2011", replace;
	#delimit cr // This converts the command delimiter back to a carraige return

	label values pres_year_group pres_year_label
	
	tab pres_year_group, gen(pres_year_)
	
* Create prevalent dementia (<6 months from index) variable

	gen dementia_within_6 =.
	replace dementia_within_6 = 1 if (diagnosis_dem_date-index_date<=183)
	replace dementia_within_6 = 0 if (diagnosis_dem_date-index_date>183)
	
* Stopped/added/switched
gen sas=.
	*Stopped
	replace sas = 1 if (first_drug_last_date+183)<diagnosis_dem_end
	
foreach drug_date in $hc_treat_date{
	* Added
	replace sas = 2 if !missing(`drug_date') & `drug_date'!=first_drug_date & `drug_date'<=first_drug_last_date
	* Switched
	replace sas = 3 if !missing(`drug_date') & `drug_date'!=first_drug_date & `drug_date'>first_drug_last_date
}

 
* Add hydo/lipophilic info to statins ------------------------------------------
	rename first_drug_prodcode prodcode
	merge m:1 prodcode using "$data/codelists/prod_hc_sta.dta", keep(match master)
	rename type first_drug_type
	drop prodcode 
 
* Generate group for index year ------------------------------------------------
	gen index_year = year(index_date)

	gen index_year_group = .
	replace index_year_group = 1 if index_year >=1996
	replace index_year_group = 2 if index_year >=2001
	replace index_year_group = 3 if index_year >=2006
	replace index_year_group = 4 if index_year >=2011

	#delimit ; // This converts the command delimiter to a semi-colon
	label define index_year_label
	1 ">=1996"
	2 ">=2001"
	3 ">=2006"
	4 ">=2011", replace;
	#delimit cr // This converts the command delimiter back to a carraige return

	label values index_year_group index_year_label
	
	tab index_year_group, gen(index_year_)


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
* Note, this intentionally does not drop participants, as dropping is done at the next stage

	summ patid if index_date < diagnosis_dem_end
	matrix N[13,1] = r(N)
	
* Drop if index_date prior 1st January 1996 ------------------------------------
// Data not good prior to start of 1995 and needs 12 months of data to be included
	
	summ patid if index_date < diagnosis_dem_end & index_date>=mdy(1,1,1996)
	matrix N[14,1] = r(N)
	drop if index_date<mdy(1,1,1996)
	

* Save -------------------------------------------------------------------------

	format %td *_date *_end	
	keep $hc_basic
	compress
	save "$data/results/cohort-clean.dta", replace // Save to results folder

	matrix list N
	clear
	svmat N, names(col)
	outsheet using "$path/output/files/cohort_attrition.csv",comma replace
