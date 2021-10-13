***********************************
* CPRD Analysis: 
* Author: Luke McGuinness (adapted from code written by Venexia Walker)
***********************************

* Define paths -----------------------------------------------------------------
* Edit to your own path!
global path "//ads.bris.ac.uk/folders/Health Sciences/SafeHaven/CPRD Projects UOB/Projects/15_246/CPRD-LRA"
global output "$path/output"
global data "$path/data"
global results "$path/output/files"

***********************************
* LOAD GLOBAL VARIABLES *
***********************************
global dofiles "$path/code/00_extract_and_clean"

* Load code dictionary ---------------------------------------------------------

run "$dofiles/1-code_dictionary.do"

***********************************
* DEFINE COHORT *
***********************************
global dofiles "$path/code/01_cohort_definition"

* Generate cohort --------------------------------------------------------------

run "$dofiles/1-create_cohort.do"

* Apply inclusion criteria  ----------------------------------------------------

run "$dofiles/2-apply_criteria.do"

* Add covariates  --------------------------------------------------------------

run "$dofiles/3-add_covariates.do"

* Impute missing variables and create final analysis datasets  -----------------
* This takes a long time!

//run "$dofiles/4-imputation.do"

***********************************
* MAIN ANALYSIS *
***********************************
global dofiles "$path/code/02_analysis"

* Run primary Cox regression analysis ------------------------------------------

run "$dofiles/1-primary-analysis.do"

* Genenate data for Table of crude rates ---------------------------------------

run "$dofiles/2-crude_rate_table.do"

* Genenate data for Table of characteristics -----------------------------------

run "$dofiles/3-table_of_characteristics.do"

* Generate data on missing covariate information -------------------------------

run "$dofiles/4-missing_data_summary.do"

* Generate data on summary characteristics for text ----------------------------

run "$dofiles/5-characteristics_text.do"

***********************************
* SENSITIVITY ANALYSIS *
***********************************
global dofiles "$path/code/03_sensitivity"

run "$dofiles/1-control_outcomes.do"

run "$dofiles/2-complete_case.do"

run "$dofiles/3-statin_properties.do"

run "$dofiles/5-entry_year.do"

run "$dofiles/6-pregnancy_cohort.do"

run "$dofiles/7-smeeth_codes.do"


