* Create empty results matrix --------------------------------------------------

clear
set obs 0
gen analysis = ""
save "$data/regresults_adj.dta", replace

* Define cases and controls for all outcomes -----------------------------------

forval k  = 1/4 {
	local case`k' = "diagnosis_dem==`k'"
	local cont`k' = "diagnosis_dem==0"
	local out`k' = "`: word `k' of $dem_diag'"
}

local case5 = "diagnosis_dem>0"
local cont5 = "diagnosis_dem==0"
local out5 = "dem_any"

* Conduct analysis -------------------------------------------------------------

local c = 0

local x = 1 // Only repeat for full cohort

forval y = 1/5 {

	foreach i in $ht_paper {

		foreach j in $ht_paper {

			if "`i'" != "`j'" {

				qui {

					* Load master data -----------------------------------------

					use "$data/analysis.dta", clear

					keep if cohort`x' == 1

					local ex_start = _N

					* Define exposed-unexposed ---------------------------------

					keep if inlist(index_drug,"`i'","`j'")

					local ex_drug = _N

					gen exposure = cond(index_drug == "`j'",1,0)
					label define exposure 1 "int" 0 "ref"
					label values exposure exposure
					gen treat_int = "`j'"
					gen treat_ref = "`i'"

					* Define case-control --------------------------------------

					if `y'<5 {
						keep if `case`y'' | `cont`y''
					}
					gen outcome = cond(`case`y'',1,0)
					label define outcome 1 "case" 0 "control"
					label values outcome outcome

					local ex_diag = _N

					* Tidy data ------------------------------------------------

					keep patid gender region data_* outcome exposure index_* pres_year_* $ht_cov

					* Remove staffid = 0 ---------------------------------------

					drop if index_staff==0

					local ex_staff0 = _N

					* Add instrument -------------------------------------------

					sort index_staff index_date index_consid
					forval k = 1/7 {
						by index_staff : gen inst_`k' = exposure[_n-`k']
					}
					by index_staff: egen staffseq = seq()
					drop if staffseq<8
					egen instrument = rowtotal(inst_*)
					drop inst_* staffseq

					save "$data/analysis/data-cohort`x'-`out`y''-`i'-`j'-adj.dta", replace

					local N = _N
					count if exposure == 0 & outcome == 0
					local X0Y0 = r(N)			
					count if exposure == 1 & outcome == 0
					local X1Y0 = r(N)
					count if exposure == 0 & outcome == 1
					local X0Y1 = r(N)
					count if exposure == 1 & outcome == 1
					local X1Y1 = r(N)

					local adj = "bmi charlson imd2010 male index_age_start"

					foreach z in `adj' {

						local c = `c' + 1

						noi di "$S_TIME : Starting IV analysis `c' of 1050"

						* Perform IV analysis --------------------------------------

						ivreg2 outcome (exposure=instrument) pres_year_* `z', robust ffirst cluster(index_staff) partial(pres_year_*) endog(exposure)

						local endog = e(estat)
						local endogp = e(estatp)
						local Fstat = e(cdf) // Cragg-Donald Wald F statistic

						#delimit ;
						regsave using "$data/regresults_adj.dta", 
						pval ci addlabel(analysis, "iv", Fstat, `Fstat', endog, `endog', endogp, `endogp', outcome, `out`y'', treat_int, `j', treat_ref, `i', cohort,`x', 
						ex_start, `ex_start', ex_drug, `ex_drug', ex_diag, `ex_diag', ex_staff0, `ex_staff0',
						X0Y0, `X0Y0', X1Y0, `X1Y0', X0Y1, `X0Y1', X1Y1, `X1Y1', adj, `z'
						) append;
						#delimit cr	

					}
				}
			}
		}
	}
}

use "$data/regresults_adj.dta", clear
keep if var=="exposure" | var=="outcome:exposure"
replace coef = cond(var=="outcome:exposure",exp(coef),coef)
replace ci_lower = cond(var=="outcome:exposure",exp(ci_lower),ci_lower)
replace ci_upper = cond(var=="outcome:exposure",exp(ci_upper),ci_upper)
keep analysis outcome treat_int treat_ref cohort coef stderr pval ci_lower ci_upper Fstat endog endogp N X0Y0 X1Y0 X0Y1 X1Y1 adj
order analysis outcome treat_int treat_ref adj coef stderr pval ci_lower ci_upper Fstat endog endogp N X0Y0 X1Y0 X0Y1 X1Y1 
outsheet using "$output/analysis_reg_adj.csv", comma replace
