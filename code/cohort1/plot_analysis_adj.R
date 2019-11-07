# Load data ===================================================================

df <- read.csv("output/analysis_reg_adj.csv",stringsAsFactors = FALSE)
df$adj <- gsub(" ","",df$adj)

# Prepare data using common file ==============================================

source("code/plot_prepare.R")

# Generate plot for each adjusted analysis ====================================

for (i in unique(df$adj)) {
  
  ggplot(df[df$include==1 & df$adj==i,], aes(x = treat_ref, y = treat_int, label = gtext)) +
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
  
  ggsave(paste0("output/analysis_reg_adj_",i,".jpeg"), height = 8, width = 15, unit = "cm", dpi = 600, scale = 3.5)
  
}
