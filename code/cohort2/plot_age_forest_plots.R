library(ggplot2)
library(forcats)
library(gridExtra)
library(RGraphics)

cohort2results <- read.csv(here::here("output", "analysis-cohort2_reg.csv"),header=TRUE)

cohort2results$age <- sub(">75",">=75",cohort2results$age)

cohort2results.age <-
  cohort2results[which(
      cohort2results$outcome == "Any dementia" &
      cohort2results$covariates == "full+tc" &
      cohort2results$drug != "Ezetimibe and Statins" & # remove tiny groups
      cohort2results$drug != "Nicotinic acid groups" # remove tiny groups
  ), ]

cohort2results.age$grouping <- "Single"
cohort2results.age$grouping[which(cohort2results.age$age=="All")] <- "All"


cohort2results.age$drug <- factor(cohort2results.age$drug, levels = c("Any", "Statins","Fibrates", "Bile acid sequestrants","Omega-3 Fatty Acid Groups","Ezetimibe"))
cohort2results.age <- cohort2results.age[order(cohort2results.age$drug ),]

cohort2results.age$age <- factor(cohort2results.age$age, 
                                 levels = c("All", "<65","65-74", ">=75",""))

cohort2results.age$age <- fct_rev(cohort2results.age$age)

cohort2results.age$labelpoint <- 25

cohort2results.age$label <- paste0( "HR: ",
                                 ifelse(sprintf("%.2f",cohort2results.age$HR)<0.0051,
                                        format(cohort2results.age$HR,scientific = TRUE,digits=3),
                                        sprintf("%.2f",cohort2results.age$HR)),
                                 " (95% CI: ", 
                                 ifelse(sprintf("%.2f",cohort2results.age$ci_lower)<0.0051,
                                        format(cohort2results.age$ci_lower,scientific = TRUE,digits=3),
                                        sprintf("%.2f",cohort2results.age$ci_lower)),
                                 " to ",
                                 ifelse(sprintf("%.2f",cohort2results.age$ci_upper)<0.0051,
                                        format(cohort2results.age$ci_upper,scientific = TRUE,digits=3),
                                        sprintf("%.2f",cohort2results.age$ci_upper)),
                                 "), N: ",
                                 cohort2results.age$N_sub)

g1<- ggplot(cohort2results.age, aes(y = HR, x = age, colour = grouping, label = label)) + 
  geom_linerange(aes(ymin = ci_lower, ymax = ci_upper), size = .8) +
  geom_point(size = 2) + 
  facet_grid(drug ~ ., switch="both") +
  geom_text(aes(y=labelpoint), colour = "black", size = 3.5, hjust=0 ) +
  theme_minimal() +
  coord_flip(clip = "off") +
  scale_color_manual(values = c("black","#999999")) +
  geom_hline(yintercept=1, linetype = 2) +
  scale_x_discrete(name = "", position = "bottom") +
  scale_y_log10(limits = c(0.18,500), 
                breaks = c(0.3, 1, 3),
                name = "HR and 95% CI for developing probable Alzheimer's disease comparing \nthose treated with a lipid regulating drug class to those not treated.") +
  theme(panel.grid.major.y = element_blank(), 
        panel.grid.minor = element_blank(),
        axis.text.x=element_text(size=10, colour = "black"),
        axis.text.y = element_text(size=10, colour = "black"),
        text=element_text(size=8), 
        axis.title.x = element_text(size = 10),
        strip.text.y = element_text(size = 10, angle = 180, hjust=0),
        panel.spacing = unit(1, "lines"),
        legend.position = "bottom",strip.placement = "outside",
        legend.text = element_text(size = 10),
        legend.title = element_text(size = 10), 
        plot.margin = unit(c(1,3,1,1), "cm")
  ) +
  NULL

g2 <- grid.arrange(g1, ncol=1,
                   top = textGrob("Results of the Cox regression analysis, by age group, for the probable AD outcome",
                                  gp=gpar(fontsize=12,font=1)) )

ggsave("output/fp_cox_probad_age.jpeg",g2,height =10, width = 15, unit = "cm", dpi = 600, scale = 1.75)

