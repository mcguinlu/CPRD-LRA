# Setup ========================================================================
library(tidyverse)
source("code/pushover.R")

push_clean() # Remove pushoverr indicator file

# Analysis =====================================================================
RStata::stata("Config - Stata.do",
              stata.path = "\"A:\\Stata\\Stata15_MP\\StataMP-64\"",
              stata.version = 15,
              stata.echo = TRUE)

push_analysis() # Send pushoverr notification to phone on analysis status

# Plot main analysis results ===================================================

source("code/cohort2/plot_cohort2_attrition.R")

source("code/cohort2/plot_main_forest_plots.R")

source("code/cohort2/plot_age_forest_plots.R")

push_plotting() # Send pushoverr notification to phone on plotting status




