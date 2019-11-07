# Load data ===================================================================

df <- read.csv("output/analysis_reg.csv", 
               stringsAsFactors = FALSE)

# Prepare data using common file ==============================================

source("code/plot_prepare.R")

# Group dementia subtypes =====================================================

df$group <- ifelse(df$outcome=="Any dementia","any",NA)
df$group <- ifelse(df$outcome %in% c("Other dementias","Vascular dementia"),"non_AD",df$group)
df$group <- ifelse(df$outcome %in% c("Possible AD","Probable AD"),"AD",df$group)

# Generate plot for each group ================================================

for (i in unique(df$group)) {

  ggplot(df[df$include==1 & df$cohort==1 & df$group==i,], aes(x = treat_ref, y = treat_int, label = gtext)) +
    labs(x = "Reference drug class", y = "Drug class of interest", 
         fill = "Additional cases per 1000 \ntreated (95% CI); p-value.\n[X] indicates <100 cases. ") +
    scale_x_discrete(limits = drugs, position = "top", 
                     labels = function(x) str_wrap(levels(df$treat_ref), width = 22)) +
    scale_y_discrete(limits = rev(drugs),
                     labels = function(x) str_wrap(rev(levels(df$treat_ref)), width = 22)) +
    theme_bw() +
    theme(plot.title = element_text(size=t, hjust=0),
          panel.grid.major = element_blank(),
          axis.text=element_text(size=t),
          axis.title=element_text(size=t),
          legend.position = "bottom",
          legend.text=element_text(size=t),
          legend.title=element_text(size=t),
          panel.grid.minor = element_blank(),
          strip.text = element_text(size=t),
          strip.background = element_rect(fill="white")) +
    geom_tile(aes(fill = coef_di), colour = "white", size = 1.05) +
    geom_text(size = 0.36*t) +
    scale_fill_distiller(palette = "Spectral", guide = guide_colorbar(barwidth = 20), 
                         limits = c(-l,l), na.value = NA) +
    facet_wrap(~outcome, strip.position = "right", ncol = 1)
  
  ggsave(paste0("output/analysis_reg_",i,".jpeg"), height = 8, width = 15, unit = "cm", dpi = 600, scale = 2.75)
  
}

# Generate summary plot for each cohort =======================================

for (i in 1:5) {
  
  ggplot(df[df$include==1 & df$cohort==i,], aes(x = treat_ref, y = treat_int, label = gtext)) +
    labs(x = "Reference drug class", y = "Drug class of interest", 
         fill = "Additional cases per 1000 \ntreated (95% CI); p-value.\n[X] indicates <100 cases. ") +
    scale_x_discrete(limits = drugs, position = "top", 
                     labels = function(x) str_wrap(levels(df$treat_ref), width = 22)) +
    scale_y_discrete(limits = rev(drugs)) +
    theme_bw() +
    theme(plot.title = element_text(size=t, hjust=0),
          panel.grid.major = element_blank(),
          axis.text=element_text(size=t),
          axis.title=element_text(size=t),
          legend.position = "bottom",
          legend.text=element_text(size=t),
          legend.title=element_text(size=t),
          panel.grid.minor = element_blank(),
          strip.text = element_text(size=t),
          strip.background = element_rect(fill="white")) +
    geom_tile(aes(fill = coef_di), colour = "white", size = 1.05) +
    geom_text(size = 0.36*t) +
    scale_fill_distiller(palette = "Spectral", guide = guide_colorbar(barwidth = 20), 
                         limits = c(-l,l), na.value = NA) +
    facet_wrap(~outcome, strip.position = "right", ncol = 1)
  
  ggsave(paste0("output/analysis_reg_",i,".jpeg"), height = 8, width = 15, unit = "cm", dpi = 600, scale = 3.5)
  
}

# Generate summary plot for logit anlaysis ============================================

df$coef_di <- ifelse(df$analysis=="logit",log(df$coef),df$coef_di)

ggplot(df[df$include==1 & df$cohort==0,], aes(x = treat_ref, y = treat_int, label = gtext)) +
  labs(x = "Reference drug class", y = "Drug class of interest", 
       fill = "OR (95% CI); p-value.\n[X] indicates <100 cases. \n") +
  scale_x_discrete(limits = drugs, position = "top", 
                   labels = function(x) str_wrap(levels(df$treat_ref), width = 22)) +
  scale_y_discrete(limits = rev(drugs)) +
  theme_bw() +
  theme(plot.title = element_text(size=t, hjust=0),
        panel.grid.major = element_blank(),
        axis.text=element_text(size=t),
        axis.title=element_text(size=t),
        legend.position = "bottom",
        legend.text=element_text(size=t),
        legend.title=element_text(size=t),
        panel.grid.minor = element_blank(),
        strip.text = element_text(size=t),
        strip.background = element_rect(fill="white")) +
  geom_tile(aes(fill = coef_di), colour = "white", size = 1.05) +
  geom_text(size = 0.36*t) +
  scale_fill_distiller(palette = "Spectral", guide = guide_colorbar(barwidth = 20), 
                       limits = c(-1.75,1.75), na.value = NA, 
                       breaks = log(c(0.25,0.5,1,2,4)), labels = sprintf("%.2f",c(0.25,0.5,1,2,4))) +
  facet_wrap(~outcome, strip.position = "right", ncol = 1)

ggsave("output/analysis_reg_0.jpeg", height = 8, width = 15, unit = "cm", dpi = 600, scale = 3.5)