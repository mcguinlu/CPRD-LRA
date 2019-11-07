clear
set obs 0
gen analysis = ""
save "$data/bias_adj.dta", replace

local outcomes  = "dem_any dem_adprob dem_adposs dem_vas dem_oth"

foreach y in `outcomes' {

	foreach i in $ht_paper {

		foreach j in $ht_paper {

			if "`i'"!="`j'" {

				use "$data/analysis/data-cohort2-`y'-`i'-`j'-adj.dta",clear

				* Add smoking and drinking summary variables -----------------------------------

				gen never_smoke = cond(smoking==3,1,0)
				gen never_drink = cond(alcohol==3,1,0)

				* Save estimates for each covariate --------------------------------------------

				local cov_bin "cad cbs cvd never_smoke never_drink"
				local cov_con "cons_rate"	

				foreach x in `cov_bin' `cov_con' {

					local adj = "bmi charlson imd2010 male index_age_start"

					foreach z in `adj' {

						ivreg2 `x' (exposure=instrument) pres_year_* `k', robust ffirst cluster(index_staff) partial(pres_year_*)
						regsave using "$data/bias_adj.dta", pval ci addlabel(analysis, "iv", cov, "`x'", ref, "`i'", interest, "`j'", dem_out, "`y'", adj, "`z'") append
					
					}
				}

			}

		}
	}
}

use "$data/bias_adj.dta",clear
keep if var=="exposure"
keep cov coef adj ci_lower ci_upper analysis ref interest dem_out
outsheet using "$output/bias_scatter_adj.csv", comma replace
