// WHOLE SAMPLE

use "$data/analysis2.dta", clear

* Complete case analysis
drop if cohort_full_covar==0
drop if missing(index_baseline_tc)

replace first_drug = "No LRA" if missing(first_drug)

keep patid index_date index_end $hc_cov drug5 ssa 

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

egen t1_drug5 = total(drug5)

gen stopped = cond(ssa==1,1,0)

egen t1_stop = total(stopped)

gen added = cond(ssa==2,1,0)

egen t1_add = total(added)

gen switched = cond(ssa==3,1,0)

egen t1_switch = total(switched)

gen prior = 0
replace prior = 1 if index_date>=index_end

egen t1_prior = total(prior)

keep t1*

duplicates drop

gen first_drug = "Whole Sample"

save "$data/cohort2_table1_wholesample.dta", replace

// BY INDEX DRUG

use "$data/analysis2.dta", clear

* Complete case analysis
drop if cohort_full_covar==0
drop if missing(index_baseline_tc)

replace first_drug = "No LRA" if missing(first_drug)

keep patid index_date index_end first_drug $hc_cov drug5 ssa

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

egen t1_drug5 = total(drug5), by(first_drug)

gen stopped = cond(ssa==1,1,0)

egen t1_stop = total(stopped), by(first_drug)

gen added = cond(ssa==2,1,0)

egen t1_add = total(added), by(first_drug)

gen switched = cond(ssa==3,1,0)

egen t1_switch = total(switched), by(first_drug)

gen prior = 0
replace prior = 1 if index_date>=index_end

egen t1_prior = total(prior), by(first_drug)

keep first_drug t1*

duplicates drop

append using "$data/cohort2_table1_wholesample.dta", force

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

gen drug5 = string(round(100*(t1_drug5/N),0.1),"%3.1f") + "% (" + string(t1_drug5,"%3.0f") + ")"

gen stop = string(round(100*(t1_stop/N),0.1),"%3.1f") + "% (" + string(t1_stop,"%3.0f") + ")"
gen add = string(round(100*(t1_add/N),0.1),"%3.1f") + "% (" + string(t1_add,"%3.0f") + ")"
gen switch = string(round(100*(t1_switch/N),0.1),"%3.1f") + "% (" + string(t1_switch,"%3.0f") + ")"

rename t1_prior prior

drop t1_*

order first_drug N year female age cad cbs cvd charlson imd cons_rate alcohol smoking bmi pad hyp stop add switch drug5 prior

outsheet using "$output/cohort2_table1.csv", comma replace
