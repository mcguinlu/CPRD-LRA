# Repurposing lipid regulating agents (LRA) for dementia prevention: an analysis of data from the Clinical Practice Research Datalink

This respository contains the code to reproduce the analysis from the following paper:
 
## Abstract

Introduction: 

Methods: 

Findings: 

Interpretation: 

## Using this code

### Preparation
To run this code, clone this repository to a local folder, download the relevant datasets to the `/data/raw` folder and and run the `Config - Clean.do` file.

### Analysis
Set your working directory in the file , `Config - Stata.do`, and run the file in Stata initially, followed by the `Config - R.R` file in R. The `Config - R.R` froms part of a R porject and so you do not need to set your working directory. All other files are called when required from these configuration files. The Stata code covers most of the data cleaning and analysis, while the R code covers most of the graphical and supplementary output. If you would like any more information, please contact luke.mcguinness@bristol.ac.uk. 

## Availability of data

The data used in this project are available on application from the Clinical Practice Research Datalink.

## Supplementary material

This repository contains supplementary material in the folder ‘supplement’. [NEED TO CHECK THIS]

## Funding statement

This work was supported by the [National Institute of Health Research](https://www.nihr.ac.uk/) and the [Integrative Epidemiology Unit](http://www.bristol.ac.uk/integrative-epidemiology/). Luke McGuinness is funded through an NIHR Doctoral Research Fellowship (DRF-2018-11-ST2-048). The Integrative Epidemiology Unit is supported by the Medical Research Council and the University of Bristol [grant number MC_UU_00011/1, MC_UU_00011/3]. 
