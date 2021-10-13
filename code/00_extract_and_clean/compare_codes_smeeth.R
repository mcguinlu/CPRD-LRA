# Smeeth codes
smeeth <- rio::import("data/external/smeeth_codes.xlsx") %>%
  mutate(alzheimers = alzhemiers) %>%
  select(-alzhemiers)
  filter(is.na(prevalent))
  select(-c(prevalent,include,alzhemiers))

smeeth_oth <- tidyr::drop_na(smeeth, other)[,1]

smeeth_azd <- tidyr::drop_na(smeeth, alzheimers)[,1]

# Our codes

data_adposs <- rio::import("data/external/venexia_all.xlsx", which = "med_dem_adposs")
data_adprob <- rio::import("data/external/venexia_all.xlsx", which = "med_dem_adprob")

ours_azdprob <- c(data_adprob[,2])

ours_azd <- c(data_adprob[,2], data_adposs[,2])

data_oth <- rio::import("data/external/venexia_all.xlsx", which = "med_dem_oth")

# All AzD codes used by Smeeth are included in our definition of AzD 
table(smeeth_azd %in% ours_azdprob)

# We have extra codes for Probable AzD that are not in Smeeth's definition
table(ours_azdprob %in% smeeth_azd)

# Some of the codes in Smeeths "other" list are in our Alzheimer's list
table(smeeth_oth %in% ours_azd)


# Create Smeeth codes lists

smeeth_azd <- data.frame(readcode = smeeth_azd)

write.xlsx(smeeth_azd, "data/codelists/excel/smeeth_azd.xlsx", row.names = FALSE)

smeeth_oth <- data.frame(readcode = smeeth_oth)

write.xlsx(smeeth_oth, "data/codelists/excel/smeeth_oth.xlsx", row.names = FALSE)







