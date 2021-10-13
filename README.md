# Association of lipid-regulating drugs with dementia and related conditions: an observational study of data from the Clinical Practice Research Datalink

This repository contains the code to reproduce the analysis from the following paper:

_"Association of lipid-regulating drugs with dementia and related conditions: an observational study of data from the Clinical Practice Research Datalink"_ (full citation TBC)
 
_Authors:_ Luke A McGuinness, Julian PT Higgins, Venexia M Walker, Neil M Davies, Richard M Martin, Elizabeth Coulthard, George Davey-Smith, Patrick G Kehoe and Yoav Ben-Shlomo

## Abstract

__Background:__ There is some evidence that circulating blood lipids play a role in the development of Alzheimer’s disease (AD) and dementia. These modifiable risk factors could be targeted by existing lipid-regulating agents, including statins, for the prevention of dementia. Here, we test the association between lipid-regulating agents and risk of dementia and related conditions in the Clinical Practice Research Datalink (CPRD), a United Kingdom electronic health record database.

__Methods:__ A retrospective cohort study was performed using routinely collected data from the CPRD (January 1995 and March 2016). Multivariable Cox proportional hazard models, allowing for a time-varying treatment indicator, were used to estimate the association between seven lipid-regulating drug classes (vs. no drug) and five dementia outcomes (all-cause, vascular and other dementias, and probable and possible Alzheimer’s disease).

__Results:__ We analyzed 1,684,564 participants with a total follow-up of 10,835,685 patient-years (median: 5.9 years (IQR:2.7-9.7)). We found little evidence that lipid-regulating agents were associated with incidence of Alzheimer’s disease (probable HR:0.98, 95%CI:0.94-1.01; possible HR:0.97, 95%CI:0.93-1.01), but there was evidence of an increased risk of all-cause (HR:1.17, 95%CI:1.14-1.19), vascular (HR:1.81, 95%CI:1.73-1.89) and other dementias (HR:1.19, 95%CI:1.15-1.24). Evidence from a number of control outcomes indicated the presence of substantial residual confounding by indication (ischaemic heart disease HR: 1.62, 95%CI: 1.59-1.64; backpain HR: 1.04, 95%CI: 1.03-1.05; and Type 2 diabetes HR: 1.50, 95%CI: 1.48-1.51).

__Conclusion:__ Lipid-regulating agents were not associated with reduced Alzheimer’s disease risk. There was some evidence of an increased the risk of all-cause, vascular and other dementias, likely due to residual confounding by indication.

__Keywords:__ Dementia; Alzheimer’s disease; Lipids; Statins; Cohort study; Observational study; Electronic health records

## Using this code

### Preparation
To run this code, clone this repository to a local folder, download the relevant datasets to the `/data/raw` folder and and run the `Config - Clean.do` file.

### Analysis
Set your working directory in the file `Config - Stata.do`, and run the file in STATA initially, followed by the `Config - R.R` file in R. If you would like any more information, please contact luke.mcguinness@bristol.ac.uk. 

### Availability of data
This analysis used the CPRD-GOLD primary care dataset March 2016 snapshot (ISAC 15_246R), which is available upon application to the CPRD Independent Scientific Advisory Committee. 

## Funding statement

This work was supported by the [National Institute of Health Research](https://www.nihr.ac.uk/) and the [MRC Integrative Epidemiology Unit](http://www.bristol.ac.uk/integrative-epidemiology/). Luke McGuinness is funded through an NIHR Doctoral Research Fellowship (DRF-2018-11-ST2-048). The Integrative Epidemiology Unit is supported by the Medical Research Council and the University of Bristol [grant numbers: MC_UU_00011/1, MC_UU_00011/4].  The views expressed in articles arising from this repository are those of the authors and do not necessarily represent those of the NHS, the NIHR, MRC, or the Department of Health and Social Care.
