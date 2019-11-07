// DATA SPECIFICATION FOR COHORT B.1: 1,022,084 patients - 172 extra excluded

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

save "$data/cohort.dta", replace

* Add relevant diagnostic information ------------------------------------------

quietly foreach list in $dem_cond {
	use "$data/cohort.dta", clear
	merge 1:1 patid using "$path/data/patlists/patlist_`list'.dta", keep(match master) keepusing(index_date)
	rename index_date `list'_date
	format %td *date
	drop _merge
	save "$data/cohort.dta", replace
}

* Add relevant treatment information and choose between prescriptions prescibed 
* on the same day for the same drug class --------------------------------------

quietly foreach list in $hc_treat $dem_treat {
	use "$path/data/patlists/patlist_`list'.dta", clear
	merge 1:m patid index_date using "$path/data/eventlists/eventlist_`list'.dta", keep(match master) keepusing(consid issueseq qty staffid)
	format %td *date
	keep patid index_date consid issueseq qty staffid
	gsort patid index_date consid issueseq -qty staffid
	by patid: egen patseq = seq()
	keep if patseq==1
	keep patid index_date consid staffid
	rename index_date `list'_date
	rename consid `list'_consid
	rename staffid `list'_staffid
	save "$data/cohortpatlists/cohortpatlist_`list'.dta", replace
	use "$data/cohort.dta", clear
	merge 1:1 patid using "$data/cohortpatlists/cohortpatlist_`list'.dta", keep(match master)
	drop _merge
	save "$data/cohort.dta", replace
}
use "$data/cohort.dta", clear

* == Next section is to extract the numbers for the cohort selection figure == *
* Determine index date ---------------------------------------------------------
matrix define N = J(14,1,.)

matrix N[1,1] = _N

egen index_date = rowmin($hc_treat_date)
keep if !missing(index_date)

matrix N[2,1] = _N

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

gen index_age_start = year(index_date) - yob
drop if index_age_start < 40

matrix N[6,1] = _N

* Remove patients with insufficient prior data ---------------------------------

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


* == Determine index information == *
* Determine index drug ---------------------------------------------------------

gen index_drug = "" 
quietly foreach x in $hc_treat { 
	replace index_drug =  index_drug + ";`x'" if `x'_date == index_date // Find treatments prescribed on the index date
}
replace index_drug = substr(index_drug,2,.)

* Drop if multiple lipid regulating agents prescribed --------------------------

drop if strpos(index_drug, ";")

matrix N[12,1] = _N

* Determine index consultation details -----------------------------------------

gen double index_staff = .
gen double index_consid = .
quietly foreach x in $hc_treat { 
	replace index_staff = `x'_staff if "`x'" == index_drug 
	replace index_consid = `x'_consid if "`x'" == index_drug 
}

format %td index_date
format %15.0g index_staff index_consid

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

gen statins_yn = .
replace statins_yn = 1 if index_drug == "hc_sta"
replace statins_yn = 0 if index_drug != "hc_sta"

* Generate new non-string version of drug and label appropriately --------------
* Statins chosen as reference group (=0) as largest group and normative treatment

gen index_drug_factor = .
replace index_drug_factor = 0 if index_drug == "hc_sta"
replace index_drug_factor = 1 if index_drug == "hc_bas"
replace index_drug_factor = 2 if index_drug == "hc_eze_sta"
replace index_drug_factor = 3 if index_drug == "hc_fib"
replace index_drug_factor = 4 if index_drug == "hc_om3"
replace index_drug_factor = 5 if index_drug == "hc_nag"
replace index_drug_factor = 6 if index_drug == "hc_eze"

#delimit ; // This converts the command delimiter to a semi-colon --------------
label define treatments
0 "Statins"
1 "Bile acid sequestrants"
2 "Ezetimibe/Statins"
3 "Fibrates"
4 "Omega 3 Fatty Acids"
5 "Nitrates"
6 "Ezetimibe";
#delimit cr // This converts the command delimiter back to a carraige return

label values index_drug_factor treatments

* Calculate end date in study and age at end -----------------------------------

egen index_end = rowmin(data_end diagnosis_date)
gen index_age_end = year(index_end)-yob
gen studytime = index_end - index_date
gen studytime_w = studytime/7

* Drop if follow-up ends/condition occurs before index_date --------------------

drop if index_date>index_end
matrix N[13,1] = _N

* Drop if index_date prior 1st January 1996 ------------------------------------
* Catchs new users betwee 1996 and 2016

drop if index_date<mdy(1,1,1996)
matrix N[14,1] = _N

* Calculate follow up time -----------------------------------------------------
 
gen fup = (data_end - index_date)/365.25

* Determine if another drug was recieved within 5 years ------------------------

gen drug5 = 0
foreach drug in $hc_treat_date {
	replace drug5 = 1 if !missing(`drug') & year(`drug')-year(index_date)<=5 & `drug'!=index_date & `drug'<=index_end
}

* Determine if another drug was recieved within 10 years -----------------------

gen drug10 = 0
foreach drug in $hc_treat_date {
	replace drug10 = 1 if !missing(`drug') & year(`drug')-year(index_date)<=10 & `drug'!=index_date & `drug'<=index_end
}

* Determine if another drug was recieved during follow-up ----------------------

gen drug_fup = 0
foreach drug in $hc_treat_date {
	replace drug_fup = 1 if !missing(`drug') & `drug'!=index_date & `drug'<=index_end
}

* Add year of prescription -----------------------------------------------------

gen pres_year = year(index_date)

gen pres_cat = 1
replace pres_cat = 2 if pres_year>=1996
replace pres_cat = 3 if pres_year>=2001
replace pres_cat = 4 if pres_year>=2006
replace pres_cat = 5 if pres_year>=2011
tab pres_cat, gen(pres_year_)

* Save -------------------------------------------------------------------------

format %td *_date index_end	
keep $hc_basic
compress
save "$data/cohort.dta", replace

matrix list N
clear
svmat N, names(col)
outsheet using "$path/data/additional/cohort_attrition.csv",comma replace
