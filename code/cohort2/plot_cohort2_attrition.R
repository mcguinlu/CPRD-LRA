library(DiagrammeR)
library(htmltools)
library(webshot)
library(dplyr)
library(here)

#Define main dataset
main <- read.csv(here("output","cohorta2_attrition.csv"))

# Define node names
main[1,2] <- paste0("M0")
for (i in 1:13) {
  main[1+i,2] <- paste0("M",i)
}
for (i in 1:13) {
  main[14+i,2] <- paste0("S",i)
}
colnames(main)[2] <- "Node"

main <- main[,c(2,1)]

# Create figures for number removed
for (i in 1:13) {
  main[14+i,2] <- as.numeric(main[i,2])-as.numeric(main[i+1,2])
}

# Create labels
main[1,3] <- paste0("Data extract from the CPRD for ISAC Protocol 15_246R\n(n=", main[1,2],")")
main[2,3] <- paste0("Patients without an index event of interest\n(n=", main[2,2],")")
main[3,3] <- paste0("Patients flagged as acceptable by the CPRD\n(n=", main[3,2],")")
main[4,3] <- paste0("Patients with an index date after the data extract start date (1/1/87)\n(n=", main[4,2],")")
main[5,3] <- paste0("Patients with an index date before the data extract end date (29/02/16)\n(n=", main[5,2],")")
main[6,3] <- paste0("Patients aged 40 and over at index\n(n=", main[6,2],")")
main[7,3] <- paste0("Patients with a minimum of 12 months worth of data prior to index\n(n=", main[7,2],")")
main[8,3] <- paste0("Patients alive at index\n(n=", main[8,2],")")
main[9,3] <- paste0("Patients with an index date prior to the last collection date for their practice\n(n=", main[9,2],")")
main[10,3] <- paste0("Patients with an index date prior to their transferral out of practice\n(n=", main[10,2],")")
main[11,3] <- paste0("Patients recorded as male or female\n(n=", main[11,2],")")
main[12,3] <- paste0("Patients initally prescribed a single class of lipid regulating agents \n(n=", main[12,2],")")
main[13,3] <- paste0("Patients whose follow-up ends after their index date\n(n=", main[13,2],")")
main[14,3] <- paste0("Patients with an index date after 1/1/1996\n(n=", main[14,2],")")

main[15,3] <- paste0("Patients without an index event of interest\n(n=", main[15,2],")")
main[16,3] <- paste0("Patients falgged as unacceptable by the CPRD\n(n=", main[16,2],")")
main[17,3] <- paste0("Patients with an index date prior to the data extract start date (1/1/87)\n(n=", main[17,2],")")
main[18,3] <- paste0("Patients with an index date after the data extract end date (29/02/16)\n(n=", main[18,2],")")
main[19,3] <- paste0("Patients aged under 40 at index\n(n=", main[19,2],")")
main[20,3] <- paste0("Patients with less than 12 months worth of data prior to index\n(n=", main[20,2],")")
main[21,3] <- paste0("Patients with an index date after death\n(n=", main[21,2],")")
main[22,3] <- paste0("Patients with an index date after the last collection date for their practice\n(n=", main[22,2],")")
main[23,3] <- paste0("Patients with an index date after their transferral out of practice\n(n=", main[23,2],")")
main[24,3] <- paste0("Patients of an unknown gender\n(n=", main[24,2],")")
main[25,3] <- paste0("Patients initally receiving >1 class of lipid regulating agents\n(n=", main[25,2],")")
main[26,3] <- paste0("Patients whose follow-up ends prior to their index date\n(n=", main[26,2],")")
main[27,3] <- paste0("Patients with an index date prior to 1/1/1996\n(n=", main[27,2],")")

colnames(main)[3] <- "Label"  



# Create graph
graph <- grViz("digraph flowchart {
      # node definitions with substituted label text
      node [fontname = Helvetica, shape = rectangle]

      M1 [width = 7];
M2 [width = 7];
M3 [width = 7];
M4 [width = 7];
M5 [width = 7];
M6 [width = 7];
M7 [width = 7];
M8 [width = 7];
M9 [width = 7];
M10 [width = 7];
M11 [width = 7];
M12 [width = 7];
M13 [width = 7];
M14 [width = 7];
S1 [width = 7];
S2 [width = 7];
S3 [width = 7];
S4 [width = 7];
S5 [width = 7];
S6 [width = 7];
S7 [width = 7];
S8 [width = 7];
S9 [width = 7];
S10 [width = 7];
S11 [width = 7];
S12 [width = 7];
S13 [width = 7]

      #Define ranks
      subgraph {
          rank = same; M2; S1
      }
      subgraph {
          rank = same; M3; S2
      }
      subgraph {
          rank = same; M4; S3
      }
      subgraph {
          rank = same; M5; S4
      }
      subgraph {
          rank = same; M6; S5
      }
      subgraph {
          rank = same; M7; S6
      }
      subgraph {
          rank = same; M8; S7
      }
      subgraph {
          rank = same; M9; S8
      }
      subgraph {
          rank = same; M10; S9
      }
      subgraph {
          rank = same; M11; S10
      }
      subgraph {
          rank = same; M12; S11
      }
      subgraph {
          rank = same; M13; S12
      }
      subgraph {
          rank = same; M14; S13
      }
      
      # edge definitions with the node IDs
      M1 -> M2 -> M3-> M4 -> M5 -> M6 -> M7 -> M8 -> M9 -> M10 -> M11 -> M12 -> M13 -> M14
      M2 -> S1 [arrowhead = none]
      M3 -> S2 [arrowhead = none]
      M4 -> S3 [arrowhead = none]
      M5 -> S4 [arrowhead = none] 
      M6 -> S5 [arrowhead = none] 
      M7 -> S6 [arrowhead = none]
      M8 -> S7 [arrowhead = none]
      M9 -> S8 [arrowhead = none]
      M10 -> S9 [arrowhead = none]
      M11 -> S10 [arrowhead = none]
      M12 -> S11 [arrowhead = none]
      M13 -> S12 [arrowhead = none]
      M14 -> S13 [arrowhead = none]
      
      
      # Define labels
      M1 [label = '@@1-1']
      M2 [label = '@@1-2']
      M3 [label = '@@1-3']
      M4 [label = '@@1-4']
      M5 [label = '@@1-5']
      M6 [label = '@@1-6']
      M7 [label = '@@1-7']
      M8 [label = '@@1-8']
      M9 [label = '@@1-9']
      M10 [label = '@@1-10']
      M11 [label = '@@1-11']
      M12 [label = '@@1-12']
      M13 [label = '@@1-13']
      M14 [label = '@@1-14']
      S1 [label = '@@1-15']
      S2 [label = '@@1-16']
      S3 [label = '@@1-17']
      S4 [label = '@@1-18']
      S5 [label = '@@1-19']
      S6 [label = '@@1-20']
      S7 [label = '@@1-21']
      S8 [label = '@@1-22']
      S9 [label = '@@1-23']
      S10 [label = '@@1-24']
      S11 [label = '@@1-25']
      S12 [label = '@@1-26']
      S13 [label = '@@1-27']
      }
      
      [1]:main$Label

      ")

graph

# Save 

html_print(add_mathjax(graph)) %>%
  webshot(file = "output/figures/cohorta2_attrition.png", delay = 1,
          selector = '.html-widget-static-bound',
          vwidth = 2000,
          vheight = 200,
          zoom = 4)
