local csvfiles "cm_hyp.csv cm_pad.csv cm_ckd.csv cm_dm_type1.csv cm_dm_type2.csv"

foreach file in `csvfiles' {
	import delimited using "$data/covariates/csv/`file'", clear
	local noextension=subinstr("`file'",".csv","",.)
	keep medcode readterm
	drop if missing(medcode)
	label var medcode "Medical Code"
	label var readterm "Read Term"
	save "$data/covariates/stata/`noextension'", replace
}
	
local dtafiles "cm_dm_type1.dta cm_dm_type2.dta"
	
qui foreach file in `dtafiles' {
	local event=subinstr("`file'",".dta","",.)
	noi di "$S_TIME : Extracting: `event'"
	cd "$data/raw"
	local files ""
	foreach j in clinical referral test immunisation {	
		fs "*`j'*"		
		foreach f in `r(files)' {
			noi display "- `f' started at " c(current_time)
			use "$data/raw/`f'",clear
			gen filename = subinstr("`f'",".dta","",.)
			gen index_date = cond(missing(eventdate),sysdate,eventdate)
			gen datetype = cond(missing(eventdate),"sysdate","eventdate")
			joinby medcode using "$data/covariates/stata/`event'.dta"
			tostring textid filename readterm, replace
			compress
			save "$data/eventlists/`f'_eventlist_`event'.dta", replace
			local files : list  f | files
		}
	}

	foreach i in `files'{
		append using "$data/eventlists/`i'_eventlist_`event'.dta"
		rm "$data/eventlists/`i'_eventlist_`event'.dta"
	}

	duplicates drop
	compress
	format %15.0g staffid consid patid
	format %td *date

	save "$data/eventlists/eventlist_`event'.dta", replace
	egen index_count = count(patid), by(patid)
	egen min_date = min(index_date), by(patid)
	format %td min_date
	keep patid index_count min_date
	rename min_date index_date 
	duplicates drop *, force
	save "$data/patlists/patlist_`event'.dta", replace
}
