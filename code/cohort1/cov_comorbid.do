// Unclear what this script is doing?
cap prog drop comorbid
prog def comorbid
args event

	use patid index_date using "$data/eventlists/eventlist_cm_`event'.dta", clear
	rename index_date cm_`event'_date
	merge m:1 patid using "$data/cohort.dta", keep(match master) keepusing(patid index_date)
	keep if !missing(index_date) & cm_`event'_date<index_date
	keep patid
	duplicates drop
	gen `event' = 1
	save "$data/covar/`event'.dta", replace

end
