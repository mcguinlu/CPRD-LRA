cap prog drop comorbid
prog def comorbid
args event

	use patid index_date using "$data/eventlists/eventlist_cm_`event'.dta", clear
	rename index_date cm_`event'_date
	merge m:1 patid using "$data/cohort2.dta", keep(match master) keepusing(patid index_date)
	keep if !missing(index_date) 
	duplicates drop
	sort patid cm_`event'_date
	by patid: egen patseq = seq()
	drop if patseq != 1
	gen `event' = 1 if cm_`event'_date<index_date
	keep patid cm_`event'_date `event'
	rename cm_`event'_date `event'_date
	save "$data/covar/`event'.dta", replace

end
