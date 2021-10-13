*******************************************************************************
* CREATE IMPUTED DATASET(S)
* Using a chained approach, following the adivec of the MI short course
* Similarly, including all possibly important variables
* Trouble with perfect prediction, so using the "augment" option
********************************************************************************

* Explore missing data for dementia outcome ------------------------------------
* Use this to identify the variables that need to be imputed in the next step

use "$data/results/analysis.dta", clear

mi set mlong
mi misstable summarize diagnosis_dem first_drug $hc_cov

mi misstable pattern diagnosis_dem first_drug $hc_cov

* Impute against each outcome --------------------------------------------------
* Outcome should be included in model, see:

foreach x in dem ihd t2d backpain {

use "$data/results/analysis.dta", clear

drop if index_date >= diagnosis_`x'_end

mi set mlong

mi register imputed smoking baseline_tc_all baseline_ldl_all bmi alcohol imd2010

mi impute chained (mlogit) imd2010 smoking alcohol (regress) baseline_tc_all baseline_ldl_all bmi  = ///
diagnosis_`x' male index_age_start  ///
cad cbs cvd charlson cons_rate pad hyp ckd dm_type1 dm_type2, add(20) rseed (42) dots augment

save "$data/results/analysis_`x'_imputed.dta", replace

}

