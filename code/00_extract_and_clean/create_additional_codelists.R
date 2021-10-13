
# IMPORT AND CLEAN CPRD MEDICAL DICTIONARY -------------------------------------

  # Import CPRD code browser file
  meddict <- read.delim("data/external/medical.txt", header = FALSE)

  # Remove first two rows of nonsense and convert to dataframe
  meddict <-meddict[c(3:nrow(meddict)),] 
  meddict <- as.data.frame(meddict)

  # Label columns as required for analysis
  names(meddict)[1] <- "medcode"
  names(meddict)[2] <- "readcode"
  names(meddict)[7] <- "readterm"
  
  
# IMPORT AND CLEAN CPRD PRODUCT DICTIONARY -------------------------------------
  proddict <- read.delim("data/external/product.txt", header = FALSE)
  proddict <-proddict[c(3:nrow(proddict)),] 
  proddict <- as.data.frame(proddict)
  
  # Label as required for analysis
  names(proddict)[1] <- "prodcode"
  names(proddict)[4] <- "productname"
  names(proddict)[5] <- "description2"
  names(proddict)[9] <- "bnfcode"
  
  # Reorder columns
  proddict <- proddict[,c(1,9,4,5,2:3,6:8,10:12)]
  
  
# FRAMINGHAM -------------------------------------------------------------------
  # Get codes for Framingham score (note ignore.case = TRUE)
  framingham_codes <-meddict[grep("Framingham",meddict$readterm,ignore.case = TRUE),]
  
  # Remove ineligble codes
  framingham_codes_excl <- c("adjusted","type A", "5 year", "anger", "JBS 2")
  framingham_codes_clean <- framingham_codes[-grep(paste(framingham_codes_excl, collapse="|"),framingham_codes$readterm), ]

  # Format for analysis  
  framingham_codes_clean <- framingham_codes_clean[,c(1,2,7)]

  # Save
  write.xlsx(framingham_codes_clean, "data/codelists/excel/framingham.xlsx", row.names = FALSE)


# QRISK ------------------------------------------------------------------------
  # Get codes for QRISK score, clean and format for analysis
  qrisk_codes <-meddict[grep("qrisk",meddict$readterm,ignore.case = TRUE),]

  # Remove ineligble codes
  qrisk_codes_excl <- c("heart age","declined", "Unsuitable")
  qrisk_codes_clean <- qrisk_codes[-grep(paste(qrisk_codes_excl, collapse="|"),qrisk_codes$readterm), ]

  # Format for analysis  
  qrisk_codes_clean <- qrisk_codes_clean[,c(1,2,7)]
  
  # Save
  write.xlsx(qrisk_codes_clean, "data/codelists/excel/qrisk.xlsx", row.names = FALSE)
  
  
# Myocardial infarction: Condition -----------------------------------------
  # Load codes from BMJ paper, sourced from the Clinical Codes website
  # Source: https://clinicalcodes.rss.mhs.man.ac.uk/medcodes/article/27/codelist/res27-myocardial-infarction/
  
  med_mi_codes_cc <- read.xlsx("data/external/mi_cond.xlsx", sheetIndex = 1, header = FALSE)
  
  # Keep only needed columns and rename for merge
  med_mi_codes_cc <- med_mi_codes_cc[,c(1,3)]
  names(med_mi_codes_cc)[1] <- "readcode"
  names(med_mi_codes_cc)[2] <- "description"
  
  # Merge with meddict to find relevant medcode
  med_mi_codes_merge <- merge (med_mi_codes_cc, meddict, by = "readcode")
  
  # Clean resulting dataset
  med_mi_codes_clean <- med_mi_codes_merge[,c(3,1,2)]
  names(med_mi_codes_clean)[3] <- "readterm"
  
  # Save
  write.xlsx(med_mi_codes_clean, "data/codelists/excel/mi_cond.xlsx", row.names = FALSE)  
  
  
  
# Peripheral artery disease: Condition -----------------------------------------
  # Load codes from BMJ paper, sourced from the Clinical Codes website
  # Source: https://clinicalcodes.rss.mhs.man.ac.uk/medcodes/article/6/codelist/peripheral-arterial-disease/
  
  med_pad_codes_cc <- read.xlsx("data/external/pad-raw.xlsx", sheetIndex = 1, header = FALSE)
  
  # Limit to "main" codes
  med_pad_codes_cc <- med_pad_codes_cc[which(med_pad_codes_cc$X6 == "Main"),]
  
  # Limit to READ codes
  med_pad_codes_cc <- med_pad_codes_cc[which(med_pad_codes_cc$X2 == "Read"),]
  
  # Keep only needed columns and rename for merge
  med_pad_codes_cc <- med_pad_codes_cc[,c(1,3)]
  names(med_pad_codes_cc)[1] <- "readcode"
  names(med_pad_codes_cc)[2] <- "description"
  
  # Merge with meddict to find relevant medcode
  med_pad_codes_merge <- merge (med_pad_codes_cc, meddict, by = "readcode")
  
  # Clean resulting dataset
  med_pad_codes_clean <- med_pad_codes_merge[,c(3,1,2)]
  names(med_pad_codes_clean)[3] <- "readterm"
  
  # Save
  write.xlsx(med_pad_codes_clean, "data/codelists/excel/pad_cond.xlsx", row.names = FALSE)
  
# Peripheral artery disease: Treatments ----------------------------------------

  # Define treatments for peripheral artery disease based on NICE/BNF guidance
  # Source: https://bnf.nice.org.uk/treatment-summary/peripheral-vascular-disease.html
  prod_pad_codes_list <- c("NAFTIDROFURYL",
                           "CILOSTAZOL",
                           "ILOPROST",
                           "PENTOXIFYLLINE",
                           "INOSITOL NICOTINATE")
  
  # Search for treatments containing these in either description
  prod_pad_codes_raw <- proddict[grep(paste(prod_pad_codes_list, collapse="|"), 
                                      paste(proddict$productname,proddict$description2), 
                                      ignore.case = TRUE), ]


  # Format for analysis  
  prod_pad_codes_clean <-  prod_pad_codes_raw[,c(1,3)]
  
  #Save
  write.xlsx(prod_pad_codes_clean, "data/codelists/excel/pad_treat.xlsx", row.names = FALSE)    

  
# Depression: Condition --------------------------------------------------------
  
  med_dep_codes_cc <- read.xlsx("data/external/depression.xlsx", sheetIndex = 1, header = FALSE)
  
  # Limit to READ codes
  med_dep_codes_cc <- med_dep_codes_cc[which(med_dep_codes_cc$X2 == "Read"),]
  
  # Keep only needed columns and rename for merge
  med_dep_codes_cc <- med_dep_codes_cc[,c(1,3)]
  names(med_dep_codes_cc)[1] <- "readcode"
  names(med_dep_codes_cc)[2] <- "description"
  
  # Merge with meddict to find relevant medcode
  med_dep_codes_merge <- merge (med_dep_codes_cc, meddict, by = "readcode")
  
  # Clean resulting dataset
  med_dep_codes_clean <- med_dep_codes_merge[,c(3,1,2)]
  names(med_dep_codes_clean)[3] <- "readterm"
  
  # Save
  write.xlsx(med_dep_codes_clean, "data/codelists/excel/dep_cond.xlsx", row.names = FALSE)
  

  
  # backpain: Condition --------------------------------------------------------
  # From: 10.1136/bmj.d3590
  med_bp_codes_cc <- read.xlsx("data/external/backpain.xlsx", sheetIndex = 1, header = FALSE)
  
  # Limit to READ codes
  med_bp_codes_cc <- med_bp_codes_cc[which(med_bp_codes_cc$X2 == "Read"),]
  
  # Keep only needed columns and rename for merge
  med_bp_codes_cc <- med_bp_codes_cc[,c(1,3)]
  names(med_bp_codes_cc)[1] <- "readcode"
  names(med_bp_codes_cc)[2] <- "description"
  
  # Merge with meddict to find relevant medcode
  med_bp_codes_merge <- merge (med_bp_codes_cc, meddict, by = "readcode")
  
  # Clean resulting dataset
  med_bp_codes_clean <- med_bp_codes_merge[,c(3,1,2)]
  names(med_bp_codes_clean)[3] <- "readterm"
  
  # Save
  write.xlsx(med_bp_codes_clean, "data/codelists/excel/backpain_cond.xlsx", row.names = FALSE)
  
  
  
  # Ischemic heart disease: Condition --------------------------------------------------------
  # From 10.1136/bmjopen-2014-004952
  med_ihd_codes_cc <- read.xlsx("data/external/ihd.xlsx", sheetIndex = 1, header = FALSE)
  
  # Limit to READ codes
  med_ihd_codes_cc <- med_ihd_codes_cc[which(med_ihd_codes_cc$X2 == "Read"),]
  
  # Keep only needed columns and rename for merge
  med_ihd_codes_cc <- med_ihd_codes_cc[,c(1,3)]
  names(med_ihd_codes_cc)[1] <- "readcode"
  names(med_ihd_codes_cc)[2] <- "description"
  
  # Merge with meddict to find relevant medcode
  med_ihd_codes_merge <- merge (med_ihd_codes_cc, meddict, by = "readcode")
  
  # Clean resulting dataset
  med_ihd_codes_clean <- med_ihd_codes_merge[,c(3,1,2)]
  names(med_ihd_codes_clean)[3] <- "readterm"
  
  # Save
  write.xlsx(med_ihd_codes_clean, "data/codelists/excel/ihd_cond.xlsx", row.names = FALSE)
  
  

# Statins - lipo vs hydro philic -------------------------------------------
# Creates hydro/lipophilic info to prodcode
# Use in sensitivity analysis to split by type  

lipo_pattern <- "[Aa]torvastatin|[Ll]ovastatin|[Ss]imvastatin|[Cc]erivastatin"
hydro_pattern <- "[Pp]ravastatin|[Rr]osuvastatin|[Ff]luvastatin" 
  
  
code_sta <- rio::import("data/external/venexia_all.xlsx", which = "prod_hc_sta") %>%
    mutate(prodcode = cprd_prodcode,
           type = case_when(grepl(lipo_pattern,description2) ~ "Lipophilic",
                            grepl(hydro_pattern,description2) ~ "Hydrophilic")) %>%
  select(prodcode, type)

rio::export(code_sta, "data/codelists/excel/prod_hc_sta.xlsx", row.names = FALSE)



# Diabetes ----------------------------------------------------------------

med_t1d_codes_cc <- rio::import("data/external/venexia_all.xlsx", which = "med_dm_type1")

names(med_t1d_codes_cc)[1] <- "medcode"
names(med_t1d_codes_cc)[2] <- "readcode"
names(med_t1d_codes_cc)[3] <- "readterm"

med_t1d_codes_cc$medcode <- as.character(med_t1d_codes_cc$medcode)

rio::export(med_t1d_codes_cc, "data/codelists/excel/dm_type1_cond.xlsx", row.names = FALSE)


med_t2d_codes_cc <- rio::import("data/external/venexia_all.xlsx", which = "med_dm_type2")

names(med_t2d_codes_cc)[1] <- "medcode"
names(med_t2d_codes_cc)[2] <- "readcode"
names(med_t2d_codes_cc)[3] <- "readterm"

med_t2d_codes_cc$medcode <- as.character(med_t2d_codes_cc$medcode)

rio::export(med_t2d_codes_cc, "data/codelists/excel/dm_type2_cond.xlsx", row.names = FALSE)


# Chronic Kidney Disease --------------------------------------------------

med_ckd_codes_cc <- rio::import("data/codelists/excel/ckd_cond.xlsx")

med_ckd_codes_cc$medcode <- as.character(med_ckd_codes_cc$medcode)

rio::export(med_ckd_codes_cc, "data/codelists/excel/ckd_cond.xlsx", row.names = FALSE)


# Smeeth codelists -------------------------------------------------------------
# AD
smeeth_azd <- rio::import("data/codelists/excel/smeeth_azd.xlsx")

smeeth_azd <- merge(smeeth_azd, meddict, by = "readcode")[c(2,1,7)]

rio::export(smeeth_azd, "data/codelists/excel/smeeth_azd.xlsx", row.names = FALSE)

# Other

smeeth_oth <- rio::import("data/codelists/excel/smeeth_oth.xlsx")

smeeth_oth <- merge(smeeth_oth, meddict, by = "readcode")[c(2,1,7)]

rio::export(smeeth_oth, "data/codelists/excel/smeeth_oth.xlsx", row.names = FALSE)
