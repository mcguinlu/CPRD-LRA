* COVARIATES

* Define covariates to be retained in all files --------------------------------
global hc_basic "patid pracid gender region dob yob frd crd uts tod lcd deathdate fup accept data_* index_* diagnosis* studytime drug5 drug10 drug_fup male pres_year_* dementia_within_6 sas first_drug* index_year* *_dummy" 

global hc_cov "male index_age_start cad cbs cvd bmi charlson imd2010 cons_rate smoking alcohol pad hyp ckd baseline_tc_all baseline_ldl_all dm_type1 dm_type2"

global analysis_cov "male i.index_year_group cad cbs cvd bmi charlson imd2010 cons_rate i.smoking i.alcohol pad hyp ckd baseline_tc_all baseline_ldl_all dm_type1 dm_type2"

* EVENTS

global hc_treat "hc_bas hc_eze hc_eze_sta hc_fib hc_nag hc_om3 hc_sta"

global hc_treat_min "hc_sta hc_bas hc_fib"

global hc_proto "hc_sta hc_fib hc_bas hc_om3 hc_eze hc_nag"

global hc_base "hc_sta"

global hc_tests "hc_testcond hc_testrisk"

global hc_codes "hc_cond hc_risk"

global dm_treat "dm_big dm_big_oad dm_oad dm_sul"

global dm_proto "dm_big dm_sul dm_oad"

global dm_base "dm_big"

global dem_cond "dem_adposs dem_adprob dem_ns dem_oth dem_vas"

global dem_treat "dem_don dem_gal dem_mem dem_riv"

global dem_diag "dem_adprob dem_adposs dem_vas dem_oth dem_mixadprob dem_mixadposs dem_mixnoad dem_undiag" // order must match definition of var dementia_diagnosis

* DATE & FREQ

foreach z in date freq type staff staffid consid {

	local event_global = "ht_treat hc_tests hc_codes hc_treat dm_treat ht_proto ht_paper hc_proto dm_proto dem_cond dem_treat"
	foreach y in `event_global' {
		local `y'_`z' = ""
		foreach x in $`y' {
			local `y'_`z' "``y'_`z'' `x'_`z'"
		}
		global `y'_`z' = "``y'_`z''"
	}
		
}
