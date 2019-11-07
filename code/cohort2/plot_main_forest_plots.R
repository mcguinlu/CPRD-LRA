library(ggplot2)
library(forcats)
library(gridExtra)
library(RGraphics)

cohort2results <- read.csv(here::here("output", "analysis-cohort2_reg.csv"),header=TRUE)

cohort2results1 <-
  cohort2results[which(
      cohort2results$outcome == "Probable AD" &
      (cohort2results$covariates == "full" |
      cohort2results$covariates == "full+tc") &
      (cohort2results$age =="All" |  
      cohort2results$age =="") &
      cohort2results$drug != "Ezetimibe and Statins" & # remove tiny groups
      cohort2results$drug != "Nicotinic acid groups" # remove tiny groups
  ), ]

cohort2results1$drug <- factor(cohort2results1$drug, levels = c("Any", "Statins","Fibrates", "Bile acid sequestrants","Omega-3 Fatty Acid Groups","Ezetimibe"))
cohort2results1 <- cohort2results1[order(cohort2results1$drug ),]


cohort2results1$grouping <- "Single"
cohort2results1$grouping[which(cohort2results1$drug=="Any")] <- "All"

cohort2results1$Covariate.Group <- "full"
cohort2results1$Covariate.Group[which(cohort2results1$covariates=="full+tc")] <- "full+tc"

cohort2results1$label <- paste0( "HR: ",
                        ifelse(sprintf("%.2f",cohort2results1$HR)<0.0051,
                               format(cohort2results1$HR,scientific = TRUE,digits=3),
                               sprintf("%.2f",cohort2results1$HR)),
                        " (95% CI: ", 
                        ifelse(sprintf("%.2f",cohort2results1$ci_lower)<0.0051,
                               format(cohort2results1$ci_lower,scientific = TRUE,digits=3),
                               sprintf("%.2f",cohort2results1$ci_lower)),
                        " to ",
                        ifelse(sprintf("%.2f",cohort2results1$ci_upper)<0.0051,
                               format(cohort2results1$ci_upper,scientific = TRUE,digits=3),
                               sprintf("%.2f",cohort2results1$ci_upper)),
                        "), N: ",
                        cohort2results1$N_sub)




cohort2results1$label <- factor(cohort2results1$label, levels=unique(cohort2results1$label[order(cohort2results1$covariates)]), ordered=TRUE)


g1 <- 
  ggplot(cohort2results1, aes(y = HR, x = 1, colour = Covariate.Group)) + 
  geom_linerange(aes(ymin = ci_lower, ymax = ci_upper), size = .8) +
  geom_point(size = 2) + 
  facet_grid(drug + label ~ ., switch="both") +
  theme_minimal() +
  coord_flip() +
  scale_color_manual(values = c("black","#999999")) +
  geom_hline(yintercept=1, linetype = 2) +
  scale_x_discrete(name = "", position = "bottom") +
  scale_y_log10(limits = c(0.18, 4.5), 
                breaks = c(0.3, 1, 3),
                name = "HR and 95% CI comparing those treated with a \nlipid regulating drug class to those not treated.") +
  theme(panel.grid.major.y = element_blank(), 
        panel.grid.minor = element_blank(),
        axis.text.x=element_text(size=10, colour = "black"),
        axis.text.y = element_blank(),
        text=element_text(size=8), 
        axis.title.x = element_text(size = 10),
        strip.text.y = element_text(size = 10, angle = 180, hjust=0.5),
        panel.spacing = unit(0, "lines"),
        legend.position = "bottom",
        legend.text = element_text(size = 10),
        legend.title = element_text(size = 10)
        ) +
  NULL


g2 <- grid.arrange(g1, ncol=1,
             top = textGrob("Results of the Cox regression analysis for probable AzD, \nallowing for time-varying treatment and adjusting for baseline confounders \n",
                            gp=gpar(fontsize=12,font=1)) )

ggsave("output/fp_cox_probad.jpeg",g2,height = 6, width = 15, unit = "cm", dpi = 600, scale = 1.75)


cohort2results2 <-
  cohort2results[which(
    cohort2results$drug == "Any" &
      (cohort2results$covariates == "full" |
         cohort2results$covariates == "full+tc") &
      (cohort2results$age =="All" |
         cohort2results$age =="")
  ), ]

cohort2results2$outcome <- factor(cohort2results2$outcome, levels = c("Probable AD","Possible AD", "Vascular dementia","Other dementia", "Any dementia"))
cohort2results2 <- cohort2results2[order(cohort2results2$outcome ),]


cohort2results2$grouping <- "Single"
cohort2results2$grouping[which(cohort2results2$outcome=="Any dementia")] <- "All"

cohort2results2$Covariate.Group <- "full"
cohort2results2$Covariate.Group[which(cohort2results2$covariates=="full+tc")] <- "full+tc"

cohort2results2$label <- paste0( "HR: ",
                                 ifelse(sprintf("%.2f",cohort2results2$HR)<0.0051,
                                        format(cohort2results2$HR,scientific = TRUE,digits=3),
                                        sprintf("%.2f",cohort2results2$HR)),
                                 " (95% CI: ",
                                 ifelse(sprintf("%.2f",cohort2results2$ci_lower)<0.0051,
                                        format(cohort2results2$ci_lower,scientific = TRUE,digits=3),
                                        sprintf("%.2f",cohort2results2$ci_lower)),
                                 " to ",
                                 ifelse(sprintf("%.2f",cohort2results2$ci_upper)<0.0051,
                                        format(cohort2results2$ci_upper,scientific = TRUE,digits=3),
                                        sprintf("%.2f",cohort2results2$ci_upper)),
                                 "), N: ",
                                 cohort2results2$N_sub)

cohort2results2$label <- factor(cohort2results2$label, levels=unique(cohort2results2$label[order(cohort2results2$covariates)]), ordered=TRUE)



g3 <- ggplot(cohort2results2, aes(y = HR, x = 1, colour = Covariate.Group)) +
  geom_linerange(aes(ymin = ci_lower, ymax = ci_upper), size = .8) +
  geom_point(size = 2) +
  facet_grid(outcome + label ~ ., switch="both") +
  theme_minimal() +
  coord_flip() +
  scale_color_manual(values = c("black","#999999")) +
  geom_hline(yintercept=1, linetype = 2) +
  scale_x_discrete(name = "", position = "bottom") +
  scale_y_log10(limits = c(0.18, 2.5),
                breaks = c(0.3, 1, 3),
                name = "HR and 95% CI comparing those treated with a \nlipid regulating drug class to those not treated.") +
  theme(panel.grid.major.y = element_blank(),
        panel.grid.minor = element_blank(),
        axis.text.x=element_text(size=10, colour = "black"),
        axis.text.y = element_blank(),
        text=element_text(size=8),
        axis.title.x = element_text(size = 10),
        strip.text.y = element_text(size = 10, angle = 180, hjust=0.5),
        panel.spacing = unit(0, "lines"),
        legend.position = "bottom",
        legend.text = element_text(size = 10),
        legend.title = element_text(size = 10)
  ) +
  NULL

g4 <- grid.arrange(g3, ncol=1,
                   top = textGrob("Results of the Cox regression analysis by dementia subgroup, \n allowing for time-varying treatment and adjusting for baseline confounders \n",
                                  gp=gpar(fontsize=12,font=1)) )

ggsave("output/fp_cox_alldem.jpeg",g4, height = 6, width = 15, unit = "cm", dpi = 600, scale = 1.75)


cohort2results1 <-
  cohort2results[which(
    cohort2results$outcome == "Vascular dementia" &
      (cohort2results$covariates == "full" |
         cohort2results$covariates == "full+tc") &
      (cohort2results$age =="All" |  
         cohort2results$age =="") &
      cohort2results$drug != "Ezetimibe and Statins" & # remove tiny groups
      cohort2results$drug != "Nicotinic acid groups" # remove tiny groups
  ), ]

cohort2results1$drug <- factor(cohort2results1$drug, levels = c("Any", "Statins","Fibrates", "Bile acid sequestrants","Omega-3 Fatty Acid Groups","Ezetimibe"))
cohort2results1 <- cohort2results1[order(cohort2results1$drug ),]


cohort2results1$grouping <- "Single"
cohort2results1$grouping[which(cohort2results1$drug=="Any")] <- "All"

cohort2results1$Covariate.Group <- "full"
cohort2results1$Covariate.Group[which(cohort2results1$covariates=="full+tc")] <- "full+tc"

cohort2results1$label <- paste0( "HR: ",
                                 ifelse(sprintf("%.2f",cohort2results1$HR)<0.0051,
                                        format(cohort2results1$HR,scientific = TRUE,digits=3),
                                        sprintf("%.2f",cohort2results1$HR)),
                                 " (95% CI: ", 
                                 ifelse(sprintf("%.2f",cohort2results1$ci_lower)<0.0051,
                                        format(cohort2results1$ci_lower,scientific = TRUE,digits=3),
                                        sprintf("%.2f",cohort2results1$ci_lower)),
                                 " to ",
                                 ifelse(sprintf("%.2f",cohort2results1$ci_upper)<0.0051,
                                        format(cohort2results1$ci_upper,scientific = TRUE,digits=3),
                                        sprintf("%.2f",cohort2results1$ci_upper)),
                                 "), N: ",
                                 cohort2results1$N_sub)




cohort2results1$label <- factor(cohort2results1$label, levels=unique(cohort2results1$label[order(cohort2results1$covariates)]), ordered=TRUE)


g5 <- 
  ggplot(cohort2results1, aes(y = HR, x = 1, colour = Covariate.Group)) + 
  geom_linerange(aes(ymin = ci_lower, ymax = ci_upper), size = .8) +
  geom_point(size = 2) + 
  facet_grid(drug + label ~ ., switch="both") +
  theme_minimal() +
  coord_flip() +
  scale_color_manual(values = c("black","#999999")) +
  geom_hline(yintercept=1, linetype = 2) +
  scale_x_discrete(name = "", position = "bottom") +
  scale_y_log10(limits = c(0.18, 20), 
                breaks = c(0.3, 1, 3),
                name = "HR and 95% CI comparing those treated with a \nlipid regulating drug class to those not treated.") +
  theme(panel.grid.major.y = element_blank(), 
        panel.grid.minor = element_blank(),
        axis.text.x=element_text(size=10, colour = "black"),
        axis.text.y = element_blank(),
        text=element_text(size=8), 
        axis.title.x = element_text(size = 10),
        strip.text.y = element_text(size = 10, angle = 180, hjust=0.5),
        panel.spacing = unit(0, "lines"),
        legend.position = "bottom",
        legend.text = element_text(size = 10),
        legend.title = element_text(size = 10)
  ) +
  NULL


g6 <- grid.arrange(g5, ncol=1,
                   top = textGrob("Results of the Cox regression analysis for VaD, \nallowing for time-varying treatment and adjusting for baseline confounders \n",
                                  gp=gpar(fontsize=12,font=1)) )

ggsave("output/fp_cox_vad.jpeg",g6,height = 6, width = 15, unit = "cm", dpi = 600, scale = 1.75)


