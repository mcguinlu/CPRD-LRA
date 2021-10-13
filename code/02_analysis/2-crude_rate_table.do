use "$data/results/analysis.dta", clear

matrix define N = J(45,3,.)

stset diagnosis_dem_end, failure(diagnosis_any_dementia) id(patid) origin(dob) enter(index_date)

stsplit treatment, at(0) after(first_drug_date)

* Change the treatment indicator to 0 (No drug) to 1 (drug)
* stcox defaults to -1 (No drug) and 0 (drug)
replace treatment = treatment + 1 if !missing(first_drug_date)

local i=1

	stptime, by(first_drug) per(1000) 
	
	matrix N[`i',1] = r(ptime)
	matrix N[`i',2] = r(failures)
	matrix N[`i',3] = r(rate)

		local ++i
	
foreach drug in $hc_treat "None" {
	* Get crude rates, per 1000 days
	stptime if first_drug == "`drug'", by(first_drug) per(1000) 
	
	matrix N[`i',1] = r(ptime)
	matrix N[`i',2] = r(failures)
	matrix N[`i',3] = r(rate)
	
	local ++i
}

matrix list N

foreach diagnoses in adprob vasdem adposs othdem {

use "$data/results/analysis.dta", clear

drop if `diagnoses'_dummy != 1 & diagnosis_any_dementia == 1 // Exlcude those who had a different outcome

* Set the data, using:
* 	- patid as the unique indicator (needed for time-varying analyses)
* 	- the index_date as the origin
stset diagnosis_dem_end, failure(`diagnoses'_dummy) id(patid) origin(dob) enter(index_date) 

* Split follow-up time between treatment, using date of first drug prescription
stsplit treatment, at(0) after(first_drug_date)

* Change the treatment indicator to 0 (No drug) to 1 (drug)
* stcox defaults to -1 (No drug) and 0 (drug)
replace treatment = treatment + 1 if !missing(first_drug_date)

	stptime, by(first_drug) per(1000) 
	
	matrix N[`i',1] = r(ptime)
	matrix N[`i',2] = r(failures)
	matrix N[`i',3] = r(rate)

	local ++i

foreach drug in $hc_treat "None" {
	* Get crude rates, per 1000 days
	stptime if first_drug == "`drug'", by(first_drug) per(1000) 
	
	matrix N[`i',1] = r(ptime)
	matrix N[`i',2] = r(failures)
	matrix N[`i',3] = r(rate)
	
	local ++i
}
}

matrix list N

clear
svmat N, names(col)
export delim using "$path/output/files/crude_rates.csv", replace