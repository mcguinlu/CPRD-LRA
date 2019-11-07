# List all drugs under consideration ==========================================

drugs <- c("Alpha-adrenoceptor blockers",
           "Angiotensin-II receptor blockers",
           "Angiotensin converting enzyme inhibitors",
           "Beta-adrenoceptor blockers",
           "Calcium channel blockers",
           "Diuretics",
           "Vasodilator antihypertensives")

# Remove outcome death (not plotted) ==========================================

df <- df[df$outcome!="death",]

# Mark logit analysis as cohort 0 =============================================

df$cohort <- ifelse(df$analysis=="logit",0,df$cohort)

# Format outcome labels =======================================================

df$outcome <- ifelse(df$outcome=="dem_any","Any dementia",df$outcome)
df$outcome <- ifelse(df$outcome=="dem_oth","Other dementias",df$outcome)
df$outcome <- ifelse(df$outcome=="dem_vas","Vascular dementia",df$outcome)
df$outcome <- ifelse(df$outcome=="dem_adposs","Possible AD",df$outcome)
df$outcome <- ifelse(df$outcome=="dem_adprob","Probable AD",df$outcome)

# Format treatment of interest labels =========================================

df$treat_int <- ifelse(df$treat_int=="ht_aab","Alpha-adrenoceptor blockers",df$treat_int)
df$treat_int <- ifelse(df$treat_int=="ht_ace","Angiotensin converting enzyme inhibitors",df$treat_int)
df$treat_int <- ifelse(df$treat_int=="ht_arb","Angiotensin-II receptor blockers",df$treat_int)
df$treat_int <- ifelse(df$treat_int=="ht_bab","Beta-adrenoceptor blockers",df$treat_int)
df$treat_int <- ifelse(df$treat_int=="ht_ccb","Calcium channel blockers",df$treat_int)
df$treat_int <- ifelse(df$treat_int=="ht_diu","Diuretics",df$treat_int)
df$treat_int <- ifelse(df$treat_int=="ht_vad","Vasodilator antihypertensives",df$treat_int)

# Format reference treatment labels ===========================================

df$treat_ref <- ifelse(df$treat_ref=="ht_aab","Alpha-adrenoceptor blockers",df$treat_ref)
df$treat_ref <- ifelse(df$treat_ref=="ht_ace","Angiotensin converting enzyme inhibitors",df$treat_ref)
df$treat_ref <- ifelse(df$treat_ref=="ht_arb","Angiotensin-II receptor blockers",df$treat_ref)
df$treat_ref <- ifelse(df$treat_ref=="ht_bab","Beta-adrenoceptor blockers",df$treat_ref)
df$treat_ref <- ifelse(df$treat_ref=="ht_ccb","Calcium channel blockers",df$treat_ref)
df$treat_ref <- ifelse(df$treat_ref=="ht_diu","Diuretics",df$treat_ref)
df$treat_ref <- ifelse(df$treat_ref=="ht_vad","Vasodilator antihypertensives",df$treat_ref)

# Make IV estimates per 1000 people treated ====================================

df$coef <- ifelse(df$analysis=="iv",1000*df$coef,df$coef)
df$ci_lower <- ifelse(df$analysis=="iv",1000*df$ci_lower,df$ci_lower)
df$ci_upper <- ifelse(df$analysis=="iv",1000*df$ci_upper,df$ci_upper)

# Use NA for estimates that do not have >0 for each treatment-outcome combination

df$coef <- ifelse(df$X0Y0==0 | df$X0Y1==0 | df$X1Y0==0 | df$X1Y1==0,NA,df$coef)
df$ci_lower <- ifelse(df$X0Y0==0 | df$X0Y1==0 | df$X1Y0==0 | df$X1Y1==0,NA,df$ci_lower)
df$ci_upper <- ifelse(df$X0Y0==0 | df$X0Y1==0 | df$X1Y0==0 | df$X1Y1==0,NA,df$ci_upper)
df$pval <- ifelse(df$X0Y0==0 | df$X0Y1==0 | df$X1Y0==0 | df$X1Y1==0,NA,df$pval)

# Format estimate labels ======================================================

df$gtext <- ifelse(df$analysis=="iv",
                   paste0(sprintf("%.0f",df$coef)," (",
                          sprintf("%.0f",df$ci_lower)," to ",
                          sprintf("%.0f",df$ci_upper),"); ",
                          format(df$pval,scientific = TRUE,digits =2)),
                   paste0(sprintf("%.1f",df$coef)," (",
                          sprintf("%.1f",df$ci_lower)," to ",
                          sprintf("%.1f",df$ci_upper),"); ",
                          format(df$pval,scientific = TRUE,digits =2)))

df$gtext <- ifelse(is.na(df$coef),NA,df$gtext)
df$gtext <- ifelse(df$X0Y1+df$X1Y1<100 & !is.na(df$coef),paste0(df$gtext," [X]"),df$gtext)

# Mark analyses to present (i.e. top right half of matrix) ====================

df$include <- 1
c <- 1

for (i in drugs[1:6]) {
  c <- c + 1
  j <- drugs[c:7]
  df[df$treat_ref==i & df$treat_int %in% j,]$include <- 0
}

df$outcome <- factor(df$outcome,levels(factor(df$outcome))[c(4,3,5,2,1)])

# Set standard text sizes =====================================================

t <- 12

# Factor reference treatment to aid plotting ==================================

df$treat_ref <- factor(df$treat_ref)

# Set limit for colours and define colours for estimates outside limits as max

l <- 30
df$coef_di <- ifelse(abs(df$coef)>l,sign(df$coef)*l,df$coef)