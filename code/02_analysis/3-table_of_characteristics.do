// WHOLE SAMPLE

use "$data/results/analysis.dta", clear

* Drop patients whose follow-up ends before their index date
drop if diagnosis_dem_end < index_date

* Drop patients whose follow-up ends before they get a drug
replace first_drug = "No LRA" if !missing(first_drug) & first_drug_date <= diagnosis_dem_end

keep patid index_date diagnosis_dem_end $hc_cov sas fup

egen t1_fup = median(fup)

egen t1_fup_sd = sd(fup)

gen t1_exposed = _N

gen index_year = year(index_date)

egen t1_year = median(index_year)

egen t1_age = median(index_age_start)

egen t1_male = total(male)

egen t1_cad = total(cad)

egen t1_cbs = total(cbs)
 
egen t1_cvd = total(cvd)

egen t1_pad = total(pad)

egen t1_hyp = total(hyp)

egen t1_bmi = mean(bmi)

egen t1_bmi_sd = sd(bmi)

gen charlson_ever = cond(charlson>0,1,0)

egen t1_charlson = total(charlson_ever)

egen t1_imd2010 = median(imd2010)

egen t1_cons_rate = mean(cons_rate)

egen t1_cons_rate_sd = sd(cons_rate)

gen smoking_ever = cond(smoking==3,0,1)

egen t1_smoking = total(smoking_ever)

gen alcohol_ever = cond(alcohol==3,0,1)

egen t1_alcohol = total(alcohol_ever)

egen t1_chol = mean(baseline_tc_all)

egen t1_chol_sd = sd(baseline_tc_all)

egen t1_ldl = mean(baseline_ldl_all)

egen t1_ldl_sd = sd(baseline_ldl_all)

egen t1_dm2 = total(dm_type2)

egen t1_dm1 = total(dm_type1)

egen t1_ckd = total(ckd)

gen stopped = cond(sas==1,1,0)

egen t1_stop = total(stopped)

gen added = cond(sas==2,1,0)

egen t1_add = total(added)

gen switched = cond(sas==3,1,0)

egen t1_switch = total(switched)

gen prior = 0
replace prior = 1 if index_date>=diagnosis_dem_end

egen t1_prior = total(prior)

keep t1*

duplicates drop

gen first_drug = "Whole Sample"

save "$data/results/table1.dta", replace

********************************************************************************
// BY INDEX DRUG
********************************************************************************

use "$data/results/analysis.dta", clear

replace first_drug = "No LRA" if missing(first_drug)

* Drop patients whose follow-up ends before their index date
drop if diagnosis_dem_end <= index_date

* Drop patients whose follow-up ends before they get a drug
replace first_drug = "No LRA" if !missing(first_drug) & first_drug_date <= diagnosis_dem_end

keep patid index_date diagnosis_dem_end first_drug $hc_cov drug5 sas dm_type1 ckd fup

egen t1_fup = median(fup), by(first_drug)

egen t1_fup_sd = sd(fup), by(first_drug)

egen t1_exposed = count(first_drug), by(first_drug)

gen index_year = year(index_date)

egen t1_year = median(index_year), by(first_drug)

egen t1_age = median(index_age_start), by(first_drug)

egen t1_male = total(male), by(first_drug)

egen t1_cad = total(cad), by(first_drug) 

egen t1_cbs = total(cbs), by(first_drug) 
 
egen t1_cvd = total(cvd), by(first_drug) 

egen t1_pad = total(pad), by(first_drug) 

egen t1_hyp = total(hyp), by(first_drug) 

egen t1_bmi = mean(bmi), by(first_drug)

egen t1_bmi_sd = sd(bmi), by(first_drug)

gen charlson_ever = cond(charlson>0,1,0)

egen t1_charlson = total(charlson_ever), by(first_drug)

egen t1_imd2010 = median(imd2010), by(first_drug)

egen t1_cons_rate = mean(cons_rate), by(first_drug)

egen t1_cons_rate_sd = sd(cons_rate), by(first_drug)

gen smoking_ever = cond(smoking==3,0,1)

egen t1_smoking = total(smoking_ever), by(first_drug) 

gen alcohol_ever = cond(alcohol==3,0,1)

egen t1_alcohol = total(alcohol_ever), by(first_drug)

egen t1_chol = mean(baseline_tc_all), by(first_drug)

egen t1_chol_sd = sd(baseline_tc_all), by(first_drug)

egen t1_ldl = mean(baseline_ldl_all), by(first_drug)

egen t1_ldl_sd = sd(baseline_ldl_all), by(first_drug)

egen t1_dm2 = total(dm_type2), by(first_drug)

egen t1_dm1 = total(dm_type1), by(first_drug)

egen t1_ckd = total(ckd), by(first_drug)

gen stopped = cond(sas==1,1,0)

egen t1_stop = total(stopped), by(first_drug)

gen added = cond(sas==2,1,0)

egen t1_add = total(added), by(first_drug)

gen switched = cond(sas==3,1,0)

egen t1_switch = total(switched), by(first_drug)

gen prior = 0
replace prior = 1 if index_date>=diagnosis_dem_end

egen t1_prior = total(prior), by(first_drug)

keep first_drug t1*

duplicates drop

append using "$data/results/table1.dta", force

********************************************************************************
// CLEAN & EXPORT
********************************************************************************

replace first_drug = "Statins" if first_drug=="hc_sta"
replace first_drug = "Bile acid sequestrants" if first_drug=="hc_bas"
replace first_drug = "Nicotinic acid groups" if first_drug=="hc_nag"
replace first_drug = "Ezetimibe & Statins" if first_drug=="hc_eze_sta"
replace first_drug = "Ezetimibe" if first_drug=="hc_eze"
replace first_drug = "Omega-3 Fatty Acid Groups" if first_drug=="hc_om3"
replace first_drug = "Fibrates" if first_drug=="hc_fib"
sort first_drug

rename t1_exposed N

rename t1_year year

gen female = string(round(100*((N-t1_male)/N),0.1),"%3.1f") + "% (" + string(N-t1_male,"%3.0f") + ")"

rename t1_age age

gen cad = string(round(100*(t1_cad/N),0.1),"%3.1f") + "% (" + string(t1_cad,"%3.0f") + ")"

gen cbs = string(round(100*(t1_cbs/N),0.1),"%3.1f") + "% (" + string(t1_cbs,"%3.0f") + ")"

gen cvd = string(round(100*(t1_cvd/N),0.1),"%3.1f") + "% (" + string(t1_cvd,"%3.0f") + ")"

gen pad = string(round(100*(t1_pad/N),0.1),"%3.1f") + "% (" + string(t1_pad,"%3.0f") + ")"

gen hyp = string(round(100*(t1_hyp/N),0.1),"%3.1f") + "% (" + string(t1_hyp,"%3.0f") + ")"

gen charlson = string(round(100*(t1_charlson/N),0.1),"%3.1f") + "% (" + string(t1_charlson,"%3.0f") + ")"

rename t1_imd2010 imd

gen cons_rate = string(round(t1_cons_rate,0.1),"%3.1f") + " (" + string(round(t1_cons_rate_sd,0.1),"%3.1f") + ")"

gen alcohol = string(round(100*(t1_alcohol/N),0.1),"%3.1f") + "% (" + string(t1_alcohol,"%3.0f") + ")"

gen smoking =string(round(100*(t1_smoking/N),0.1),"%3.1f") + "% (" + string(t1_smoking,"%3.0f") + ")"

gen bmi = string(round(t1_bmi,0.1),"%3.1f") + " (" + string(round(t1_bmi_sd,0.1),"%3.1f") + ")"

gen chol = string(round(t1_chol,0.1),"%3.1f") + " (" + string(round(t1_chol_sd,0.1),"%3.1f") + ")"

gen ldl = string(round(t1_ldl,0.1),"%3.1f") + " (" + string(round(t1_ldl_sd,0.1),"%3.1f") + ")"

gen ckd = string(round(100*(t1_ckd/N),0.1),"%3.1f") + "% (" + string(t1_ckd,"%3.0f") + ")"

gen dm1 = string(round(100*(t1_dm1/N),0.1),"%3.1f") + "% (" + string(t1_dm1,"%3.0f") + ")"

gen dm2 = string(round(100*(t1_dm2/N),0.1),"%3.1f") + "% (" + string(t1_dm2,"%3.0f") + ")"

gen stop = string(round(100*(t1_stop/N),0.1),"%3.1f") + "% (" + string(t1_stop,"%3.0f") + ")"
gen add = string(round(100*(t1_add/N),0.1),"%3.1f") + "% (" + string(t1_add,"%3.0f") + ")"
gen switch = string(round(100*(t1_switch/N),0.1),"%3.1f") + "% (" + string(t1_switch,"%3.0f") + ")"

gen fup = string(round(t1_fup,0.1),"%3.1f")

rename t1_prior prior

drop t1_*

order first_drug N year female age cad cbs cvd charlson imd cons_rate alcohol smoking bmi pad hyp chol ckd dm1 stop add switch ldl dm2 fup

outsheet using "$output/files/table1.csv", comma replace
