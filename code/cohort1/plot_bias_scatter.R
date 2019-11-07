# Load data =================================================================

df <- read.csv("output/bias_scatter.csv",stringsAsFactors = FALSE)

df <- reshape(df,idvar=c("cov","dem_out","ref","interest"),timevar = "analysis",direction = "wide")

# Mark binary and continuous analyses =======================================

bin.cov <- c("male","cad","cbs","cvd","never_drink","never_smoke")

df$bin.cont <- ifelse(df$cov %in% bin.cov,
                      "binary",
                      "continous")

# Tidy covariate names ======================================================

cov.names <- data.frame(cov = c("bmi","cad","cbs","charlson","cons_rate",
                                "cvd","imd2010","index_age_start","male",
                                "never_drink","never_smoke"),
                        cov.name = c("BMI",
                                     "Ever coronary artery disease [vs never]",
                                     "Ever coronary bypass surgery [vs never]",
                                     "Charlson index for chronic disease",
                                     "Annual consultation rate",
                                     "Ever cerebrovascular disease [vs never]",
                                     "Index of Multiple Deprivation 2010",
                                     "Age at index",
                                     "Male [vs female]",
                                     "Never drinker [vs ever]",
                                     "Never smoker [vs ever]"))

df <- merge(df,cov.names,by="cov",all.x = TRUE)

# Mark analyses to include ==================================================

drugs <- c("ht_aab","ht_arb","ht_ace","ht_bab","ht_ccb","ht_diu","ht_vad")

df$include <- 1
c <- 1

for (i in drugs[1:6]) {
  c <- c + 1
  j <- drugs[c:7]
  df[df$ref==i & df$interest %in% j,]$include <- 0
}

# Format confidence intervals and estimates =================================

df$lci.iv <- ifelse(sign(df$coef.iv)==-1,-1*df$ci_upper.iv,df$ci_lower.iv)
df$uci.iv <- ifelse(sign(df$coef.iv)==-1,-1*df$ci_lower.iv,df$ci_upper.iv)
df$est.iv <- ifelse(sign(df$coef.iv)==-1,-1*df$coef.iv,df$coef.iv)

df$lci.lin <- ifelse(sign(df$coef.lin)==-1,-1*df$ci_upper.lin,df$ci_lower.lin)
df$uci.lin <- ifelse(sign(df$coef.lin)==-1,-1*df$ci_lower.lin,df$ci_upper.lin)
df$est.lin <- ifelse(sign(df$coef.lin)==-1,-1*df$coef.lin,df$coef.lin)

## Generate plots ===========================================================

t <- 12

for (outcome in unique(df$dem_out)) {
  
  tmp_min <- df[df$dem_out==outcome & df$include==1,c("cov.name","lci.iv","lci.lin")] %>% 
    group_by(cov.name) %>% 
    summarise(facet_min = min(lci.iv,lci.lin)) %>%
    ungroup()
  
  tmp_max <- df[df$dem_out==outcome & df$include==1,c("cov.name","uci.iv","uci.lin")] %>% 
    group_by(cov.name) %>% 
    summarise(facet_max = max(uci.iv,uci.lin)) %>%
    ungroup()
  
  dummy <- data.frame(cov.name = rep(tmp_min$cov.name,4),
                      est.lin = c(tmp_min$facet_min,
                                  tmp_min$facet_min,
                                  tmp_max$facet_max,
                                  tmp_max$facet_max),
                      est.iv = c(tmp_min$facet_min,
                                 tmp_max$facet_max,
                                 tmp_min$facet_min,
                                 tmp_max$facet_max),
                      lci.iv = NA,
                      uci.iv = NA,
                      lci.lin = NA,
                      uci.lin = NA,
                      stringsAsFactors = FALSE)
  
  dfplot <- rbind(df[df$dem_out==outcome & df$include==1,
                     c("cov.name","est.iv","est.lin","lci.iv","uci.iv",
                       "lci.lin","uci.lin")],dummy)
  
  ggplot(dfplot, aes(x=est.lin, y=est.iv)) +
    geom_point(col = "white") +
    geom_abline(slope=1, col = "grey") +
    geom_vline(xintercept = 0, col = "grey") +
    geom_hline(yintercept = 0, col = "grey") +
    geom_errorbar(aes(ymin = lci.iv,ymax = uci.iv)) + 
    geom_errorbarh(aes(xmin = lci.lin,xmax = uci.lin)) +
    labs(x = "Multivariable linear regression analysis estimate (absolute value)",
         y = "Instrumental variable analysis estimate (absolute value)") +
    theme_bw() +
    theme(panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          strip.background = element_rect(fill="white"),
          plot.title = element_text(size=t, hjust=0),
          axis.text=element_text(size=t),
          axis.title=element_text(size=t),
          strip.text = element_text(size=t)) +
    facet_wrap(~cov.name, scales = "free")
  
  ggsave(paste0("output/bias_scatter_",outcome,".jpeg"), 
         height = 8, width = 15, unit = "cm", 
         dpi = 600, scale = 2.75)
  
}