# Setup ====================================================================
library(tidyverse) # Easily Install and Load the 'Tidyverse'
library(DiagrammeR) # Graph/Network Visualization
library(htmltools) # Tools for HTML
library(webshot) # Take Screenshots of Web Pages
library(dplyr) # A Grammar of Data Manipulation
library(here) # A Simpler Way to Find Your Files
library(ggplot2) # Create Elegant Data Visualisations Using the Grammar of Graphics
library(forcats) # Tools for Working with Categorical Variables (Factors)
library(gridExtra) # Miscellaneous Functions for "Grid" Graphics
library(RGraphics) # Data and Functions from the Book R Graphics, Second Edition
library(stringr) # Simple, Consistent Wrappers for Common String Operations
library(patchwork) # The Composer of Plots
library(xlsx)
library(data.table)
library(officer)
library(dplyr)
library(flextable)

# Save session info to file for GitHub Repository ==========================
writeLines(capture.output(sessionInfo()), here("output","files","sessionInfo_R.txt"))

