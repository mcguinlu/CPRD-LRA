library(xlsx)


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
  proddict <-proddict[,c(1,9,4,5,2:3,6:8,10:12)]
  
  
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
  
  
# Peripheral artery disease: Condition -----------------------------------------
  # Load codes from BMJ paper, sourced from the Clinical Codes website
  # Source: https://clinicalcodes.rss.mhs.man.ac.uk/medcodes/article/6/codelist/peripheral-arterial-disease/
  
  med_pad_codes_cc <- read.xlsx("data/external/pad-raw.xlsx", sheetIndex = 1, header = FALSE)
  
  # Limit to "main" codes
  med_pad_codes_cc <- med_pad_codes_cc[which(med_pad_codes_cc$X6 == "Main"),]
  
  # Limit to READ codes
  med_pad_codes_cc <- med_pad_codes_cc[which(med_pad_codes_cc$X2 == "Read"),]
  
  # Keep only needed columns and remane for merge
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

  # Define treatments for perihperal artery disease based on NICE/BNF guidance
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
